package httpapi

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type restaurantCreateOrderRequest struct {
	BranchID     string `json:"branch_id"`
	TableID      string `json:"table_id"`
	CustomerName string `json:"customer_name"`
}

type restaurantAddItemRequest struct {
	ProductID string  `json:"product_id"`
	Quantity  float64 `json:"quantity"`
	Notes     string  `json:"notes"`
}

type restaurantUpdateOrderRequest struct {
	CustomerName *string  `json:"customer_name"`
	Discount     *float64 `json:"discount_amount"`
	Tax          *float64 `json:"tax_amount"`
	Service      *float64 `json:"service_charge"`
}

type restaurantStatusRequest struct {
	Status string `json:"status"`
}

func restaurantJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(payload); err != nil {
		return
	}
}

func restaurantError(w http.ResponseWriter, status int, code string, message string) {
	restaurantJSON(w, status, map[string]any{
		"error": map[string]any{
			"code":    code,
			"message": message,
		},
	})
}

func restaurantBusinessID(r *http.Request) string {
	return strings.TrimSpace(chi.URLParam(r, "businessID"))
}

func restaurantOrderID(r *http.Request) string {
	return strings.TrimSpace(chi.URLParam(r, "orderID"))
}

func restaurantValidStatus(status string) bool {
	switch status {
	case "open", "confirmed", "cooking", "ready", "served", "completed", "cancelled":
		return true
	default:
		return false
	}
}

func restaurantCanModifyOrder(status string) bool {
	switch status {
	case "open", "confirmed", "cooking", "ready", "served":
		return true
	default:
		return false
	}
}

func restaurantGenerateOrderNumber() string {
	now := time.Now()
	buf := make([]byte, 4)

	if _, err := rand.Read(buf); err != nil {
		return fmt.Sprintf(
			"AK-%s-%06d",
			now.Format("20060102"),
			now.UnixNano()%1000000,
		)
	}

	return fmt.Sprintf(
		"ND-%s-%s",
		now.Format("20060102-150405"),
		strings.ToUpper(hex.EncodeToString(buf)),
	)
}

func restaurantIsUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError

	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}

	return false
}

// GET /api/v1/businesses/{businessID}/restaurant/tables
func (h *Handler) restaurantListTables(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)

	rows, err := h.DB.Query(
		r.Context(),
		`
        SELECT
            d.id::text,
            d.branch_id::text,
            d.code,
            d.name,
            d.capacity,
            d.status,
            d.created_at,
            d.updated_at
        FROM dining_tables d
        WHERE d.business_id = $1
          AND d.tenant_id = $2
          AND d.status <> 'inactive'
        ORDER BY d.branch_id, d.code
        `,
		businessID,
		claims.TenantID,
	)
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TABLE_QUERY_FAILED", "failed to query dining tables")
		return
	}
	defer rows.Close()

	items := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id        string
			branchID  string
			code      string
			name      string
			capacity  int
			status    string
			createdAt any
			updatedAt any
		)

		if err := rows.Scan(
			&id,
			&branchID,
			&code,
			&name,
			&capacity,
			&status,
			&createdAt,
			&updatedAt,
		); err != nil {
			restaurantError(w, http.StatusInternalServerError, "TABLE_SCAN_FAILED", "failed to scan dining table")
			return
		}

		items = append(items, map[string]any{
			"id":         id,
			"branch_id":  branchID,
			"code":       code,
			"name":       name,
			"capacity":   capacity,
			"status":     status,
			"created_at": createdAt,
			"updated_at": updatedAt,
		})
	}

	if err := rows.Err(); err != nil {
		restaurantError(w, http.StatusInternalServerError, "TABLE_QUERY_FAILED", "failed while reading dining tables")
		return
	}

	restaurantJSON(w, http.StatusOK, map[string]any{
		"business_id": businessID,
		"items":       items,
		"total":       len(items),
	})
}

// GET /api/v1/businesses/{businessID}/restaurant/orders
func (h *Handler) restaurantListOrders(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)

	status := strings.TrimSpace(r.URL.Query().Get("status"))
	branchID := strings.TrimSpace(r.URL.Query().Get("branch_id"))

	rows, err := h.DB.Query(
		r.Context(),
		`
        SELECT
            o.id::text,
            o.branch_id::text,
            o.order_number,
            o.table_id::text,
            d.code,
            d.name,
            o.customer_name,
            o.status,
            o.payment_status,
            o.subtotal,
            o.discount_amount,
            o.tax_amount,
            o.service_charge,
            o.grand_total,
            o.opened_at,
            o.closed_at,
            o.created_at,
            o.updated_at
        FROM restaurant_orders o
        INNER JOIN dining_tables d
            ON d.id = o.table_id
           AND d.business_id = o.business_id
        WHERE o.business_id = $1
          AND o.tenant_id = $2
          AND ($3 = '' OR o.status = $3)
          AND ($4 = '' OR o.branch_id::text = $4)
        ORDER BY o.opened_at DESC
        LIMIT 200
        `,
		businessID,
		claims.TenantID,
		status,
		branchID,
	)
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "ORDER_QUERY_FAILED", "failed to query restaurant orders")
		return
	}
	defer rows.Close()

	items := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id            string
			branchIDValue string
			orderNumber   string
			tableID       string
			tableCode     string
			tableName     string
			customerName  *string
			orderStatus   string
			paymentStatus string
			subtotal      float64
			discount      float64
			tax           float64
			serviceCharge float64
			grandTotal    float64
			openedAt      any
			closedAt      any
			createdAt     any
			updatedAt     any
		)

		if err := rows.Scan(
			&id,
			&branchIDValue,
			&orderNumber,
			&tableID,
			&tableCode,
			&tableName,
			&customerName,
			&orderStatus,
			&paymentStatus,
			&subtotal,
			&discount,
			&tax,
			&serviceCharge,
			&grandTotal,
			&openedAt,
			&closedAt,
			&createdAt,
			&updatedAt,
		); err != nil {
			restaurantError(w, http.StatusInternalServerError, "ORDER_SCAN_FAILED", "failed to scan restaurant order")
			return
		}

		items = append(items, map[string]any{
			"id":              id,
			"branch_id":       branchIDValue,
			"order_number":    orderNumber,
			"table_id":        tableID,
			"table_code":      tableCode,
			"table_name":      tableName,
			"customer_name":   customerName,
			"status":          orderStatus,
			"payment_status":  paymentStatus,
			"subtotal":        subtotal,
			"discount_amount": discount,
			"tax_amount":      tax,
			"service_charge":  serviceCharge,
			"grand_total":     grandTotal,
			"opened_at":       openedAt,
			"closed_at":       closedAt,
			"created_at":      createdAt,
			"updated_at":      updatedAt,
		})
	}

	if err := rows.Err(); err != nil {
		restaurantError(w, http.StatusInternalServerError, "ORDER_QUERY_FAILED", "failed while reading restaurant orders")
		return
	}

	restaurantJSON(w, http.StatusOK, map[string]any{
		"business_id": businessID,
		"items":       items,
		"total":       len(items),
	})
}

// GET /api/v1/businesses/{businessID}/restaurant/orders/{orderID}
func (h *Handler) restaurantGetOrder(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)
	orderID := restaurantOrderID(r)

	var (
		id            string
		tenantID      string
		branchID      string
		orderNumber   string
		tableID       string
		tableCode     string
		tableName     string
		customerName  *string
		orderStatus   string
		paymentStatus string
		subtotal      float64
		discount      float64
		tax           float64
		serviceCharge float64
		grandTotal    float64
		openedAt      any
		closedAt      any
		createdAt     any
		updatedAt     any
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            o.id::text,
            o.tenant_id::text,
            o.branch_id::text,
            o.order_number,
            o.table_id::text,
            d.code,
            d.name,
            o.customer_name,
            o.status,
            o.payment_status,
            o.subtotal,
            o.discount_amount,
            o.tax_amount,
            o.service_charge,
            o.grand_total,
            o.opened_at,
            o.closed_at,
            o.created_at,
            o.updated_at
        FROM restaurant_orders o
        INNER JOIN dining_tables d
            ON d.id = o.table_id
           AND d.business_id = o.business_id
        WHERE o.id = $1
          AND o.business_id = $2
          AND o.tenant_id = $3
        `,
		orderID,
		businessID,
		claims.TenantID,
	).Scan(
		&id,
		&tenantID,
		&branchID,
		&orderNumber,
		&tableID,
		&tableCode,
		&tableName,
		&customerName,
		&orderStatus,
		&paymentStatus,
		&subtotal,
		&discount,
		&tax,
		&serviceCharge,
		&grandTotal,
		&openedAt,
		&closedAt,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			restaurantError(w, http.StatusNotFound, "ORDER_NOT_FOUND", "restaurant order not found")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "ORDER_QUERY_FAILED", "failed to query restaurant order")
		return
	}

	rows, err := h.DB.Query(
		r.Context(),
		`
        SELECT
            i.id::text,
            i.product_id::text,
            i.product_name,
            i.product_sku,
            i.quantity,
            i.unit,
            i.unit_price,
            i.discount_amount,
            i.subtotal,
            i.notes,
            i.created_at,
            i.updated_at
        FROM restaurant_order_items i
        WHERE i.order_id = $1
          AND i.business_id = $2
          AND i.tenant_id = $3
        ORDER BY i.created_at ASC
        `,
		orderID,
		businessID,
		claims.TenantID,
	)
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "ITEM_QUERY_FAILED", "failed to query order items")
		return
	}
	defer rows.Close()

	items := make([]map[string]any, 0)

	for rows.Next() {
		var (
			itemID       string
			productID    string
			productName  string
			productSKU   string
			quantity     float64
			unit         string
			unitPrice    float64
			itemDiscount float64
			itemSubtotal float64
			notes        string
			itemCreated  any
			itemUpdated  any
		)

		if err := rows.Scan(
			&itemID,
			&productID,
			&productName,
			&productSKU,
			&quantity,
			&unit,
			&unitPrice,
			&itemDiscount,
			&itemSubtotal,
			&notes,
			&itemCreated,
			&itemUpdated,
		); err != nil {
			restaurantError(w, http.StatusInternalServerError, "ITEM_SCAN_FAILED", "failed to scan order item")
			return
		}

		items = append(items, map[string]any{
			"id":              itemID,
			"product_id":      productID,
			"product_name":    productName,
			"product_sku":     productSKU,
			"quantity":        quantity,
			"unit":            unit,
			"unit_price":      unitPrice,
			"discount_amount": itemDiscount,
			"subtotal":        itemSubtotal,
			"notes":           notes,
			"created_at":      itemCreated,
			"updated_at":      itemUpdated,
		})
	}

	if err := rows.Err(); err != nil {
		restaurantError(w, http.StatusInternalServerError, "ITEM_QUERY_FAILED", "failed while reading order items")
		return
	}

	restaurantJSON(w, http.StatusOK, map[string]any{
		"id":              id,
		"tenant_id":       tenantID,
		"business_id":     businessID,
		"branch_id":       branchID,
		"order_number":    orderNumber,
		"table_id":        tableID,
		"table_code":      tableCode,
		"table_name":      tableName,
		"customer_name":   customerName,
		"status":          orderStatus,
		"payment_status":  paymentStatus,
		"subtotal":        subtotal,
		"discount_amount": discount,
		"tax_amount":      tax,
		"service_charge":  serviceCharge,
		"grand_total":     grandTotal,
		"opened_at":       openedAt,
		"closed_at":       closedAt,
		"created_at":      createdAt,
		"updated_at":      updatedAt,
		"items":           items,
	})
}

// POST /api/v1/businesses/{businessID}/restaurant/orders
func (h *Handler) restaurantCreateOrder(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)

	var req restaurantCreateOrderRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		restaurantError(w, http.StatusBadRequest, "INVALID_JSON", "invalid request body")
		return
	}

	req.BranchID = strings.TrimSpace(req.BranchID)
	req.TableID = strings.TrimSpace(req.TableID)
	req.CustomerName = strings.TrimSpace(req.CustomerName)

	if req.BranchID == "" || req.TableID == "" {
		restaurantError(w, http.StatusBadRequest, "INVALID_ORDER", "branch_id and table_id are required")
		return
	}

	tx, err := h.DB.Begin(r.Context())
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_FAILED", "failed to begin transaction")
		return
	}
	defer tx.Rollback(r.Context())

	var tableStatus string

	err = tx.QueryRow(
		r.Context(),
		`
        SELECT status
        FROM dining_tables
        WHERE id = $1
          AND business_id = $2
          AND tenant_id = $3
          AND branch_id = $4
        FOR UPDATE
        `,
		req.TableID,
		businessID,
		claims.TenantID,
		req.BranchID,
	).Scan(&tableStatus)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			restaurantError(w, http.StatusNotFound, "TABLE_NOT_FOUND", "dining table not found")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "TABLE_QUERY_FAILED", "failed to validate dining table")
		return
	}

	if tableStatus == "inactive" {
		restaurantError(w, http.StatusConflict, "TABLE_INACTIVE", "dining table is inactive")
		return
	}

	if tableStatus == "occupied" {
		restaurantError(w, http.StatusConflict, "TABLE_OCCUPIED", "dining table already has an active order")
		return
	}

	orderNumber := restaurantGenerateOrderNumber()

	var orderID string
	err = tx.QueryRow(
		r.Context(),
		`
        INSERT INTO restaurant_orders (
            tenant_id,
            business_id,
            branch_id,
            order_number,
            table_id,
            customer_name,
            status,
            payment_status,
            created_by,
            updated_by
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            NULLIF($6, ''),
            'open',
            'unpaid',
            NULL,
            NULL
        )
        RETURNING id::text
        `,
		claims.TenantID,
		businessID,
		req.BranchID,
		orderNumber,
		req.TableID,
		req.CustomerName,
	).Scan(&orderID)

	if err != nil {
		if restaurantIsUniqueViolation(err) {
			restaurantError(w, http.StatusConflict, "ORDER_NUMBER_CONFLICT", "order number collision, please retry")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "ORDER_CREATE_FAILED", "failed to create restaurant order")
		return
	}

	_, err = tx.Exec(
		r.Context(),
		`
        UPDATE dining_tables
        SET status = 'occupied',
            updated_at = now()
        WHERE id = $1
          AND business_id = $2
          AND tenant_id = $3
        `,
		req.TableID,
		businessID,
		claims.TenantID,
	)

	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TABLE_UPDATE_FAILED", "failed to occupy dining table")
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_COMMIT_FAILED", "failed to commit restaurant order")
		return
	}

	restaurantJSON(w, http.StatusCreated, map[string]any{
		"id":             orderID,
		"business_id":    businessID,
		"branch_id":      req.BranchID,
		"table_id":       req.TableID,
		"order_number":   orderNumber,
		"status":         "open",
		"payment_status": "unpaid",
		"subtotal":       0,
		"grand_total":    0,
	})
}

// POST /api/v1/businesses/{businessID}/restaurant/orders/{orderID}/items
func (h *Handler) restaurantAddOrderItem(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)
	orderID := restaurantOrderID(r)

	var req restaurantAddItemRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		restaurantError(w, http.StatusBadRequest, "INVALID_JSON", "invalid request body")
		return
	}

	req.ProductID = strings.TrimSpace(req.ProductID)
	req.Notes = strings.TrimSpace(req.Notes)

	if req.ProductID == "" {
		restaurantError(w, http.StatusBadRequest, "INVALID_ITEM", "product_id is required")
		return
	}

	if req.Quantity <= 0 {
		restaurantError(w, http.StatusBadRequest, "INVALID_QUANTITY", "quantity must be greater than zero")
		return
	}

	tx, err := h.DB.Begin(r.Context())
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_FAILED", "failed to begin transaction")
		return
	}
	defer tx.Rollback(r.Context())

	var (
		orderStatus string
		orderBranch string
	)

	err = tx.QueryRow(
		r.Context(),
		`
        SELECT status, branch_id::text
        FROM restaurant_orders
        WHERE id = $1
          AND business_id = $2
          AND tenant_id = $3
        FOR UPDATE
        `,
		orderID,
		businessID,
		claims.TenantID,
	).Scan(&orderStatus, &orderBranch)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			restaurantError(w, http.StatusNotFound, "ORDER_NOT_FOUND", "restaurant order not found")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "ORDER_QUERY_FAILED", "failed to validate restaurant order")
		return
	}

	if !restaurantCanModifyOrder(orderStatus) {
		restaurantError(w, http.StatusConflict, "ORDER_CLOSED", "restaurant order cannot be modified in its current status")
		return
	}

	var (
		productID   string
		productSKU  string
		productName string
		unit        string
		price       float64
		productType string
	)

	err = tx.QueryRow(
		r.Context(),
		`
        SELECT
            id,
            sku,
            name,
            unit,
            price::double precision,
            product_type
        FROM catalog_products
        WHERE id = $1
          AND business_id = $2
          AND tenant_id = $3
          AND status = 'active'
        `,
		req.ProductID,
		businessID,
		claims.TenantID,
	).Scan(
		&productID,
		&productSKU,
		&productName,
		&unit,
		&price,
		&productType,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			restaurantError(w, http.StatusNotFound, "PRODUCT_NOT_FOUND", "active product not found for this business")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "PRODUCT_QUERY_FAILED", "failed to query product")
		return
	}

	_ = productType

	var itemID string

	subtotal := price * req.Quantity

	err = tx.QueryRow(
		r.Context(),
		`
        INSERT INTO restaurant_order_items (
            tenant_id,
            business_id,
            branch_id,
            order_id,
            product_id,
            product_name,
            product_sku,
            quantity,
            unit,
            unit_price,
            discount_amount,
            subtotal,
            notes
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7,
            $8,
            $9,
            $10,
            0,
            $11,
            $12
        )
        RETURNING id::text
        `,
		claims.TenantID,
		businessID,
		orderBranch,
		orderID,
		productID,
		productName,
		productSKU,
		req.Quantity,
		unit,
		price,
		subtotal,
		req.Notes,
	).Scan(&itemID)

	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "ITEM_CREATE_FAILED", "failed to add item to restaurant order")
		return
	}

	_, err = tx.Exec(
		r.Context(),
		`
        UPDATE restaurant_orders o
        SET
            subtotal = totals.subtotal,
            grand_total = GREATEST(
                totals.subtotal
                - o.discount_amount
                + o.tax_amount
                + o.service_charge,
                0
            ),
            updated_at = now()
        FROM (
            SELECT
                order_id,
                COALESCE(SUM(subtotal - discount_amount), 0) AS subtotal
            FROM restaurant_order_items
            WHERE order_id = $1
              AND business_id = $2
              AND tenant_id = $3
            GROUP BY order_id
        ) totals
        WHERE o.id = totals.order_id
          AND o.id = $1
          AND o.business_id = $2
          AND o.tenant_id = $3
        `,
		orderID,
		businessID,
		claims.TenantID,
	)

	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TOTAL_UPDATE_FAILED", "failed to recalculate order total")
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_COMMIT_FAILED", "failed to commit order item")
		return
	}

	restaurantJSON(w, http.StatusCreated, map[string]any{
		"id":           itemID,
		"order_id":     orderID,
		"product_id":   productID,
		"product_name": productName,
		"product_sku":  productSKU,
		"quantity":     req.Quantity,
		"unit":         unit,
		"unit_price":   price,
		"subtotal":     subtotal,
		"notes":        req.Notes,
	})
}

// PATCH /api/v1/businesses/{businessID}/restaurant/orders/{orderID}/status
func (h *Handler) restaurantUpdateOrderStatus(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)
	orderID := restaurantOrderID(r)

	var req restaurantStatusRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		restaurantError(w, http.StatusBadRequest, "INVALID_JSON", "invalid request body")
		return
	}

	req.Status = strings.ToLower(strings.TrimSpace(req.Status))

	if !restaurantValidStatus(req.Status) {
		restaurantError(w, http.StatusBadRequest, "INVALID_STATUS", "invalid restaurant order status")
		return
	}

	tx, err := h.DB.Begin(r.Context())
	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_FAILED", "failed to begin transaction")
		return
	}
	defer tx.Rollback(r.Context())

	var (
		currentStatus string
		tableID       string
	)

	err = tx.QueryRow(
		r.Context(),
		`
        SELECT status, table_id::text
        FROM restaurant_orders
        WHERE id = $1
          AND business_id = $2
          AND tenant_id = $3
        FOR UPDATE
        `,
		orderID,
		businessID,
		claims.TenantID,
	).Scan(&currentStatus, &tableID)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			restaurantError(w, http.StatusNotFound, "ORDER_NOT_FOUND", "restaurant order not found")
			return
		}

		restaurantError(w, http.StatusInternalServerError, "ORDER_QUERY_FAILED", "failed to query restaurant order")
		return
	}

	if currentStatus == "completed" || currentStatus == "cancelled" {
		restaurantError(w, http.StatusConflict, "ORDER_FINALIZED", "finalized order cannot change status")
		return
	}

	_, err = tx.Exec(
		r.Context(),
		`
        UPDATE restaurant_orders
        SET
            status = $1,
            closed_at = CASE
                WHEN $1 IN ('completed', 'cancelled') THEN now()
                ELSE closed_at
            END,
            updated_at = now()
        WHERE id = $2
          AND business_id = $3
          AND tenant_id = $4
        `,
		req.Status,
		orderID,
		businessID,
		claims.TenantID,
	)

	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "STATUS_UPDATE_FAILED", "failed to update order status")
		return
	}

	if req.Status == "completed" || req.Status == "cancelled" {
		_, err = tx.Exec(
			r.Context(),
			`
            UPDATE dining_tables
            SET status = 'available',
                updated_at = now()
            WHERE id = $1
              AND business_id = $2
              AND tenant_id = $3
            `,
			tableID,
			businessID,
			claims.TenantID,
		)

		if err != nil {
			restaurantError(w, http.StatusInternalServerError, "TABLE_RELEASE_FAILED", "failed to release dining table")
			return
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		restaurantError(w, http.StatusInternalServerError, "TRANSACTION_COMMIT_FAILED", "failed to commit order status")
		return
	}

	restaurantJSON(w, http.StatusOK, map[string]any{
		"order_id": orderID,
		"status":   req.Status,
	})
}

// PATCH /api/v1/businesses/{businessID}/restaurant/orders/{orderID}
func (h *Handler) restaurantUpdateOrder(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		restaurantError(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing tenant context")
		return
	}

	businessID := restaurantBusinessID(r)
	orderID := restaurantOrderID(r)

	var req restaurantUpdateOrderRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		restaurantError(w, http.StatusBadRequest, "INVALID_JSON", "invalid request body")
		return
	}

	if req.Discount != nil && *req.Discount < 0 {
		restaurantError(w, http.StatusBadRequest, "INVALID_DISCOUNT", "discount_amount cannot be negative")
		return
	}

	if req.Tax != nil && *req.Tax < 0 {
		restaurantError(w, http.StatusBadRequest, "INVALID_TAX", "tax_amount cannot be negative")
		return
	}

	if req.Service != nil && *req.Service < 0 {
		restaurantError(w, http.StatusBadRequest, "INVALID_SERVICE_CHARGE", "service_charge cannot be negative")
		return
	}

	_, err := h.DB.Exec(
		r.Context(),
		`
        UPDATE restaurant_orders
        SET
            customer_name = COALESCE($1, customer_name),
            discount_amount = COALESCE($2, discount_amount),
            tax_amount = COALESCE($3, tax_amount),
            service_charge = COALESCE($4, service_charge),
            grand_total = GREATEST(
                subtotal
                - COALESCE($2, discount_amount)
                + COALESCE($3, tax_amount)
                + COALESCE($4, service_charge),
                0
            ),
            updated_at = now()
        WHERE id = $5
          AND business_id = $6
          AND tenant_id = $7
          AND status NOT IN ('completed', 'cancelled')
        `,
		req.CustomerName,
		req.Discount,
		req.Tax,
		req.Service,
		orderID,
		businessID,
		claims.TenantID,
	)

	if err != nil {
		restaurantError(w, http.StatusInternalServerError, "ORDER_UPDATE_FAILED", "failed to update restaurant order")
		return
	}

	restaurantJSON(w, http.StatusOK, map[string]any{
		"order_id": orderID,
		"updated":  true,
	})
}

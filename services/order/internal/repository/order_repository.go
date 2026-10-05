package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nusa-dhipa/business-os/services/order/internal/domain"
)

var (
	ErrNotFound       = errors.New("not found")
	ErrInvalidContext = errors.New("invalid tenant/business/branch context")
	ErrConflict       = errors.New("conflict")
	ErrInvalidState   = errors.New("invalid order state")
)

type Repository struct {
	DB *pgxpool.Pool
}

func New(db *pgxpool.Pool) *Repository {
	return &Repository{DB: db}
}

func (r *Repository) ListTables(
	ctx context.Context,
	tenantID, businessID, branchID string,
) ([]domain.DiningTable, error) {
	rows, err := r.DB.Query(ctx, `
        SELECT id, tenant_id, business_id, branch_id,
               code, name, capacity, status, created_at, updated_at
        FROM dining_tables
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
        ORDER BY code
    `, tenantID, businessID, branchID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]domain.DiningTable, 0)

	for rows.Next() {
		var t domain.DiningTable

		if err := rows.Scan(
			&t.ID,
			&t.TenantID,
			&t.BusinessID,
			&t.BranchID,
			&t.Code,
			&t.Name,
			&t.Capacity,
			&t.Status,
			&t.CreatedAt,
			&t.UpdatedAt,
		); err != nil {
			return nil, err
		}

		result = append(result, t)
	}

	return result, rows.Err()
}

func (r *Repository) CreateTable(
	ctx context.Context,
	tenantID, businessID, branchID, code, name string,
	capacity int,
) (*domain.DiningTable, error) {
	if capacity <= 0 {
		return nil, fmt.Errorf("capacity must be greater than zero")
	}

	id := uuid.NewString()

	var t domain.DiningTable

	err := r.DB.QueryRow(ctx, `
        INSERT INTO dining_tables (
            id, tenant_id, business_id, branch_id,
            code, name, capacity
        )
        SELECT $1, $2, $3, $4, $5, $6, $7
        WHERE EXISTS (
            SELECT 1
            FROM businesses b
            JOIN branches br
              ON br.business_id = b.id
             AND br.tenant_id = b.tenant_id
            WHERE b.id = $3
              AND b.tenant_id = $2
              AND br.id = $4
        )
        RETURNING
            id, tenant_id, business_id, branch_id,
            code, name, capacity, status, created_at, updated_at
    `,
		id,
		tenantID,
		businessID,
		branchID,
		code,
		name,
		capacity,
	).Scan(
		&t.ID,
		&t.TenantID,
		&t.BusinessID,
		&t.BranchID,
		&t.Code,
		&t.Name,
		&t.Capacity,
		&t.Status,
		&t.CreatedAt,
		&t.UpdatedAt,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrInvalidContext
	}

	if err != nil {
		return nil, ErrConflict
	}

	return &t, nil
}

func (r *Repository) UpdateTableStatus(
	ctx context.Context,
	tenantID, businessID, branchID, tableID, status string,
) error {
	result, err := r.DB.Exec(ctx, `
        UPDATE dining_tables
        SET status = $1,
            updated_at = NOW()
        WHERE id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
    `,
		status,
		tableID,
		tenantID,
		businessID,
		branchID,
	)

	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *Repository) CreateOrder(
	ctx context.Context,
	tenantID, businessID, branchID, tableID,
	orderNumber, customerName, createdBy string,
) (*domain.Order, error) {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var tableExists bool

	err = tx.QueryRow(ctx, `
        SELECT EXISTS (
            SELECT 1
            FROM dining_tables
            WHERE id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
              AND status <> 'inactive'
        )
    `,
		tableID,
		tenantID,
		businessID,
		branchID,
	).Scan(&tableExists)

	if err != nil {
		return nil, err
	}

	if !tableExists {
		return nil, ErrInvalidContext
	}

	var activeOrder bool

	err = tx.QueryRow(ctx, `
        SELECT EXISTS (
            SELECT 1
            FROM restaurant_orders
            WHERE table_id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
              AND status IN (
                  'open',
                  'confirmed',
                  'cooking',
                  'ready',
                  'served'
              )
        )
    `,
		tableID,
		tenantID,
		businessID,
		branchID,
	).Scan(&activeOrder)

	if err != nil {
		return nil, err
	}

	if activeOrder {
		return nil, ErrConflict
	}

	id := uuid.NewString()

	var createdByValue *string
	if strings.TrimSpace(createdBy) != "" {
		createdByValue = &createdBy
	}

	var order domain.Order

	err = tx.QueryRow(ctx, `
        INSERT INTO restaurant_orders (
            id,
            tenant_id,
            business_id,
            branch_id,
            order_number,
            table_id,
            customer_name,
            created_by
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8
        )
        RETURNING
            id,
            tenant_id,
            business_id,
            branch_id,
            order_number,
            table_id,
            COALESCE(customer_name, ''),
            status,
            payment_status,
            subtotal,
            discount_amount,
            tax_amount,
            service_charge,
            grand_total,
            opened_at,
            closed_at,
            created_by,
            updated_by,
            created_at,
            updated_at
    `,
		id,
		tenantID,
		businessID,
		branchID,
		orderNumber,
		tableID,
		customerName,
		createdByValue,
	).Scan(
		&order.ID,
		&order.TenantID,
		&order.BusinessID,
		&order.BranchID,
		&order.OrderNumber,
		&order.TableID,
		&order.CustomerName,
		&order.Status,
		&order.PaymentStatus,
		&order.Subtotal,
		&order.DiscountAmount,
		&order.TaxAmount,
		&order.ServiceCharge,
		&order.GrandTotal,
		&order.OpenedAt,
		&order.ClosedAt,
		&order.CreatedBy,
		&order.UpdatedBy,
		&order.CreatedAt,
		&order.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	_, err = tx.Exec(ctx, `
        UPDATE dining_tables
        SET status = 'occupied',
            updated_at = NOW()
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
    `,
		tableID,
		tenantID,
		businessID,
		branchID,
	)

	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &order, nil
}

func (r *Repository) ListOrders(
	ctx context.Context,
	tenantID, businessID, branchID, status string,
) ([]domain.Order, error) {
	query := `
        SELECT
            id, tenant_id, business_id, branch_id,
            order_number, table_id,
            COALESCE(customer_name, ''),
            status, payment_status,
            subtotal, discount_amount, tax_amount,
            service_charge, grand_total,
            opened_at, closed_at,
            created_by, updated_by,
            created_at, updated_at
        FROM restaurant_orders
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
    `

	args := []any{
		tenantID,
		businessID,
		branchID,
	}

	if strings.TrimSpace(status) != "" {
		query += ` AND status = $4`
		args = append(args, status)
	}

	query += ` ORDER BY opened_at DESC LIMIT 200`

	rows, err := r.DB.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]domain.Order, 0)

	for rows.Next() {
		var o domain.Order

		if err := rows.Scan(
			&o.ID,
			&o.TenantID,
			&o.BusinessID,
			&o.BranchID,
			&o.OrderNumber,
			&o.TableID,
			&o.CustomerName,
			&o.Status,
			&o.PaymentStatus,
			&o.Subtotal,
			&o.DiscountAmount,
			&o.TaxAmount,
			&o.ServiceCharge,
			&o.GrandTotal,
			&o.OpenedAt,
			&o.ClosedAt,
			&o.CreatedBy,
			&o.UpdatedBy,
			&o.CreatedAt,
			&o.UpdatedAt,
		); err != nil {
			return nil, err
		}

		result = append(result, o)
	}

	return result, rows.Err()
}

func (r *Repository) GetOrder(
	ctx context.Context,
	tenantID, businessID, branchID, orderID string,
) (*domain.Order, error) {
	var o domain.Order

	err := r.DB.QueryRow(ctx, `
        SELECT
            id, tenant_id, business_id, branch_id,
            order_number, table_id,
            COALESCE(customer_name, ''),
            status, payment_status,
            subtotal, discount_amount, tax_amount,
            service_charge, grand_total,
            opened_at, closed_at,
            created_by, updated_by,
            created_at, updated_at
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
    `,
		orderID,
		tenantID,
		businessID,
		branchID,
	).Scan(
		&o.ID,
		&o.TenantID,
		&o.BusinessID,
		&o.BranchID,
		&o.OrderNumber,
		&o.TableID,
		&o.CustomerName,
		&o.Status,
		&o.PaymentStatus,
		&o.Subtotal,
		&o.DiscountAmount,
		&o.TaxAmount,
		&o.ServiceCharge,
		&o.GrandTotal,
		&o.OpenedAt,
		&o.ClosedAt,
		&o.CreatedBy,
		&o.UpdatedBy,
		&o.CreatedAt,
		&o.UpdatedAt,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	rows, err := r.DB.Query(ctx, `
        SELECT
            id,
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
            notes,
            created_at,
            updated_at
        FROM restaurant_order_items
        WHERE order_id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        ORDER BY created_at ASC
    `,
		orderID,
		tenantID,
		businessID,
		branchID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	o.Items = make([]domain.OrderItem, 0)

	for rows.Next() {
		var item domain.OrderItem

		if err := rows.Scan(
			&item.ID,
			&item.TenantID,
			&item.BusinessID,
			&item.BranchID,
			&item.OrderID,
			&item.ProductID,
			&item.ProductName,
			&item.ProductSKU,
			&item.Quantity,
			&item.Unit,
			&item.UnitPrice,
			&item.DiscountAmount,
			&item.Subtotal,
			&item.Notes,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}

		o.Items = append(o.Items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return &o, nil
}

func (r *Repository) AddItem(
	ctx context.Context,
	tenantID, businessID, branchID, orderID,
	productID string,
	quantity, discount float64,
	notes string,
) (*domain.OrderItem, error) {
	if quantity <= 0 {
		return nil, fmt.Errorf("quantity must be greater than zero")
	}

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var orderStatus string

	err = tx.QueryRow(ctx, `
        SELECT status
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        FOR UPDATE
    `,
		orderID,
		tenantID,
		businessID,
		branchID,
	).Scan(&orderStatus)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	if orderStatus == "completed" || orderStatus == "cancelled" {
		return nil, ErrInvalidState
	}

	var (
		productName   string
		productSKU    string
		unit          string
		unitPrice     float64
		productStatus string
	)

	err = tx.QueryRow(ctx, `
        SELECT
            name,
            sku,
            unit,
            price,
            status
        FROM catalog_products
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
    `,
		productID,
		tenantID,
		businessID,
	).Scan(
		&productName,
		&productSKU,
		&unit,
		&unitPrice,
		&productStatus,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	if productStatus != "active" {
		return nil, ErrInvalidState
	}

	subtotal := quantity*unitPrice - discount
	if subtotal < 0 {
		return nil, fmt.Errorf("discount cannot exceed item amount")
	}

	itemID := uuid.NewString()

	var item domain.OrderItem

	err = tx.QueryRow(ctx, `
        INSERT INTO restaurant_order_items (
            id,
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
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11, $12,
            $13, $14
        )
        RETURNING
            id,
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
            notes,
            created_at,
            updated_at
    `,
		itemID,
		tenantID,
		businessID,
		branchID,
		orderID,
		productID,
		productName,
		productSKU,
		quantity,
		unit,
		unitPrice,
		discount,
		subtotal,
		notes,
	).Scan(
		&item.ID,
		&item.TenantID,
		&item.BusinessID,
		&item.BranchID,
		&item.OrderID,
		&item.ProductID,
		&item.ProductName,
		&item.ProductSKU,
		&item.Quantity,
		&item.Unit,
		&item.UnitPrice,
		&item.DiscountAmount,
		&item.Subtotal,
		&item.Notes,
		&item.CreatedAt,
		&item.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	if orderStatus == "served" ||
		orderStatus == "ready" ||
		orderStatus == "cooking" {
		_, err = tx.Exec(ctx, `
            UPDATE restaurant_orders
            SET status = 'confirmed',
                updated_at = NOW()
            WHERE id = $1
        `, orderID)

		if err != nil {
			return nil, err
		}
	}

	if err := recalculateOrderTx(
		ctx,
		tx,
		tenantID,
		businessID,
		branchID,
		orderID,
	); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &item, nil
}

func (r *Repository) UpdateItem(
	ctx context.Context,
	tenantID, businessID, branchID, orderID, itemID string,
	quantity, discount float64,
	notes string,
) (*domain.OrderItem, error) {
	if quantity <= 0 {
		return nil, fmt.Errorf("quantity must be greater than zero")
	}

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var unitPrice float64

	err = tx.QueryRow(ctx, `
        SELECT unit_price
        FROM restaurant_order_items
        WHERE id = $1
          AND order_id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
        FOR UPDATE
    `,
		itemID,
		orderID,
		tenantID,
		businessID,
		branchID,
	).Scan(&unitPrice)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	subtotal := quantity*unitPrice - discount
	if subtotal < 0 {
		return nil, fmt.Errorf("discount cannot exceed item amount")
	}

	var item domain.OrderItem

	err = tx.QueryRow(ctx, `
        UPDATE restaurant_order_items
        SET quantity = $1,
            discount_amount = $2,
            subtotal = $3,
            notes = $4,
            updated_at = NOW()
        WHERE id = $5
          AND order_id = $6
          AND tenant_id = $7
          AND business_id = $8
          AND branch_id = $9
        RETURNING
            id,
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
            notes,
            created_at,
            updated_at
    `,
		quantity,
		discount,
		subtotal,
		notes,
		itemID,
		orderID,
		tenantID,
		businessID,
		branchID,
	).Scan(
		&item.ID,
		&item.TenantID,
		&item.BusinessID,
		&item.BranchID,
		&item.OrderID,
		&item.ProductID,
		&item.ProductName,
		&item.ProductSKU,
		&item.Quantity,
		&item.Unit,
		&item.UnitPrice,
		&item.DiscountAmount,
		&item.Subtotal,
		&item.Notes,
		&item.CreatedAt,
		&item.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	if err := recalculateOrderTx(
		ctx,
		tx,
		tenantID,
		businessID,
		branchID,
		orderID,
	); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &item, nil
}

func (r *Repository) DeleteItem(
	ctx context.Context,
	tenantID, businessID, branchID, orderID, itemID string,
) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	result, err := tx.Exec(ctx, `
        DELETE FROM restaurant_order_items
        WHERE id = $1
          AND order_id = $2
          AND tenant_id = $3
          AND business_id = $4
          AND branch_id = $5
    `,
		itemID,
		orderID,
		tenantID,
		businessID,
		branchID,
	)

	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return ErrNotFound
	}

	if err := recalculateOrderTx(
		ctx,
		tx,
		tenantID,
		businessID,
		branchID,
		orderID,
	); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *Repository) Transition(
	ctx context.Context,
	tenantID, businessID, branchID, orderID, target string,
	updatedBy string,
) error {
	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var (
		current string
		payment string
		tableID string
	)

	err = tx.QueryRow(ctx, `
        SELECT status, payment_status, table_id
        FROM restaurant_orders
        WHERE id = $1
          AND tenant_id = $2
          AND business_id = $3
          AND branch_id = $4
        FOR UPDATE
    `,
		orderID,
		tenantID,
		businessID,
		branchID,
	).Scan(
		&current,
		&payment,
		&tableID,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return ErrNotFound
	}

	if err != nil {
		return err
	}

	if !validTransition(current, target) {
		return ErrInvalidState
	}

	if target == "completed" && payment != "paid" {
		return fmt.Errorf("order cannot be completed before payment is paid")
	}

	var closedAt *time.Time
	if target == "completed" || target == "cancelled" {
		now := time.Now()
		closedAt = &now
	}

	_, err = tx.Exec(ctx, `
        UPDATE restaurant_orders
        SET status = $1,
            closed_at = COALESCE($2, closed_at),
            updated_by = NULLIF($3, ''),
            updated_at = NOW()
        WHERE id = $4
    `,
		target,
		closedAt,
		updatedBy,
		orderID,
	)

	if err != nil {
		return err
	}

	if target == "completed" || target == "cancelled" {
		_, err = tx.Exec(ctx, `
            UPDATE dining_tables
            SET status = 'available',
                updated_at = NOW()
            WHERE id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
        `,
			tableID,
			tenantID,
			businessID,
			branchID,
		)

		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func validTransition(current, target string) bool {
	switch current {
	case "open":
		return target == "confirmed" || target == "cancelled"
	case "confirmed":
		return target == "cooking" || target == "cancelled"
	case "cooking":
		return target == "ready" || target == "cancelled"
	case "ready":
		return target == "served" || target == "cancelled"
	case "served":
		return target == "completed" || target == "cancelled"
	case "cancelled":
		return target == "reopen"
	default:
		return false
	}
}

func recalculateOrderTx(
	ctx context.Context,
	tx pgx.Tx,
	tenantID, businessID, branchID, orderID string,
) error {
	_, err := tx.Exec(ctx, `
        UPDATE restaurant_orders o
        SET subtotal = x.subtotal,
            grand_total =
                x.subtotal
                - o.discount_amount
                + o.tax_amount
                + o.service_charge,
            updated_at = NOW()
        FROM (
            SELECT
                COALESCE(SUM(subtotal), 0) AS subtotal
            FROM restaurant_order_items
            WHERE order_id = $1
              AND tenant_id = $2
              AND business_id = $3
              AND branch_id = $4
        ) x
        WHERE o.id = $1
          AND o.tenant_id = $2
          AND o.business_id = $3
          AND o.branch_id = $4
    `,
		orderID,
		tenantID,
		businessID,
		branchID,
	)

	return err
}

package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type contextKey string

const (
	userIDKey   contextKey = "user_id"
	tenantIDKey contextKey = "tenant_id"
	roleKey     contextKey = "role"
)

type Handler struct {
	DB        *pgxpool.Pool
	JWTSecret string
}

type categoryRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

type productRequest struct {
	CategoryID     *string `json:"category_id"`
	SKU            string  `json:"sku"`
	Name           string  `json:"name"`
	Description    string  `json:"description"`
	ProductType    string  `json:"product_type"`
	Unit           string  `json:"unit"`
	Price          float64 `json:"price"`
	CostPrice      float64 `json:"cost_price"`
	TrackInventory bool    `json:"track_inventory"`
}

func NewRouter(db *pgxpool.Pool, jwtSecret string) http.Handler {
	h := &Handler{
		DB:        db,
		JWTSecret: jwtSecret,
	}

	r := chi.NewRouter()

	r.Get("/health", h.health)

	r.Route("/api/v1/catalog", func(r chi.Router) {
		r.Use(h.jwtMiddleware)

		r.Route("/categories", func(r chi.Router) {
			r.Get("/", h.listCategories)
			r.Post("/", h.createCategory)
		})

		r.Route("/products", func(r chi.Router) {
			r.Get("/", h.listProducts)
			r.Post("/", h.createProduct)
			r.Get("/{productID}", h.getProduct)
			r.Put("/{productID}", h.updateProduct)
			r.Delete("/{productID}", h.deleteProduct)
		})
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	if err := h.DB.Ping(ctx); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{
			"success": false,
			"error":   "database unavailable",
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"service": "catalog",
		"status":  "ok",
	})
}

func (h *Handler) jwtMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")

		if !strings.HasPrefix(header, "Bearer ") {
			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "missing bearer token",
			})
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))
		if token == "" {
			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "missing bearer token",
			})
			return
		}

		claims, err := parseToken(token, h.JWTSecret)
		if err != nil || claims == nil ||
			claims.UserID == "" ||
			claims.TenantID == "" ||
			claims.Role == "" {

			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "invalid token",
			})
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, claims.UserID)
		ctx = context.WithValue(ctx, tenantIDKey, claims.TenantID)
		ctx = context.WithValue(ctx, roleKey, claims.Role)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func tenantIDFromContext(r *http.Request) (string, bool) {
	value, ok := r.Context().Value(tenantIDKey).(string)
	return value, ok && value != ""
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func (h *Handler) listCategories(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	if businessID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id is required"})
		return
	}

	rows, err := h.DB.Query(
		r.Context(),
		`SELECT id, name, description, status, created_at, updated_at
         FROM catalog_categories
         WHERE tenant_id = $1
           AND business_id = $2
         ORDER BY name ASC`,
		tenantID,
		businessID,
	)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to query categories"})
		return
	}
	defer rows.Close()

	categories := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id, name, description, status string
			createdAt, updatedAt          time.Time
		)

		if err := rows.Scan(
			&id,
			&name,
			&description,
			&status,
			&createdAt,
			&updatedAt,
		); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to scan category"})
			return
		}

		categories = append(categories, map[string]any{
			"id":          id,
			"business_id": businessID,
			"name":        name,
			"description": description,
			"status":      status,
			"created_at":  createdAt,
			"updated_at":  updatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    categories,
	})
}

func (h *Handler) createCategory(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	if businessID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id is required"})
		return
	}

	var req categoryRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "invalid JSON"})
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Description = strings.TrimSpace(req.Description)

	if req.Name == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "name is required"})
		return
	}

	id := uuid.NewString()

	err := h.DB.QueryRow(
		r.Context(),
		`INSERT INTO catalog_categories
            (id, tenant_id, business_id, name, description)
         SELECT $1, $2, $3, $4, $5
         WHERE EXISTS (
             SELECT 1
             FROM businesses
             WHERE id = $3
               AND tenant_id = $2
         )
         RETURNING id`,
		id,
		tenantID,
		businessID,
		req.Name,
		req.Description,
	).Scan(&id)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeJSON(w, http.StatusNotFound, map[string]any{"success": false, "error": "business not found"})
			return
		}

		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error":   "category could not be created",
		})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":          id,
			"business_id": businessID,
			"name":        req.Name,
			"description": req.Description,
			"status":      "active",
		},
	})
}

func (h *Handler) listProducts(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	if businessID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id is required"})
		return
	}

	rows, err := h.DB.Query(
		r.Context(),
		`SELECT
            p.id,
            p.category_id,
            COALESCE(c.name, ''),
            p.sku,
            p.name,
            p.description,
            p.product_type,
            p.unit,
            p.price,
            p.cost_price,
            p.track_inventory,
            p.status,
            p.created_at,
            p.updated_at
         FROM catalog_products p
         LEFT JOIN catalog_categories c
           ON c.id = p.category_id
          AND c.tenant_id = p.tenant_id
          AND c.business_id = p.business_id
         WHERE p.tenant_id = $1
           AND p.business_id = $2
         ORDER BY p.name ASC`,
		tenantID,
		businessID,
	)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to query products"})
		return
	}
	defer rows.Close()

	products := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id, sku, name, description, productType, unit, status string
			categoryID                                            *string
			categoryName                                          string
			price, costPrice                                      float64
			trackInventory                                        bool
			createdAt, updatedAt                                  time.Time
		)

		if err := rows.Scan(
			&id,
			&categoryID,
			&categoryName,
			&sku,
			&name,
			&description,
			&productType,
			&unit,
			&price,
			&costPrice,
			&trackInventory,
			&status,
			&createdAt,
			&updatedAt,
		); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to scan product"})
			return
		}

		products = append(products, map[string]any{
			"id":              id,
			"business_id":     businessID,
			"category_id":     categoryID,
			"category_name":   categoryName,
			"sku":             sku,
			"name":            name,
			"description":     description,
			"product_type":    productType,
			"unit":            unit,
			"price":           price,
			"cost_price":      costPrice,
			"track_inventory": trackInventory,
			"status":          status,
			"created_at":      createdAt,
			"updated_at":      updatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    products,
	})
}

func (h *Handler) createProduct(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	if businessID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id is required"})
		return
	}

	var req productRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "invalid JSON"})
		return
	}

	req.SKU = strings.TrimSpace(req.SKU)
	req.Name = strings.TrimSpace(req.Name)
	req.Description = strings.TrimSpace(req.Description)
	req.ProductType = strings.TrimSpace(req.ProductType)
	req.Unit = strings.TrimSpace(req.Unit)

	if req.SKU == "" || req.Name == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "sku and name are required"})
		return
	}

	if req.ProductType == "" {
		req.ProductType = "product"
	}

	if req.Unit == "" {
		req.Unit = "pcs"
	}

	id := uuid.NewString()

	err := h.DB.QueryRow(
		r.Context(),
		`INSERT INTO catalog_products
            (
                id,
                tenant_id,
                business_id,
                category_id,
                sku,
                name,
                description,
                product_type,
                unit,
                price,
                cost_price,
                track_inventory
            )
         SELECT
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
         WHERE EXISTS (
             SELECT 1
             FROM businesses
             WHERE id = $3
               AND tenant_id = $2
         )
         AND (
             $4::uuid IS NULL
             OR EXISTS (
                 SELECT 1
                 FROM catalog_categories
                 WHERE id = $4
                   AND tenant_id = $2
                   AND business_id = $3
                   AND status = 'active'
             )
         )
         RETURNING id`,
		id,
		tenantID,
		businessID,
		req.CategoryID,
		req.SKU,
		req.Name,
		req.Description,
		req.ProductType,
		req.Unit,
		req.Price,
		req.CostPrice,
		req.TrackInventory,
	).Scan(&id)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeJSON(w, http.StatusNotFound, map[string]any{
				"success": false,
				"error":   "business or category not found",
			})
			return
		}

		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error":   "product could not be created; SKU may already exist",
		})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":              id,
			"business_id":     businessID,
			"category_id":     req.CategoryID,
			"sku":             req.SKU,
			"name":            req.Name,
			"description":     req.Description,
			"product_type":    req.ProductType,
			"unit":            req.Unit,
			"price":           req.Price,
			"cost_price":      req.CostPrice,
			"track_inventory": req.TrackInventory,
			"status":          "active",
		},
	})
}

func (h *Handler) getProduct(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	productID := strings.TrimSpace(chi.URLParam(r, "productID"))

	if businessID == "" || productID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id and productID are required"})
		return
	}

	var (
		id, sku, name, description, productType, unit, status string
		categoryID                                            *string
		price, costPrice                                      float64
		trackInventory                                        bool
		createdAt, updatedAt                                  time.Time
	)

	err := h.DB.QueryRow(
		r.Context(),
		`SELECT
            id,
            category_id,
            sku,
            name,
            description,
            product_type,
            unit,
            price,
            cost_price,
            track_inventory,
            status,
            created_at,
            updated_at
         FROM catalog_products
         WHERE id = $1
           AND tenant_id = $2
           AND business_id = $3`,
		productID,
		tenantID,
		businessID,
	).Scan(
		&id,
		&categoryID,
		&sku,
		&name,
		&description,
		&productType,
		&unit,
		&price,
		&costPrice,
		&trackInventory,
		&status,
		&createdAt,
		&updatedAt,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"success": false, "error": "product not found"})
		return
	}

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to query product"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":              id,
			"business_id":     businessID,
			"category_id":     categoryID,
			"sku":             sku,
			"name":            name,
			"description":     description,
			"product_type":    productType,
			"unit":            unit,
			"price":           price,
			"cost_price":      costPrice,
			"track_inventory": trackInventory,
			"status":          status,
			"created_at":      createdAt,
			"updated_at":      updatedAt,
		},
	})
}

func (h *Handler) updateProduct(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	productID := strings.TrimSpace(chi.URLParam(r, "productID"))

	if businessID == "" || productID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id and productID are required"})
		return
	}

	var req productRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "invalid JSON"})
		return
	}

	req.SKU = strings.TrimSpace(req.SKU)
	req.Name = strings.TrimSpace(req.Name)
	req.Description = strings.TrimSpace(req.Description)
	req.ProductType = strings.TrimSpace(req.ProductType)
	req.Unit = strings.TrimSpace(req.Unit)

	if req.SKU == "" || req.Name == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "sku and name are required"})
		return
	}

	if req.ProductType == "" {
		req.ProductType = "product"
	}

	if req.Unit == "" {
		req.Unit = "pcs"
	}

	result, err := h.DB.Exec(
		r.Context(),
		`UPDATE catalog_products
         SET
            category_id = $1,
            sku = $2,
            name = $3,
            description = $4,
            product_type = $5,
            unit = $6,
            price = $7,
            cost_price = $8,
            track_inventory = $9,
            updated_at = NOW()
         WHERE id = $10
           AND tenant_id = $11
           AND business_id = $12`,
		req.CategoryID,
		req.SKU,
		req.Name,
		req.Description,
		req.ProductType,
		req.Unit,
		req.Price,
		req.CostPrice,
		req.TrackInventory,
		productID,
		tenantID,
		businessID,
	)

	if err != nil {
		writeJSON(w, http.StatusConflict, map[string]any{"success": false, "error": "product could not be updated"})
		return
	}

	if result.RowsAffected() == 0 {
		writeJSON(w, http.StatusNotFound, map[string]any{"success": false, "error": "product not found"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "product updated",
	})
}

func (h *Handler) deleteProduct(w http.ResponseWriter, r *http.Request) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"success": false, "error": "tenant context missing"})
		return
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	productID := strings.TrimSpace(chi.URLParam(r, "productID"))

	if businessID == "" || productID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"success": false, "error": "business_id and productID are required"})
		return
	}

	result, err := h.DB.Exec(
		r.Context(),
		`UPDATE catalog_products
         SET status = 'archived',
             updated_at = NOW()
         WHERE id = $1
           AND tenant_id = $2
           AND business_id = $3`,
		productID,
		tenantID,
		businessID,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"success": false, "error": "failed to archive product"})
		return
	}

	if result.RowsAffected() == 0 {
		writeJSON(w, http.StatusNotFound, map[string]any{"success": false, "error": "product not found"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "product archived",
	})
}

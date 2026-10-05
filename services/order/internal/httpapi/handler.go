package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/golang-jwt/jwt/v5"

	"github.com/nusa-dhipa/business-os/services/order/internal/domain"
	"github.com/nusa-dhipa/business-os/services/order/internal/repository"
	"github.com/nusa-dhipa/business-os/services/order/internal/service"
)

type contextKey string

const (
	userIDKey   contextKey = "user_id"
	tenantIDKey contextKey = "tenant_id"
	roleKey     contextKey = "role"
)

type Handler struct {
	Service   *service.Service
	JWTSecret string
}

type claims struct {
	UserID   string `json:"user_id"`
	TenantID string `json:"tenant_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

type createTableRequest struct {
	Code     string `json:"code"`
	Name     string `json:"name"`
	Capacity int    `json:"capacity"`
}

type createOrderRequest struct {
	TableID      string `json:"table_id"`
	OrderNumber  string `json:"order_number"`
	CustomerName string `json:"customer_name"`
}

type addItemRequest struct {
	ProductID string  `json:"product_id"`
	Quantity  float64 `json:"quantity"`
	Discount  float64 `json:"discount_amount"`
	Notes     string  `json:"notes"`
}

type updateItemRequest struct {
	Quantity float64 `json:"quantity"`
	Discount float64 `json:"discount_amount"`
	Notes    string  `json:"notes"`
}

type tableStatusRequest struct {
	Status string `json:"status"`
}

func NewRouter(svc *service.Service, jwtSecret string) http.Handler {
	h := &Handler{
		Service:   svc,
		JWTSecret: jwtSecret,
	}

	r := chi.NewRouter()

	r.Get("/health", h.health)

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(h.jwtMiddleware)

		r.Route("/dining-tables", func(r chi.Router) {
			r.Get("/", h.listTables)
			r.Post("/", h.createTable)
			r.Patch("/{tableID}", h.updateTable)
		})

		r.Route("/orders", func(r chi.Router) {
			r.Get("/", h.listOrders)
			r.Post("/", h.createOrder)
			r.Get("/{orderID}", h.getOrder)

			r.Post("/{orderID}/items", h.addItem)
			r.Patch("/{orderID}/items/{itemID}", h.updateItem)
			r.Delete("/{orderID}/items/{itemID}", h.deleteItem)

			r.Post("/{orderID}/confirm", h.confirm)
			r.Post("/{orderID}/cooking", h.cooking)
			r.Post("/{orderID}/ready", h.ready)
			r.Post("/{orderID}/served", h.served)
			r.Post("/{orderID}/complete", h.complete)
			r.Post("/{orderID}/cancel", h.cancel)
			r.Post("/{orderID}/reopen", h.reopen)
		})
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"service": "order",
			"status":  "ok",
		},
	})
}

func (h *Handler) jwtMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := strings.TrimSpace(r.Header.Get("Authorization"))

		if !strings.HasPrefix(header, "Bearer ") {
			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "missing bearer token",
			})
			return
		}

		tokenString := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))

		c := &claims{}

		token, err := jwt.ParseWithClaims(
			tokenString,
			c,
			func(token *jwt.Token) (interface{}, error) {
				if token.Method != jwt.SigningMethodHS256 {
					return nil, errors.New("unexpected signing method")
				}

				return []byte(h.JWTSecret), nil
			},
		)

		if err != nil || !token.Valid ||
			c.UserID == "" ||
			c.TenantID == "" ||
			c.Role == "" {

			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "invalid token",
			})
			return
		}

		if c.ExpiresAt != nil && time.Now().After(c.ExpiresAt.Time) {
			writeJSON(w, http.StatusUnauthorized, map[string]any{
				"success": false,
				"error":   "token expired",
			})
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, c.UserID)
		ctx = context.WithValue(ctx, tenantIDKey, c.TenantID)
		ctx = context.WithValue(ctx, roleKey, c.Role)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func tenantIDFromContext(r *http.Request) (string, bool) {
	value, ok := r.Context().Value(tenantIDKey).(string)
	return value, ok && value != ""
}

func userIDFromContext(r *http.Request) string {
	value, _ := r.Context().Value(userIDKey).(string)
	return value
}

func contextIDs(r *http.Request) (string, string, string, bool) {
	tenantID, ok := tenantIDFromContext(r)
	if !ok {
		return "", "", "", false
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	branchID := strings.TrimSpace(r.URL.Query().Get("branch_id"))

	if businessID == "" || branchID == "" {
		return "", "", "", false
	}

	return tenantID, businessID, branchID, true
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func decodeJSON(w http.ResponseWriter, r *http.Request, target any) bool {
	if err := json.NewDecoder(r.Body).Decode(target); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "invalid JSON",
		})
		return false
	}

	return true
}

func mapError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error":   "not found",
		})

	case errors.Is(err, repository.ErrInvalidContext):
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error":   "invalid tenant/business/branch context",
		})

	case errors.Is(err, repository.ErrConflict):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error":   "conflict",
		})

	case errors.Is(err, repository.ErrInvalidState):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error":   "invalid order state",
		})

	default:
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error":   err.Error(),
		})
	}
}

func (h *Handler) listTables(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	tables, err := h.Service.ListTables(
		r.Context(),
		tenantID,
		businessID,
		branchID,
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    tables,
	})
}

func (h *Handler) createTable(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	var req createTableRequest

	if !decodeJSON(w, r, &req) {
		return
	}

	table, err := h.Service.CreateTable(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		req.Code,
		req.Name,
		req.Capacity,
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data":    table,
	})
}

func (h *Handler) updateTable(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	tableID := strings.TrimSpace(chi.URLParam(r, "tableID"))

	var req tableStatusRequest

	if !decodeJSON(w, r, &req) {
		return
	}

	err := h.Service.UpdateTableStatus(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		tableID,
		req.Status,
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "table updated",
	})
}

func (h *Handler) listOrders(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	orders, err := h.Service.ListOrders(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		r.URL.Query().Get("status"),
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    orders,
	})
}

func (h *Handler) createOrder(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	var req createOrderRequest

	if !decodeJSON(w, r, &req) {
		return
	}

	order, err := h.Service.CreateOrder(
		r.Context(),
		service.CreateOrderInput{
			TenantID:     tenantID,
			BusinessID:   businessID,
			BranchID:     branchID,
			TableID:      req.TableID,
			OrderNumber:  req.OrderNumber,
			CustomerName: req.CustomerName,
			CreatedBy:    userIDFromContext(r),
		},
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data":    order,
	})
}

func (h *Handler) getOrder(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	orderID := strings.TrimSpace(chi.URLParam(r, "orderID"))

	order, err := h.Service.GetOrder(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		orderID,
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    order,
	})
}

func (h *Handler) addItem(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	var req addItemRequest

	if !decodeJSON(w, r, &req) {
		return
	}

	item, err := h.Service.AddItem(
		r.Context(),
		service.AddItemInput{
			TenantID:   tenantID,
			BusinessID: businessID,
			BranchID:   branchID,
			OrderID:    chi.URLParam(r, "orderID"),
			ProductID:  req.ProductID,
			Quantity:   req.Quantity,
			Discount:   req.Discount,
			Notes:      req.Notes,
		},
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data":    item,
	})
}

func (h *Handler) updateItem(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	var req updateItemRequest

	if !decodeJSON(w, r, &req) {
		return
	}

	item, err := h.Service.UpdateItem(
		r.Context(),
		service.UpdateItemInput{
			TenantID:   tenantID,
			BusinessID: businessID,
			BranchID:   branchID,
			OrderID:    chi.URLParam(r, "orderID"),
			ItemID:     chi.URLParam(r, "itemID"),
			Quantity:   req.Quantity,
			Discount:   req.Discount,
			Notes:      req.Notes,
		},
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    item,
	})
}

func (h *Handler) deleteItem(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	err := h.Service.DeleteItem(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		chi.URLParam(r, "orderID"),
		chi.URLParam(r, "itemID"),
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "item deleted",
	})
}

func (h *Handler) transition(w http.ResponseWriter, r *http.Request, target string) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	err := h.Service.Transition(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		chi.URLParam(r, "orderID"),
		target,
		userIDFromContext(r),
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "order status updated",
		"status":  target,
	})
}

func (h *Handler) confirm(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "confirmed")
}

func (h *Handler) cooking(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "cooking")
}

func (h *Handler) ready(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "ready")
}

func (h *Handler) served(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "served")
}

func (h *Handler) complete(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "completed")
}

func (h *Handler) cancel(w http.ResponseWriter, r *http.Request) {
	h.transition(w, r, "cancelled")
}

func (h *Handler) reopen(w http.ResponseWriter, r *http.Request) {
	tenantID, businessID, branchID, ok := contextIDs(r)

	if !ok {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error":   "business_id and branch_id are required",
		})
		return
	}

	err := h.Service.Transition(
		r.Context(),
		tenantID,
		businessID,
		branchID,
		chi.URLParam(r, "orderID"),
		"open",
		userIDFromContext(r),
	)

	if err != nil {
		mapError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"message": "order reopened",
		"status":  "open",
	})
}

// Keep domain imported intentionally so this package documents the response model boundary.
var _ domain.Order

package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nusa-dhipa/business-os/packages/auth"
	"github.com/nusa-dhipa/business-os/packages/events"
	"github.com/nusa-dhipa/business-os/packages/httpx"
	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/repository"
	inventoryservice "github.com/nusa-dhipa/business-os/services/inventory_service/internal/service"
)

type contextKey string

const claimsKey contextKey = "claims"

type Handler struct {
	DB        *pgxpool.Pool
	JWTSecret string
	Events    *events.Publisher
	Service   *inventoryservice.Service
}

type createMovementRequest struct {
	BusinessID    string  `json:"business_id"`
	BranchID      string  `json:"branch_id"`
	ProductID     string  `json:"product_id"`
	MovementType  string  `json:"movement_type"`
	Quantity      float64 `json:"quantity"`
	ReferenceType *string `json:"reference_type"`
	ReferenceID   *string `json:"reference_id"`
	Note          string  `json:"note"`
}

func NewRouter(h *Handler) http.Handler {
	if h.Service == nil {
		h.Service = inventoryservice.New(repository.New(h.DB))
	}

	r := chi.NewRouter()

	r.Get("/health", h.health)

	r.Route("/api/v1/inventory", func(r chi.Router) {
		r.Use(h.requireAuth)

		r.Get("/balances", h.listBalances)
		r.Get("/balances/{productID}", h.getBalance)
		r.Get("/movements", h.listMovements)
		r.Post("/movements", h.createMovement)
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"service": "inventory",
			"status":  "healthy",
		},
	})
}

func (h *Handler) requireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := strings.TrimSpace(r.Header.Get("Authorization"))

		if header == "" {
			httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "missing bearer token")
			return
		}

		parts := strings.Fields(header)

		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "invalid authorization header")
			return
		}

		claims, err := auth.ParseToken(h.JWTSecret, parts[1])
		if err != nil {
			httpx.Fail(w, http.StatusUnauthorized, "INVALID_TOKEN", "invalid or expired token")
			return
		}

		if strings.TrimSpace(claims.UserID) == "" ||
			strings.TrimSpace(claims.TenantID) == "" ||
			strings.TrimSpace(claims.Role) == "" {
			httpx.Fail(w, http.StatusUnauthorized, "INVALID_CLAIMS", "required authentication claims are missing")
			return
		}

		ctx := context.WithValue(r.Context(), claimsKey, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func getClaims(r *http.Request) (*auth.Claims, bool) {
	claims, ok := r.Context().Value(claimsKey).(*auth.Claims)
	return claims, ok
}

func requestedContext(
	r *http.Request,
) (*auth.Claims, string, string, bool) {
	claims, ok := getClaims(r)
	if !ok || claims == nil {
		return nil, "", "", false
	}

	businessID := strings.TrimSpace(r.URL.Query().Get("business_id"))
	branchID := strings.TrimSpace(r.URL.Query().Get("branch_id"))

	return claims, businessID, branchID, true
}

func (h *Handler) listBalances(w http.ResponseWriter, r *http.Request) {
	claims, businessID, branchID, ok := requestedContext(r)

	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "tenant context is missing")
		return
	}

	if businessID == "" || branchID == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_CONTEXT",
			"business_id and branch_id are required",
		)
		return
	}

	items, err := h.Service.ListBalances(
		r.Context(),
		claims.TenantID,
		businessID,
		branchID,
	)
	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "query failed")
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"items": items,
			"total": len(items),
		},
	})
}

func (h *Handler) getBalance(w http.ResponseWriter, r *http.Request) {
	claims, businessID, branchID, ok := requestedContext(r)

	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "tenant context is missing")
		return
	}

	productID := strings.TrimSpace(chi.URLParam(r, "productID"))

	if businessID == "" || branchID == "" || productID == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_CONTEXT",
			"business_id, branch_id and product_id are required",
		)
		return
	}

	item, err := h.Service.GetBalance(
		r.Context(),
		claims.TenantID,
		businessID,
		branchID,
		productID,
	)
	if errors.Is(err, repository.ErrNotFound) {
		httpx.Fail(w, http.StatusNotFound, "NOT_FOUND", "inventory balance not found")
		return
	}

	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "query failed")
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    item,
	})
}

func (h *Handler) listMovements(w http.ResponseWriter, r *http.Request) {
	claims, businessID, branchID, ok := requestedContext(r)

	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "tenant context is missing")
		return
	}

	if businessID == "" || branchID == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_CONTEXT",
			"business_id and branch_id are required",
		)
		return
	}

	productID := strings.TrimSpace(r.URL.Query().Get("product_id"))

	items, err := h.Service.ListMovements(
		r.Context(),
		claims.TenantID,
		businessID,
		branchID,
		productID,
	)
	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "query failed")
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"items": items,
			"total": len(items),
		},
	})
}

func (h *Handler) createMovement(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)

	if !ok || claims == nil {
		httpx.Fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "tenant context is missing")
		return
	}

	var req createMovementRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "INVALID_JSON", "invalid JSON")
		return
	}

	req.BusinessID = strings.TrimSpace(req.BusinessID)
	req.BranchID = strings.TrimSpace(req.BranchID)
	req.ProductID = strings.TrimSpace(req.ProductID)
	req.MovementType = strings.ToLower(strings.TrimSpace(req.MovementType))
	req.Note = strings.TrimSpace(req.Note)

	if req.BusinessID == "" ||
		req.BranchID == "" ||
		req.ProductID == "" ||
		req.MovementType == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_REQUEST",
			"business_id, branch_id, product_id and movement_type are required",
		)
		return
	}

	if req.Quantity <= 0 {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_QUANTITY",
			"quantity must be greater than zero",
		)
		return
	}

	movement, balance, err := h.Service.CreateMovement(
		r.Context(),
		inventoryservice.CreateMovementInput{
			TenantID:      claims.TenantID,
			BusinessID:    req.BusinessID,
			BranchID:      req.BranchID,
			ProductID:     req.ProductID,
			MovementType:  req.MovementType,
			Quantity:      req.Quantity,
			ReferenceType: req.ReferenceType,
			ReferenceID:   req.ReferenceID,
			Note:          req.Note,
			CreatedBy:     claims.UserID,
		},
	)

	if errors.Is(err, repository.ErrInvalidContext) {
		httpx.Fail(
			w,
			http.StatusForbidden,
			"INVALID_CONTEXT",
			"business, branch or product does not belong to tenant",
		)
		return
	}

	if errors.Is(err, repository.ErrInsufficient) {
		httpx.Fail(
			w,
			http.StatusConflict,
			"INSUFFICIENT_INVENTORY",
			"inventory quantity is insufficient",
		)
		return
	}

	if errors.Is(err, repository.ErrNotFound) {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"NOT_FOUND",
			"inventory balance not found",
		)
		return
	}

	if errors.Is(err, repository.ErrInvalidMovement) {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_MOVEMENT",
			"unsupported movement type",
		)
		return
	}

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"inventory movement failed",
		)
		return
	}

	if h.Events != nil {
		if err := h.Events.PublishInventoryUpdated(
			r.Context(),
			movement.BusinessID,
			movement.TenantID,
			movement.BranchID,
			movement.ProductID,
			movement.ID,
			movement.MovementType,
			movement.Quantity,
			balance.AvailableQuantity,
		); err != nil {
			events.LogPublishError(err)
		}
	}

	httpx.JSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"movement": movement,
			"balance":  balance,
		},
	})
}

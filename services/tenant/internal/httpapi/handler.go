package httpapi

import (
	"context"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nusa-dhipa/business-os/packages/auth"
	"github.com/nusa-dhipa/business-os/packages/httpx"
)

type Handler struct {
	DB        *pgxpool.Pool
	JWTSecret string
}

type contextKey string

const claimsKey contextKey = "claims"

func NewRouter(h *Handler) http.Handler {
	r := chi.NewRouter()

	r.Get("/health", h.health)

	r.Route("/api/v1/tenants", func(r chi.Router) {
		r.Use(h.requireAuth)

		r.Get("/", h.list)
		r.Get("/{tenantID}", h.get)
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"service": "tenant",
			"status":  "healthy",
		},
	})
}

func (h *Handler) requireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")

		if !strings.HasPrefix(header, "Bearer ") {
			httpx.Fail(
				w,
				http.StatusUnauthorized,
				"UNAUTHORIZED",
				"missing bearer token",
			)
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))

		if token == "" {
			httpx.Fail(
				w,
				http.StatusUnauthorized,
				"UNAUTHORIZED",
				"empty bearer token",
			)
			return
		}

		claims, err := auth.ParseToken(h.JWTSecret, token)
		if err != nil {
			httpx.Fail(
				w,
				http.StatusUnauthorized,
				"INVALID_TOKEN",
				"invalid or expired token",
			)
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

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)

	if !ok || claims == nil {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"UNAUTHORIZED",
			"tenant context is missing",
		)
		return
	}

	tenantID, err := uuid.Parse(claims.TenantID)
	if err != nil {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"INVALID_TENANT",
			"invalid tenant id in token",
		)
		return
	}

	var (
		id        uuid.UUID
		name      string
		slug      string
		status    string
		createdAt interface{}
	)

	err = h.DB.QueryRow(
		r.Context(),
		`
        SELECT id, name, slug, status, created_at
        FROM tenants
        WHERE id = $1
        `,
		tenantID,
	).Scan(
		&id,
		&name,
		&slug,
		&status,
		&createdAt,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"TENANT_NOT_FOUND",
			"tenant not found",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"id":         id,
			"name":       name,
			"slug":       slug,
			"status":     status,
			"created_at": createdAt,
		},
	})
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)

	if !ok || claims == nil {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"UNAUTHORIZED",
			"tenant context is missing",
		)
		return
	}

	requestedID := chi.URLParam(r, "tenantID")

	if requestedID != claims.TenantID {
		httpx.Fail(
			w,
			http.StatusForbidden,
			"FORBIDDEN",
			"tenant access denied",
		)
		return
	}

	tenantID, err := uuid.Parse(requestedID)
	if err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_TENANT",
			"invalid tenant id",
		)
		return
	}

	var (
		id        uuid.UUID
		name      string
		slug      string
		status    string
		createdAt interface{}
	)

	err = h.DB.QueryRow(
		r.Context(),
		`
        SELECT id, name, slug, status, created_at
        FROM tenants
        WHERE id = $1
        `,
		tenantID,
	).Scan(
		&id,
		&name,
		&slug,
		&status,
		&createdAt,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"TENANT_NOT_FOUND",
			"tenant not found",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"id":         id,
			"name":       name,
			"slug":       slug,
			"status":     status,
			"created_at": createdAt,
		},
	})
}

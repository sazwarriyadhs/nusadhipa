package httpapi

import (
	"context"
	"net/http"
	"strings"

	"github.com/nusa-dhipa/business-os/packages/auth"
)

type authContextKey string

const (
	userIDContextKey   authContextKey = "user_id"
	tenantIDContextKey authContextKey = "tenant_id"
	roleContextKey     authContextKey = "role"
)

func JWTMiddleware(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := strings.TrimSpace(r.Header.Get("Authorization"))

			if header == "" {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "AUTHENTICATION_REQUIRED",
						"message": "authentication required",
					},
				})
				return
			}

			parts := strings.Fields(header)

			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "INVALID_AUTHORIZATION_HEADER",
						"message": "invalid authorization header",
					},
				})
				return
			}

			claims, err := auth.ParseToken(jwtSecret, parts[1])
			if err != nil {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "INVALID_TOKEN",
						"message": "invalid or expired token",
					},
				})
				return
			}

			if strings.TrimSpace(claims.UserID) == "" ||
				strings.TrimSpace(claims.TenantID) == "" ||
				strings.TrimSpace(claims.Role) == "" {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "INVALID_CLAIMS",
						"message": "required authentication claims are missing",
					},
				})
				return
			}

			ctx := context.WithValue(
				r.Context(),
				userIDContextKey,
				claims.UserID,
			)

			ctx = context.WithValue(
				ctx,
				tenantIDContextKey,
				claims.TenantID,
			)

			ctx = context.WithValue(
				ctx,
				roleContextKey,
				claims.Role,
			)

			r = r.WithContext(ctx)

			// Never trust identity headers supplied by the client.
			// They are overwritten with values derived from the JWT.
			r.Header.Set("X-Authenticated-User-ID", claims.UserID)
			r.Header.Set("X-Authenticated-Tenant-ID", claims.TenantID)
			r.Header.Set("X-Authenticated-Role", claims.Role)

			next.ServeHTTP(w, r)
		})
	}
}

func CORSMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		// Development origins used by Flutter Web / local browser.
		// Flutter Web uses a dynamically assigned localhost port.
		allowed := origin == "http://localhost" ||
			strings.HasPrefix(origin, "http://localhost:") ||
			origin == "http://127.0.0.1" ||
			strings.HasPrefix(origin, "http://127.0.0.1:")

		if allowed {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
			w.Header().Set(
				"Access-Control-Allow-Methods",
				"GET, POST, PUT, PATCH, DELETE, OPTIONS",
			)
			w.Header().Set(
				"Access-Control-Allow-Headers",
				"Accept, Authorization, Content-Type",
			)
			w.Header().Set(
				"Access-Control-Expose-Headers",
				"Content-Length, Content-Type",
			)
		}

		if r.Method == http.MethodOptions {
			if allowed {
				w.WriteHeader(http.StatusNoContent)
			} else {
				http.Error(
					w,
					"CORS origin not allowed",
					http.StatusForbidden,
				)
			}
			return
		}

		next.ServeHTTP(w, r)
	})
}

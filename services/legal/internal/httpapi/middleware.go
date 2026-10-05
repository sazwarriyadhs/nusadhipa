package httpapi

import (
	"context"
	"net/http"
	"strings"

	"github.com/nusa-dhipa/business-os/packages/auth"
)

type contextKey string

const (
	userIDContextKey   contextKey = "authenticated_user_id"
	tenantIDContextKey contextKey = "authenticated_tenant_id"
	roleContextKey     contextKey = "authenticated_role"
)

func JWTMiddleware(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := strings.TrimSpace(r.Header.Get("Authorization"))

			if authHeader == "" {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "AUTH_REQUIRED",
						"message": "authorization bearer token is required",
					},
				})
				return
			}

			parts := strings.Fields(authHeader)

			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				writeJSON(w, http.StatusUnauthorized, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "INVALID_AUTH_HEADER",
						"message": "authorization header must use Bearer token",
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
						"message": "invalid or expired access token",
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

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func userIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(userIDContextKey).(string)
	return value
}

func tenantIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(tenantIDContextKey).(string)
	return value
}

func roleFromContext(ctx context.Context) string {
	value, _ := ctx.Value(roleContextKey).(string)
	return value
}

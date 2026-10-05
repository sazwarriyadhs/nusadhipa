package httpapi

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"

	"github.com/nusa-dhipa/business-os/packages/auth"
	"github.com/nusa-dhipa/business-os/packages/httpx"
)

type Handler struct {
	DB        *pgxpool.Pool
	JWTSecret string
}

type registerRequest struct {
	Name         string `json:"name"`
	Email        string `json:"email"`
	Password     string `json:"password"`
	TenantName   string `json:"tenant_name"`
	BusinessName string `json:"business_name"`
	BusinessType string `json:"business_type"`
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func NewRouter(h *Handler) http.Handler {
	r := chi.NewRouter()

	r.Get("/health", h.health)

	r.Route("/api/v1/auth", func(r chi.Router) {
		r.Post("/register", h.register)
		r.Post("/login", h.login)
		r.Post("/refresh", h.refresh)
	})

	return r
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"service": "auth",
			"status":  "healthy",
		},
	})
}

func (h *Handler) register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "INVALID_JSON", "invalid JSON")
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.TenantName = strings.TrimSpace(req.TenantName)
	req.BusinessName = strings.TrimSpace(req.BusinessName)
	req.BusinessType = strings.TrimSpace(req.BusinessType)

	if req.Name == "" ||
		req.Email == "" ||
		req.Password == "" ||
		req.TenantName == "" ||
		req.BusinessName == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"VALIDATION_ERROR",
			"name, email, password, tenant_name and business_name are required",
		)
		return
	}

	if len(req.Password) < 8 {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"WEAK_PASSWORD",
			"password must contain at least 8 characters",
		)
		return
	}

	passwordHash, err := bcrypt.GenerateFromPassword(
		[]byte(req.Password),
		bcrypt.DefaultCost,
	)
	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"PASSWORD_HASH_FAILED",
			"password hashing failed",
		)
		return
	}

	ctx := r.Context()

	tx, err := h.DB.Begin(ctx)
	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"TRANSACTION_FAILED",
			"transaction failed",
		)
		return
	}
	defer tx.Rollback(ctx)

	tenantID := uuid.New()
	userID := uuid.New()
	businessID := uuid.New()
	settingsID := uuid.New()
	branchID := uuid.New()

	tenantSlug := slugify(req.TenantName) + "-" + shortUUID(tenantID)
	businessSlug := slugify(req.BusinessName) + "-" + shortUUID(businessID)

	var tenantStatus string

	err = tx.QueryRow(
		ctx,
		`
        INSERT INTO tenants (
            id,
            name,
            slug,
            status,
            created_at,
            updated_at
        )
        VALUES ($1, $2, $3, 'active', NOW(), NOW())
        RETURNING status
        `,
		tenantID,
		req.TenantName,
		tenantSlug,
	).Scan(&tenantStatus)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusConflict,
			"TENANT_CREATE_FAILED",
			"tenant could not be created",
		)
		return
	}

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO users (
            id,
            tenant_id,
            name,
            email,
            password_hash,
            role,
            status,
            created_at,
            updated_at
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            'owner',
            'active',
            NOW(),
            NOW()
        )
        `,
		userID,
		tenantID,
		req.Name,
		req.Email,
		string(passwordHash),
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusConflict,
			"USER_CREATE_FAILED",
			"email already exists for this tenant",
		)
		return
	}

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO tenant_memberships (
            id,
            tenant_id,
            user_id,
            role,
            status,
            created_at,
            updated_at
        )
        VALUES ($1, $2, $3, 'owner', 'active', NOW(), NOW())
        `,
		uuid.New(),
		tenantID,
		userID,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"MEMBERSHIP_CREATE_FAILED",
			"membership creation failed",
		)
		return
	}

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO businesses (
            id,
            tenant_id,
            name,
            slug,
            business_type,
            status,
            created_at,
            updated_at
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            'active',
            NOW(),
            NOW()
        )
        `,
		businessID,
		tenantID,
		req.BusinessName,
		businessSlug,
		req.BusinessType,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"BUSINESS_CREATE_FAILED",
			"business creation failed",
		)
		return
	}

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO business_settings (
            id,
            business_id,
            tenant_id,
            currency,
            timezone,
            tax_enabled,
            tax_rate,
            created_at,
            updated_at
        )
        VALUES (
            $1,
            $2,
            $3,
            'IDR',
            'Asia/Jakarta',
            FALSE,
            0,
            NOW(),
            NOW()
        )
        `,
		settingsID,
		businessID,
		tenantID,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"SETTINGS_CREATE_FAILED",
			"business settings creation failed",
		)
		return
	}

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO branches (
            id,
            business_id,
            tenant_id,
            name,
            code,
            is_main,
            status,
            created_at,
            updated_at
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            'MAIN',
            TRUE,
            'active',
            NOW(),
            NOW()
        )
        `,
		branchID,
		businessID,
		tenantID,
		req.BusinessName+" Main Branch",
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"BRANCH_CREATE_FAILED",
			"main branch creation failed",
		)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"TRANSACTION_COMMIT_FAILED",
			"transaction commit failed",
		)
		return
	}

	accessToken, err := auth.GenerateToken(
		h.JWTSecret,
		userID.String(),
		tenantID.String(),
		"owner",
		15*time.Minute,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"TOKEN_GENERATION_FAILED",
			"token generation failed",
		)
		return
	}

	refreshToken, err := h.createRefreshToken(
		ctx,
		userID,
		tenantID,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"REFRESH_TOKEN_FAILED",
			"refresh token creation failed",
		)
		return
	}

	httpx.JSON(w, http.StatusCreated, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"user": map[string]interface{}{
				"id":     userID,
				"name":   req.Name,
				"email":  req.Email,
				"role":   "owner",
				"status": "active",
			},
			"tenant": map[string]interface{}{
				"id":     tenantID,
				"name":   req.TenantName,
				"slug":   tenantSlug,
				"status": tenantStatus,
			},
			"business": map[string]interface{}{
				"id":            businessID,
				"name":          req.BusinessName,
				"slug":          businessSlug,
				"business_type": req.BusinessType,
			},
			"branch": map[string]interface{}{
				"id":      branchID,
				"name":    req.BusinessName + " Main Branch",
				"code":    "MAIN",
				"is_main": true,
			},
			"tokens": map[string]interface{}{
				"access_token":  accessToken,
				"refresh_token": refreshToken,
				"token_type":    "Bearer",
				"expires_in":    900,
			},
		},
	})
}

type loginBusinessContext struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	BusinessType string `json:"business_type"`
	Slug         string `json:"slug"`
	Status       string `json:"status"`
}

type loginBranchContext struct {
	ID         string `json:"id"`
	BusinessID string `json:"business_id"`
	Name       string `json:"name"`
	Code       string `json:"code"`
	Status     string `json:"status"`
}

func loadLoginBusinessContext(
	ctx context.Context,
	db *pgxpool.Pool,
	tenantID uuid.UUID,
) (*loginBusinessContext, *loginBranchContext, error) {

	var business loginBusinessContext

	err := db.QueryRow(
		ctx,
		`
        SELECT
            id,
            name,
            business_type,
            slug,
            status
        FROM businesses
        WHERE tenant_id = $1
        ORDER BY created_at ASC
        LIMIT 1
        `,
		tenantID,
	).Scan(
		&business.ID,
		&business.Name,
		&business.BusinessType,
		&business.Slug,
		&business.Status,
	)

	if err != nil {
		return nil, nil, err
	}

	var branch loginBranchContext

	err = db.QueryRow(
		ctx,
		`
        SELECT
            id,
            business_id,
            name,
            code,
            status
        FROM branches
        WHERE business_id = $1
        ORDER BY created_at ASC
        LIMIT 1
        `,
		business.ID,
	).Scan(
		&branch.ID,
		&branch.BusinessID,
		&branch.Name,
		&branch.Code,
		&branch.Status,
	)

	if err != nil {
		return &business, nil, err
	}

	return &business, &branch, nil
}
func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "INVALID_JSON", "invalid JSON")
		return
	}

	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if req.Email == "" || req.Password == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"VALIDATION_ERROR",
			"email and password are required",
		)
		return
	}

	var (
		userID       uuid.UUID
		tenantID     uuid.UUID
		name         string
		email        string
		passwordHash string
		role         string
		status       string
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            id,
            tenant_id,
            name,
            email,
            password_hash,
            role,
            status
        FROM users
        WHERE LOWER(email) = LOWER($1)
        LIMIT 1
        `,
		req.Email,
	).Scan(
		&userID,
		&tenantID,
		&name,
		&email,
		&passwordHash,
		&role,
		&status,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			httpx.Fail(
				w,
				http.StatusUnauthorized,
				"INVALID_CREDENTIALS",
				"invalid email or password",
			)
			return
		}

		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"LOGIN_FAILED",
			"login failed",
		)
		return
	}

	if status != "active" {
		httpx.Fail(
			w,
			http.StatusForbidden,
			"USER_INACTIVE",
			"user is inactive",
		)
		return
	}

	if err := bcrypt.CompareHashAndPassword(
		[]byte(passwordHash),
		[]byte(req.Password),
	); err != nil {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"INVALID_CREDENTIALS",
			"invalid email or password",
		)
		return
	}

	accessToken, err := auth.GenerateToken(
		h.JWTSecret,
		userID.String(),
		tenantID.String(),
		role,
		15*time.Minute,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"TOKEN_GENERATION_FAILED",
			"token generation failed",
		)
		return
	}

	refreshToken, err := h.createRefreshToken(
		r.Context(),
		userID,
		tenantID,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"REFRESH_TOKEN_FAILED",
			"refresh token creation failed",
		)
		return
	}
	business, branch, err := loadLoginBusinessContext(
		r.Context(),
		h.DB,
		tenantID,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"BUSINESS_CONTEXT_FAILED",
			"failed to load business context",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"tenant": map[string]interface{}{
				"id": tenantID,
			},
			"business": business,
			"branch":   branch,
			"user": map[string]interface{}{
				"id":     userID,
				"name":   name,
				"email":  email,
				"role":   role,
				"status": status,
			},
			"tokens": map[string]interface{}{
				"access_token":  accessToken,
				"refresh_token": refreshToken,
				"token_type":    "Bearer",
				"expires_in":    900,
			},
		},
	})

}

func (h *Handler) refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "INVALID_JSON", "invalid JSON")
		return
	}

	req.RefreshToken = strings.TrimSpace(req.RefreshToken)

	if req.RefreshToken == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"VALIDATION_ERROR",
			"refresh_token is required",
		)
		return
	}

	tokenHash := hashToken(req.RefreshToken)

	var (
		userID   uuid.UUID
		tenantID uuid.UUID
		role     string
		expires  time.Time
		revoked  *time.Time
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            rt.user_id,
            rt.tenant_id,
            tm.role,
            rt.expires_at,
            rt.revoked_at
        FROM refresh_tokens rt
        JOIN tenant_memberships tm
            ON tm.user_id = rt.user_id
            AND tm.tenant_id = rt.tenant_id
        WHERE rt.token_hash = $1
        LIMIT 1
        `,
		tokenHash,
	).Scan(
		&userID,
		&tenantID,
		&role,
		&expires,
		&revoked,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"INVALID_REFRESH_TOKEN",
			"invalid refresh token",
		)
		return
	}

	if revoked != nil || time.Now().After(expires) {
		httpx.Fail(
			w,
			http.StatusUnauthorized,
			"REFRESH_TOKEN_EXPIRED",
			"refresh token expired or revoked",
		)
		return
	}

	accessToken, err := auth.GenerateToken(
		h.JWTSecret,
		userID.String(),
		tenantID.String(),
		role,
		15*time.Minute,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"TOKEN_GENERATION_FAILED",
			"token generation failed",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"access_token": accessToken,
			"token_type":   "Bearer",
			"expires_in":   900,
		},
	})
}

func (h *Handler) createRefreshToken(
	ctx context.Context,
	userID uuid.UUID,
	tenantID uuid.UUID,
) (string, error) {
	raw := make([]byte, 48)

	if _, err := rand.Read(raw); err != nil {
		return "", err
	}

	token := hex.EncodeToString(raw)
	tokenHash := hashToken(token)

	_, err := h.DB.Exec(
		ctx,
		`
        INSERT INTO refresh_tokens (
            id,
            user_id,
            tenant_id,
            token_hash,
            expires_at,
            created_at
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            NOW() + INTERVAL '30 days',
            NOW()
        )
        `,
		uuid.New(),
		userID,
		tenantID,
		tokenHash,
	)

	if err != nil {
		return "", err
	}

	return token, nil
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func slugify(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))

	var b strings.Builder
	lastDash := false

	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z':
			b.WriteRune(r)
			lastDash = false
		case r >= '0' && r <= '9':
			b.WriteRune(r)
			lastDash = false
		default:
			if !lastDash && b.Len() > 0 {
				b.WriteRune('-')
				lastDash = true
			}
		}
	}

	result := strings.Trim(b.String(), "-")

	if result == "" {
		return "tenant"
	}

	return result
}

func shortUUID(id uuid.UUID) string {
	value := strings.ReplaceAll(id.String(), "-", "")

	if len(value) > 8 {
		return value[:8]
	}

	return value
}

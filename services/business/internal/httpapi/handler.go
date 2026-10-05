package httpapi

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nusa-dhipa/business-os/packages/auth"
	"github.com/nusa-dhipa/business-os/packages/events"
	"github.com/nusa-dhipa/business-os/packages/httpx"
)

type Handler struct {
	DB        *pgxpool.Pool
	JWTSecret string
	Events    *events.Publisher
}

type createBusinessRequest struct {
	Name         string `json:"name"`
	BusinessType string `json:"business_type"`
	Activity     string `json:"activity"`
	KbliCode     string `json:"kbli_code"`
	KbliName     string `json:"kbli_name"`
	Phone        string `json:"phone"`
	Email        string `json:"email"`
	Address      string `json:"address"`
}

type updateBusinessRequest struct {
	Name          string `json:"name"`
	BusinessType  string `json:"business_type"`
	Activity      string `json:"activity"`
	KbliCode      string `json:"kbli_code"`
	KbliName      string `json:"kbli_name"`
	Phone         string `json:"phone"`
	Email         string `json:"email"`
	Address       string `json:"address"`
	ShortName     string `json:"short_name"`
	Tagline       string `json:"tagline"`
	Description   string `json:"description"`
	Whatsapp      string `json:"whatsapp"`
	Website       string `json:"website"`
	LogoURL       string `json:"logo_url"`
	CoverImageURL string `json:"cover_image_url"`
	BrandColor    string `json:"brand_color"`
}

type createServiceQuoteRequest struct {
	CustomerName     string `json:"customer_name"`
	CustomerWhatsApp string `json:"customer_whatsapp"`
	CustomerEmail    string `json:"customer_email"`
	Brief            string `json:"brief"`
	Budget           string `json:"budget"`
	Deadline         string `json:"deadline"`
	Notes            string `json:"notes"`
}
type createBranchRequest struct {
	Name    string `json:"name"`
	Code    string `json:"code"`
	Phone   string `json:"phone"`
	Address string `json:"address"`
}

type contextKey string

const claimsKey contextKey = "business_claims"

func NewRouter(h *Handler) http.Handler {
	r := chi.NewRouter()

	r.Get("/health", h.health)

	// Public business media.
	// Files are stored persistently under /app/uploads.
	r.Handle("/uploads/*", http.StripPrefix("/uploads/", http.FileServer(http.Dir("/app/uploads"))))

	// Public read-only marketplace facade.
	// Intentionally does not use JWT middleware.
	r.Route("/api/v1/marketplace", func(r chi.Router) {
		r.Get("/businesses", h.marketplaceBusinesses)
		r.Get("/businesses/{businessID}", h.marketplaceBusiness)
		r.Post("/businesses/{businessID}/service-quotes", h.createServiceQuote)
		r.Get("/businesses/{businessID}/service-capabilities", h.serviceCapabilities)
		r.Get("/businesses/{businessID}/products", h.marketplaceProducts)
	})
	r.Route("/api/v1/businesses", func(r chi.Router) {
		r.Use(h.requireAuth)

		r.Get("/", h.list)
		r.Post("/", h.create)
		r.Get("/{businessID}", h.get)
		r.Put("/{businessID}", h.update)
		r.Post("/{businessID}/media", h.uploadBusinessMedia)
		r.Get("/{businessID}/branches", h.listBranches)
		r.Post("/{businessID}/branches", h.createBranch)
		// Restaurant vertical capability.
		// Scoped by authenticated tenant + business.
		r.Route("/{businessID}/restaurant", func(r chi.Router) {
			r.Get("/tables", h.restaurantListTables)

			r.Get("/orders", h.restaurantListOrders)
			r.Post("/orders", h.restaurantCreateOrder)

			r.Get("/orders/{orderID}", h.restaurantGetOrder)
			r.Post("/orders/{orderID}/items", h.restaurantAddOrderItem)

			r.Patch("/orders/{orderID}", h.restaurantUpdateOrder)
			r.Patch("/orders/{orderID}/status", h.restaurantUpdateOrderStatus)
		})
	})

	return r
}

func (h *Handler) uploadBusinessMedia(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	businessID := chi.URLParam(r, "businessID")
	mediaType := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("type")))

	if mediaType != "logo" && mediaType != "header" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_MEDIA_TYPE",
			"type must be logo or header",
		)
		return
	}

	// Verify that this business belongs to the authenticated tenant.
	var existingURL *string

	column := "logo_url"
	if mediaType == "header" {
		column = "cover_image_url"
	}

	err := h.DB.QueryRow(
		r.Context(),
		`SELECT `+column+`
                 FROM businesses
                 WHERE id = $1
                   AND tenant_id = $2
                   AND status = 'active'`,
		businessID,
		claims.TenantID,
	).Scan(&existingURL)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"ERROR",
			"business not found",
		)
		return
	}

	const maxUploadSize = int64(5 * 1024 * 1024)

	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize+1024)

	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_FILE",
			"file terlalu besar atau multipart tidak valid",
		)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"FILE_REQUIRED",
			"file wajib diunggah",
		)
		return
	}
	defer file.Close()

	if header.Size <= 0 || header.Size > maxUploadSize {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_FILE_SIZE",
			"ukuran file maksimal 5 MB",
		)
		return
	}

	// Read enough bytes to validate the actual content type.
	buffer := make([]byte, 512)
	n, err := file.Read(buffer)
	if err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_FILE",
			"file tidak dapat dibaca",
		)
		return
	}

	detectedType := http.DetectContentType(buffer[:n])

	allowedTypes := map[string]string{
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/webp": ".webp",
	}

	extension, allowed := allowedTypes[detectedType]
	if !allowed {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_FILE_TYPE",
			"format yang didukung: JPG, PNG, WebP",
		)
		return
	}

	if _, err := file.Seek(0, 0); err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_FILE",
			"file tidak dapat diproses",
		)
		return
	}

	uploadDir := filepath.Join("/app/uploads", "business", businessID)

	if err := os.MkdirAll(uploadDir, 0o755); err != nil {
		log.Printf("business media mkdir failed: %v", err)
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"STORAGE_ERROR",
			"gagal menyiapkan storage",
		)
		return
	}

	filename := mediaType + "-" + time.Now().UTC().Format("20060102-150405.000000000") + extension
	filename = strings.ReplaceAll(filename, ".", "_") + extension

	// Restore a clean extension after timestamp formatting.
	filename = mediaType + "-" + time.Now().UTC().Format("20060102-150405.000000000") + extension

	destination := filepath.Join(uploadDir, filename)

	dst, err := os.Create(destination)
	if err != nil {
		log.Printf("business media create failed: %v", err)
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"STORAGE_ERROR",
			"gagal menyimpan file",
		)
		return
	}

	_, copyErr := io.Copy(dst, file)
	closeErr := dst.Close()

	if copyErr != nil || closeErr != nil {
		_ = os.Remove(destination)
		log.Printf("business media write failed: copy=%v close=%v", copyErr, closeErr)
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"STORAGE_ERROR",
			"gagal menulis file",
		)
		return
	}

	publicURL := "/uploads/business/" + businessID + "/" + filename

	var updatedURL string

	if mediaType == "logo" {
		err = h.DB.QueryRow(
			r.Context(),
			`
                        UPDATE businesses
                        SET logo_url = $1,
                            updated_at = NOW()
                        WHERE id = $2
                          AND tenant_id = $3
                        RETURNING logo_url
                        `,
			publicURL,
			businessID,
			claims.TenantID,
		).Scan(&updatedURL)
	} else {
		err = h.DB.QueryRow(
			r.Context(),
			`
                        UPDATE businesses
                        SET cover_image_url = $1,
                            updated_at = NOW()
                        WHERE id = $2
                          AND tenant_id = $3
                        RETURNING cover_image_url
                        `,
			publicURL,
			businessID,
			claims.TenantID,
		).Scan(&updatedURL)
	}

	if err != nil {
		_ = os.Remove(destination)
		log.Printf("business media database update failed: %v", err)
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"DATABASE_ERROR",
			"gagal menyimpan referensi media",
		)
		return
	}

	// Remove the previous uploaded file only when it belongs to our
	// business upload storage. Never delete arbitrary external URLs.
	if existingURL != nil && *existingURL != "" {
		oldURL := *existingURL

		if strings.HasPrefix(oldURL, "/uploads/business/"+businessID+"/") {
			oldPath := filepath.Join(
				"/app",
				strings.TrimPrefix(oldURL, "/"),
			)

			if oldPath != destination {
				if err := os.Remove(oldPath); err != nil && !os.IsNotExist(err) {
					log.Printf("old business media cleanup failed: %v", err)
				}
			}
		}
	}

	if h.Events != nil {
		if err := h.Events.PublishBusinessIdentityUpdated(
			r.Context(),
			businessID,
			claims.TenantID,
		); err != nil {
			events.LogPublishError(err)
		}
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"business_id": businessID,
			"type":        mediaType,
			"url":         updatedURL,
		},
	})
}
func (h *Handler) createServiceQuote(w http.ResponseWriter, r *http.Request) {
	businessID := chi.URLParam(r, "businessID")

	var req createServiceQuoteRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_REQUEST",
			"invalid request body",
		)
		return
	}

	req.CustomerName = strings.TrimSpace(req.CustomerName)
	req.CustomerWhatsApp = strings.TrimSpace(req.CustomerWhatsApp)
	req.CustomerEmail = strings.TrimSpace(req.CustomerEmail)
	req.Brief = strings.TrimSpace(req.Brief)
	req.Budget = strings.TrimSpace(req.Budget)
	req.Deadline = strings.TrimSpace(req.Deadline)
	req.Notes = strings.TrimSpace(req.Notes)

	if req.CustomerName == "" ||
		req.CustomerWhatsApp == "" ||
		req.Brief == "" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"VALIDATION_ERROR",
			"nama, WhatsApp, dan kebutuhan wajib diisi",
		)
		return
	}

	var businessType string
	var businessName string

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT business_type, name
        FROM businesses
        WHERE id = $1
          AND status = 'active'
        `,
		businessID,
	).Scan(&businessType, &businessName)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"ERROR",
			"business not found",
		)
		return
	}

	if businessType != "service" {
		httpx.Fail(
			w,
			http.StatusBadRequest,
			"INVALID_BUSINESS_TYPE",
			"service quotation is only available for service businesses",
		)
		return
	}

	var quoteID string

	err = h.DB.QueryRow(
		r.Context(),
		`
        INSERT INTO service_quotes (
            business_id,
            customer_name,
            customer_whatsapp,
            customer_email,
            brief,
            budget,
            deadline,
            notes,
            status
        )
        VALUES (
            $1,
            $2,
            $3,
            NULLIF($4, ''),
            $5,
            NULLIF($6, ''),
            NULLIF($7, ''),
            NULLIF($8, ''),
            'pending'
        )
        RETURNING id::text
        `,
		businessID,
		req.CustomerName,
		req.CustomerWhatsApp,
		req.CustomerEmail,
		req.Brief,
		req.Budget,
		req.Deadline,
		req.Notes,
	).Scan(&quoteID)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"failed to create service quotation",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusCreated,
		map[string]any{
			"success": true,
			"data": map[string]any{
				"id":            quoteID,
				"business_id":   businessID,
				"business_name": businessName,
				"status":        "pending",
				"message":       "Penawaran jasa berhasil dikirim.",
			},
		},
	)
}
func (h *Handler) serviceCapabilities(w http.ResponseWriter, r *http.Request) {
	businessID := chi.URLParam(r, "businessID")

	var (
		businessType string
		kbliCode     string
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            business_type,
            COALESCE(kbli_code, '')
        FROM businesses
        WHERE id = $1
          AND status = 'active'
        `,
		businessID,
	).Scan(
		&businessType,
		&kbliCode,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"ERROR",
			"business not found",
		)
		return
	}

	businessContext, err := h.marketplaceCapabilities(
		r.Context(),
		businessID,
		businessType,
		kbliCode,
	)

	if err != nil {
		log.Printf(
			"failed to resolve marketplace capabilities for business %s: %v",
			businessID,
			err,
		)

		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"failed to resolve marketplace capabilities",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"business_id":          businessID,
			"business_type":        businessContext.BusinessType,
			"business_mode":        businessContext.BusinessMode,
			"marketplace_template": businessContext.MarketplaceTemplate,
			"kbli_code":            businessContext.KbliCode,
			"product_count":        businessContext.ProductCount,
			"service_count":        businessContext.ServiceCount,
			"capabilities":         businessContext.Capabilities,
			"business_profile":     businessContext.BusinessProfile,
			"mobile_modules":       businessContext.MobileModules,
		},
	)
}
func (h *Handler) marketplaceBusinesses(w http.ResponseWriter, r *http.Request) {
	query := strings.TrimSpace(r.URL.Query().Get("q"))

	if query == "" {
		query = strings.TrimSpace(r.URL.Query().Get("query"))
	}

	sql := `
        SELECT
            b.id,
            b.name,
            bl.legal_name,
            b.business_type,
            b.activity,
            b.kbli_code,
            b.kbli_name,
            b.phone,
            b.email,
            b.address,
            b.status,
            b.short_name,
            b.tagline,
            b.description,
            b.whatsapp,
            b.website,
            b.logo_url,
            b.cover_image_url,
            b.brand_color,
            COALESCE(bv.status, 'unverified') AS verification_status,
            COALESCE(bv.verified, false) AS verification_verified,
            COALESCE(bv.verification_level, 'basic') AS verification_level,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN '✓ NUSA-DHIPA VERIFIED'
                ELSE 'BELUM TERVERIFIKASI'
            END AS verification_badge,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN bv.verification_code
                ELSE NULL
            END AS verification_code,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN bv.public_url
                ELSE NULL
            END AS verification_public_url
        FROM businesses b
        LEFT JOIN business_legalities bl
            ON bl.business_id = b.id
        LEFT JOIN business_verifications bv
            ON bv.business_id = b.id
        WHERE b.status = 'active'
    `

	args := []any{}

	if query != "" {
		sql += `
            AND (
                b.name ILIKE $1
                OR COALESCE(bl.legal_name, '') ILIKE $1
                OR COALESCE(b.short_name, '') ILIKE $1
                OR COALESCE(b.activity, '') ILIKE $1
                OR COALESCE(b.kbli_name, '') ILIKE $1
                OR COALESCE(b.tagline, '') ILIKE $1
                OR COALESCE(b.description, '') ILIKE $1
                OR COALESCE(b.address, '') ILIKE $1
            )
        `

		args = append(args, "%"+query+"%")
	}

	sql += `
        ORDER BY name ASC
    `

	rows, err := h.DB.Query(
		r.Context(),
		sql,
		args...,
	)

	if err != nil {
		log.Printf(
			"marketplace business query failed: %v",
			err,
		)

		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"marketplace business query failed",
		)
		return
	}

	defer rows.Close()

	items := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id                    string
			name                  string
			legalName             *string
			businessType          string
			activity              *string
			kbliCode              *string
			kbliName              *string
			phone                 *string
			email                 *string
			address               *string
			status                string
			shortName             *string
			tagline               *string
			description           *string
			whatsapp              *string
			website               *string
			logoURL               *string
			coverImageURL         *string
			brandColor            *string
			verificationStatus    string
			verificationVerified  bool
			verificationLevel     string
			verificationBadge     string
			verificationCode      *string
			verificationPublicURL *string
		)

		if err := rows.Scan(
			&id,
			&name,
			&legalName,
			&businessType,
			&activity,
			&kbliCode,
			&kbliName,
			&phone,
			&email,
			&address,
			&status,
			&shortName,
			&tagline,
			&description,
			&whatsapp,
			&website,
			&logoURL,
			&coverImageURL,
			&brandColor,
			&verificationStatus,
			&verificationVerified,
			&verificationLevel,
			&verificationBadge,
			&verificationCode,
			&verificationPublicURL,
		); err != nil {
			httpx.Fail(
				w,
				http.StatusInternalServerError,
				"ERROR",
				"marketplace business scan failed",
			)
			return
		}

		resolvedKbliCode := ""

		if kbliCode != nil {
			resolvedKbliCode = strings.TrimSpace(*kbliCode)
		}

		businessContext, err := h.marketplaceCapabilities(
			r.Context(),
			id,
			businessType,
			resolvedKbliCode,
		)

		if err != nil {
			log.Printf(
				"marketplace capability resolution failed for business %s: %v",
				id,
				err,
			)

			httpx.Fail(
				w,
				http.StatusInternalServerError,
				"ERROR",
				"marketplace capability resolution failed",
			)
			return
		}

		items = append(
			items,
			map[string]any{
				"id":               id,
				"name":             name,
				"legal_name":       legalName,
				"business_type":    businessType,
				"business_mode":    businessContext.BusinessMode,
				"activity":         activity,
				"kbli_code":        kbliCode,
				"kbli_name":        kbliName,
				"product_count":    businessContext.ProductCount,
				"service_count":    businessContext.ServiceCount,
				"capabilities":     businessContext.Capabilities,
				"business_profile": businessContext.BusinessProfile,
				"mobile_modules":   businessContext.MobileModules,
				"phone":            phone,
				"email":            email,
				"address":          address,
				"status":           status,
				"short_name":       shortName,
				"tagline":          tagline,
				"description":      description,
				"whatsapp":         whatsapp,
				"website":          website,
				"logo_url":         logoURL,
				"cover_image_url":  coverImageURL,
				"brand_color":      brandColor,
				"verification": map[string]any{
					"status":            verificationStatus,
					"verified":          verificationVerified,
					"level":             verificationLevel,
					"badge":             verificationBadge,
					"verification_code": verificationCode,
					"public_url":        verificationPublicURL,
				},
			},
		)
	}

	if err := rows.Err(); err != nil {
		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"marketplace business rows failed",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"items": items,
			"total": len(items),
			"query": query,
		},
	)
}

func (h *Handler) marketplaceBusiness(w http.ResponseWriter, r *http.Request) {
	businessID := chi.URLParam(r, "businessID")

	var (
		id                    string
		name                  string
		legalName             *string
		businessType          string
		activity              *string
		kbliCode              *string
		kbliName              *string
		phone                 *string
		email                 *string
		address               *string
		status                string
		shortName             *string
		tagline               *string
		description           *string
		whatsapp              *string
		website               *string
		logoURL               *string
		coverImageURL         *string
		brandColor            *string
		verificationStatus    string
		verificationVerified  bool
		verificationLevel     string
		verificationBadge     string
		verificationCode      *string
		verificationPublicURL *string
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            b.id,
            b.name,
            bl.legal_name,
            b.business_type,
            b.activity,
            b.kbli_code,
            b.kbli_name,
            b.phone,
            b.email,
            b.address,
            b.status,
            b.short_name,
            b.tagline,
            b.description,
            b.whatsapp,
            b.website,
            b.logo_url,
            b.cover_image_url,
            b.brand_color,
            COALESCE(bv.status, 'unverified') AS verification_status,
            COALESCE(bv.verified, false) AS verification_verified,
            COALESCE(bv.verification_level, 'basic') AS verification_level,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN '✓ NUSA-DHIPA VERIFIED'
                ELSE 'BELUM TERVERIFIKASI'
            END AS verification_badge,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN bv.verification_code
                ELSE NULL
            END AS verification_code,
            CASE
                WHEN bv.status = 'verified' AND bv.verified = true
                THEN bv.public_url
                ELSE NULL
            END AS verification_public_url
        FROM businesses b
        LEFT JOIN business_legalities bl
            ON bl.business_id = b.id
        LEFT JOIN business_verifications bv
            ON bv.business_id = b.id
        WHERE b.id = $1
          AND b.status = 'active'
        `,
		businessID,
	).Scan(
		&id,
		&name,
		&legalName,
		&businessType,
		&activity,
		&kbliCode,
		&kbliName,
		&phone,
		&email,
		&address,
		&status,
		&shortName,
		&tagline,
		&description,
		&whatsapp,
		&website,
		&logoURL,
		&coverImageURL,
		&brandColor,
		&verificationStatus,
		&verificationVerified,
		&verificationLevel,
		&verificationBadge,
		&verificationCode,
		&verificationPublicURL,
	)

	if err != nil {
		httpx.Fail(
			w,
			http.StatusNotFound,
			"ERROR",
			"marketplace business not found",
		)
		return
	}

	resolvedKbliCode := ""

	if kbliCode != nil {
		resolvedKbliCode = strings.TrimSpace(*kbliCode)
	}

	businessContext, err := h.marketplaceCapabilities(
		r.Context(),
		businessID,
		businessType,
		resolvedKbliCode,
	)

	if err != nil {
		log.Printf(
			"marketplace capability resolution failed for business %s: %v",
			businessID,
			err,
		)

		httpx.Fail(
			w,
			http.StatusInternalServerError,
			"ERROR",
			"marketplace capability resolution failed",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"id":               id,
			"name":             name,
			"legal_name":       legalName,
			"business_type":    businessType,
			"business_mode":    businessContext.BusinessMode,
			"activity":         activity,
			"kbli_code":        kbliCode,
			"kbli_name":        kbliName,
			"product_count":    businessContext.ProductCount,
			"service_count":    businessContext.ServiceCount,
			"capabilities":     businessContext.Capabilities,
			"business_profile": businessContext.BusinessProfile,
			"mobile_modules":   businessContext.MobileModules,
			"phone":            phone,
			"email":            email,
			"address":          address,
			"status":           status,
			"short_name":       shortName,
			"tagline":          tagline,
			"description":      description,
			"whatsapp":         whatsapp,
			"website":          website,
			"logo_url":         logoURL,
			"cover_image_url":  coverImageURL,
			"brand_color":      brandColor,
			"verification": map[string]any{
				"status":            verificationStatus,
				"verified":          verificationVerified,
				"level":             verificationLevel,
				"badge":             verificationBadge,
				"verification_code": verificationCode,
				"public_url":        verificationPublicURL,
			},
		},
	)
}

func (h *Handler) marketplaceProducts(w http.ResponseWriter, r *http.Request) {
    businessID := chi.URLParam(r, "businessID")

    rows, err := h.DB.Query(
        r.Context(),
        `
        SELECT
            p.id,
            p.sku,
            p.name,
            p.description,
            p.product_type,
            p.unit,
            p.price::double precision,
            p.status,
            COALESCE(c.name, '') AS category,
            COALESCE(
                SUM(i.quantity - i.reserved_quantity),
                0
            )::double precision AS available_stock,
            COALESCE(pi.image_url, '') AS image_url
        FROM catalog_products p
        LEFT JOIN catalog_categories c
            ON c.id = p.category_id
           AND c.status = 'active'
        LEFT JOIN inventory_balances i
            ON i.product_id = p.id
           AND i.business_id = p.business_id
        LEFT JOIN LATERAL (
            SELECT
                cpi.image_url
            FROM catalog_product_images cpi
            WHERE cpi.product_id = p.id
            ORDER BY
                CASE
                    WHEN cpi.is_primary = true THEN 0
                    ELSE 1
                END,
                cpi.sort_order ASC,
                cpi.created_at ASC
            LIMIT 1
        ) pi ON true
        INNER JOIN businesses b
            ON b.id = p.business_id
           AND b.status = 'active'
        WHERE p.business_id = $1
          AND p.status = 'active'
        GROUP BY
            p.id,
            p.sku,
            p.name,
            p.description,
            p.product_type,
            p.unit,
            p.price,
            p.status,
            c.name,
            pi.image_url
        ORDER BY p.name ASC
        `,
        businessID,
    )

    if err != nil {
        httpx.Fail(
            w,
            http.StatusInternalServerError,
            "ERROR",
            "marketplace product query failed",
        )
        return
    }

    defer rows.Close()

    items := []map[string]any{}

    for rows.Next() {
        var (
            id             string
            sku            string
            name           string
            description    string
            productType    string
            unit           string
            price          float64
            status         string
            category       string
            availableStock float64
            imageURL       string
        )

        if err := rows.Scan(
            &id,
            &sku,
            &name,
            &description,
            &productType,
            &unit,
            &price,
            &status,
            &category,
            &availableStock,
            &imageURL,
        ); err != nil {
            httpx.Fail(
                w,
                http.StatusInternalServerError,
                "ERROR",
                "marketplace product scan failed",
            )
            return
        }

        item := map[string]any{
            "id":              id,
            "sku":             sku,
            "name":            name,
            "description":     description,
            "product_type":    productType,
            "unit":            unit,
            "price":           price,
            "status":          status,
            "category":        category,
            "available_stock": availableStock,
        }

        if imageURL != "" {
            item["image_url"] = imageURL
        }

        items = append(items, item)
    }

    if err := rows.Err(); err != nil {
        httpx.Fail(
            w,
            http.StatusInternalServerError,
            "ERROR",
            "marketplace product rows failed",
        )
        return
    }

    httpx.JSON(w, http.StatusOK, map[string]any{
        "success": true,
        "data": map[string]any{
            "business_id": businessID,
            "items":       items,
            "total":       len(items),
        },
    })
}
func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"service": "business",
			"status":  "healthy",
		},
	})
}

func (h *Handler) requireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")

		if !strings.HasPrefix(header, "Bearer ") {
			httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing bearer token")
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))

		claims, err := auth.ParseToken(h.JWTSecret, token)
		if err != nil {
			httpx.Fail(w, http.StatusUnauthorized, "ERROR", "invalid token")
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
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	rows, err := h.DB.Query(
		r.Context(),
		`SELECT id, name, business_type, phone, email, address,
                created_at, updated_at
         FROM businesses
         WHERE tenant_id = $1
         ORDER BY created_at`,
		claims.TenantID,
	)
	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "query failed")
		return
	}
	defer rows.Close()

	items := []map[string]any{}

	for rows.Next() {
		var (
			id           any
			name         string
			legalName    *string
			businessType string
			phone        *string
			email        *string
			address      *string
			createdAt    any
			updatedAt    any
		)

		if err := rows.Scan(
			&id,
			&name,
			&legalName,
			&businessType,
			&phone,
			&email,
			&address,
			&createdAt,
			&updatedAt,
		); err != nil {
			httpx.Fail(w, http.StatusInternalServerError, "ERROR", "scan failed")
			return
		}

		items = append(items, map[string]any{
			"id":            id,
			"name":          name,
			"business_type": businessType,
			"phone":         phone,
			"email":         email,
			"address":       address,
			"created_at":    createdAt,
			"updated_at":    updatedAt,
		})
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"items": items,
			"total": len(items),
		},
	})
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	var req createBusinessRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "invalid JSON")
		return
	}

	req.Name = strings.TrimSpace(req.Name)

	if req.Name == "" {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "name is required")
		return
	}

	if req.BusinessType == "" {
		req.BusinessType = "generic"
	}

	var id any

	err := h.DB.QueryRow(
		r.Context(),
		`INSERT INTO businesses(
            tenant_id,
            name,
            business_type,
            phone,
            email,
            address
        )
        VALUES($1,$2,$3,$4,$5,$6)
        RETURNING id`,
		claims.TenantID,
		req.Name,
		req.BusinessType,
		req.Phone,
		req.Address,
	).Scan(&id)

	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "business creation failed")
		return
	}

	httpx.JSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":            id,
			"name":          req.Name,
			"business_type": req.BusinessType,
		},
	})
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	id := chi.URLParam(r, "businessID")

	var (
		name          string
		businessType  string
		activity      *string
		kbliCode      *string
		kbliName      *string
		phone         *string
		email         *string
		address       *string
		status        string
		shortName     *string
		tagline       *string
		description   *string
		whatsapp      *string
		website       *string
		logoURL       *string
		coverImageURL *string
		brandColor    *string
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
        SELECT
            name,
            business_type,
            activity,
            kbli_code,
            kbli_name,
            phone,
            email,
            address,
            status,
            short_name,
            tagline,
            description,
            whatsapp,
            website,
            logo_url,
            cover_image_url,
            brand_color
        FROM businesses
        WHERE id = $1
          AND tenant_id = $2
        `,
		id,
		claims.TenantID,
	).Scan(
		&name,
		&businessType,
		&activity,
		&kbliCode,
		&kbliName,
		&phone,
		&email,
		&address,
		&status,
		&shortName,
		&tagline,
		&description,
		&whatsapp,
		&website,
		&logoURL,
		&coverImageURL,
		&brandColor,
	)

	if err != nil {
		httpx.Fail(w, http.StatusNotFound, "ERROR", "business not found")
		return
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":              id,
			"name":            name,
			"business_type":   businessType,
			"activity":        activity,
			"kbli_code":       kbliCode,
			"kbli_name":       kbliName,
			"phone":           phone,
			"email":           email,
			"address":         address,
			"status":          status,
			"short_name":      shortName,
			"tagline":         tagline,
			"description":     description,
			"whatsapp":        whatsapp,
			"website":         website,
			"logo_url":        logoURL,
			"cover_image_url": coverImageURL,
			"brand_color":     brandColor,
		},
	})
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	businessID := chi.URLParam(r, "businessID")

	var req updateBusinessRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "invalid JSON")
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.BusinessType = strings.TrimSpace(req.BusinessType)
	req.Activity = strings.TrimSpace(req.Activity)
	req.KbliCode = strings.TrimSpace(req.KbliCode)
	req.KbliName = strings.TrimSpace(req.KbliName)
	req.Phone = strings.TrimSpace(req.Phone)
	req.Email = strings.TrimSpace(req.Email)
	req.Address = strings.TrimSpace(req.Address)
	req.ShortName = strings.TrimSpace(req.ShortName)
	req.Tagline = strings.TrimSpace(req.Tagline)
	req.Description = strings.TrimSpace(req.Description)
	req.Whatsapp = strings.TrimSpace(req.Whatsapp)
	req.Website = strings.TrimSpace(req.Website)
	req.LogoURL = strings.TrimSpace(req.LogoURL)
	req.CoverImageURL = strings.TrimSpace(req.CoverImageURL)
	req.BrandColor = strings.TrimSpace(req.BrandColor)

	if req.Name == "" {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "name is required")
		return
	}

	if req.BusinessType == "" {
		req.BusinessType = "generic"
	}

	var id string

	err := h.DB.QueryRow(
		r.Context(),
		`
        UPDATE businesses
        SET
            name = $1,
            business_type = $2,
            activity = NULLIF($3, ''),
            kbli_code = NULLIF($4, ''),
            kbli_name = NULLIF($5, ''),
            phone = NULLIF($6, ''),
            email = NULLIF($7, ''),
            address = NULLIF($8, ''),
            short_name = NULLIF($9, ''),
            tagline = NULLIF($10, ''),
            description = NULLIF($11, ''),
            whatsapp = NULLIF($12, ''),
            website = NULLIF($13, ''),
            logo_url = NULLIF($14, ''),
            cover_image_url = NULLIF($15, ''),
            brand_color = NULLIF($16, ''),
            updated_at = NOW()
        WHERE id = $17
          AND tenant_id = $18
        RETURNING id
        `,
		req.Name,
		req.BusinessType,
		req.Activity,
		req.KbliCode,
		req.KbliName,
		req.Phone,
		req.Email,
		req.Address,
		req.ShortName,
		req.Tagline,
		req.Description,
		req.Whatsapp,
		req.Website,
		req.LogoURL,
		req.CoverImageURL,
		req.BrandColor,
		businessID,
		claims.TenantID,
	).Scan(&id)

	if err != nil {
		httpx.Fail(w, http.StatusNotFound, "ERROR", "business not found")
		return
	}
	if h.Events != nil {
		if err := h.Events.PublishBusinessIdentityUpdated(
			r.Context(),
			businessID,
			claims.TenantID,
		); err != nil {
			events.LogPublishError(err)
		}
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":              id,
			"name":            req.Name,
			"business_type":   req.BusinessType,
			"activity":        req.Activity,
			"kbli_code":       req.KbliCode,
			"kbli_name":       req.KbliName,
			"phone":           req.Phone,
			"email":           req.Email,
			"address":         req.Address,
			"short_name":      req.ShortName,
			"tagline":         req.Tagline,
			"description":     req.Description,
			"whatsapp":        req.Whatsapp,
			"website":         req.Website,
			"logo_url":        req.LogoURL,
			"cover_image_url": req.CoverImageURL,
			"brand_color":     req.BrandColor,
			"status":          "active",
		},
	})
}
func (h *Handler) listBranches(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	businessID := chi.URLParam(r, "businessID")

	rows, err := h.DB.Query(
		r.Context(),
		`SELECT id, name, code, phone, address, is_main, status
         FROM branches
         WHERE business_id = $1 AND tenant_id = $2
         ORDER BY is_main DESC, created_at`,
		businessID,
		claims.TenantID,
	)
	if err != nil {
		httpx.Fail(w, http.StatusInternalServerError, "ERROR", "query failed")
		return
	}
	defer rows.Close()

	items := []map[string]any{}

	for rows.Next() {
		var (
			id        any
			name      string
			legalName *string
			code      string
			phone     *string
			address   *string
			isMain    bool
			status    string
		)

		if err := rows.Scan(
			&id,
			&name,
			&legalName,
			&code,
			&phone,
			&address,
			&isMain,
			&status,
		); err != nil {
			httpx.Fail(w, http.StatusInternalServerError, "ERROR", "scan failed")
			return
		}

		items = append(items, map[string]any{
			"id":      id,
			"name":    name,
			"code":    code,
			"phone":   phone,
			"address": address,
			"is_main": isMain,
			"status":  status,
		})
	}

	httpx.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"items": items,
			"total": len(items),
		},
	})
}

func (h *Handler) createBranch(w http.ResponseWriter, r *http.Request) {
	claims, ok := getClaims(r)
	if !ok {
		httpx.Fail(w, http.StatusUnauthorized, "ERROR", "missing tenant context")
		return
	}

	businessID := chi.URLParam(r, "businessID")

	var req createBranchRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "invalid JSON")
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Code = strings.ToUpper(strings.TrimSpace(req.Code))

	if req.Name == "" || req.Code == "" {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "name and code are required")
		return
	}

	var id any

	err := h.DB.QueryRow(
		r.Context(),
		`INSERT INTO branches(
            business_id,
            tenant_id,
            name,
            code,
            phone,
            address
        )
        SELECT $1, $2, $3, $4, $5, $6
        WHERE EXISTS (
            SELECT 1
            FROM businesses
            WHERE id = $1 AND tenant_id = $2
        )
        RETURNING id`,
		businessID,
		claims.TenantID,
		req.Name,
		req.Code,
		req.Phone,
		req.Address,
	).Scan(&id)

	if err != nil {
		httpx.Fail(w, http.StatusBadRequest, "ERROR", "branch creation failed")
		return
	}

	httpx.JSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":      id,
			"name":    req.Name,
			"code":    req.Code,
			"status":  "active",
			"is_main": false,
		},
	})
}


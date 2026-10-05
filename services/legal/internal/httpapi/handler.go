package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	DB *pgxpool.Pool
}

func NewRouter(h *Handler, jwtSecret string) http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", h.health)

	mux.HandleFunc(
		"/api/v1/legal/public/setup-requests",
		h.publicSetupRequest,
	)

	mux.Handle(
		"/api/v1/legal/businesses/",
		JWTMiddleware(jwtSecret)(
			http.HandlerFunc(h.businessLegality),
		),
	)

	mux.Handle(
		"/api/v1/legal/registration-requests/",
		JWTMiddleware(jwtSecret)(
			http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				path := strings.TrimPrefix(
					r.URL.Path,
					"/api/v1/legal/registration-requests/",
				)

				path = strings.Trim(path, "/")

				if path == "" {
					http.NotFound(w, r)
					return
				}

				parts := strings.Split(path, "/")

				// GET /registration-requests/{requestID}
				if len(parts) == 1 {
					if r.Method != http.MethodGet {
						w.WriteHeader(http.StatusMethodNotAllowed)
						return
					}

					h.registrationRequestByID(
						w,
						r,
						parts[0],
					)
					return
				}

				// POST /registration-requests/{requestID}/submit
				if len(parts) == 2 &&
					strings.EqualFold(parts[1], "submit") {

					if r.Method != http.MethodPost {
						w.WriteHeader(http.StatusMethodNotAllowed)
						return
					}

					h.submitRegistrationRequest(
						w,
						r,
						parts[0],
					)
					return
				}

				http.NotFound(w, r)
			}),
		),
	)

	mux.Handle(
		"/api/v1/legal/setup-requests",
		JWTMiddleware(jwtSecret)(
			http.HandlerFunc(h.setupRequest),
		),
	)

	return mux
}

func writeJSON(
	w http.ResponseWriter,
	status int,
	payload any,
) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	_ = json.NewEncoder(w).Encode(payload)
}

func (h *Handler) health(
	w http.ResponseWriter,
	r *http.Request,
) {
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"service": "legal",
			"status":  "healthy",
			"version": "0.1.0",
		},
	})
}

func (h *Handler) businessLegality(
	w http.ResponseWriter,
	r *http.Request,
) {
	path := strings.TrimPrefix(
		r.URL.Path,
		"/api/v1/legal/businesses/",
	)

	path = strings.Trim(path, "/")

	if path == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "BUSINESS_ID_REQUIRED",
				"message": "business id is required",
			},
		})
		return
	}

	parts := strings.Split(path, "/")

	// GET /api/v1/legal/businesses/{businessID}/status
	if len(parts) == 2 &&
		strings.EqualFold(parts[1], "status") {

		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		businessID := strings.TrimSpace(parts[0])

		if businessID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "BUSINESS_ID_REQUIRED",
					"message": "business id is required",
				},
			})
			return
		}

		h.getBusinessLegalStatus(
			w,
			r,
			businessID,
		)
		return
	}

	// GET/POST /api/v1/legal/businesses/{businessID}/registration-requests
	if len(parts) == 2 &&
		strings.EqualFold(parts[1], "registration-requests") {

		businessID := strings.TrimSpace(parts[0])

		if businessID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "BUSINESS_ID_REQUIRED",
					"message": "business id is required",
				},
			})
			return
		}

		h.registrationRequests(
			w,
			r,
			businessID,
		)
		return
	}

	// Existing business legality endpoint:
	// GET /api/v1/legal/businesses/{businessID}
	// PUT /api/v1/legal/businesses/{businessID}
	if len(parts) != 1 {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "LEGAL_ROUTE_NOT_FOUND",
				"message": "legal business route not found",
			},
		})
		return
	}

	businessID := strings.TrimSpace(parts[0])

	switch r.Method {
	case http.MethodGet:
		h.getBusinessLegality(
			w,
			r,
			businessID,
		)

	case http.MethodPut:
		h.upsertBusinessLegality(
			w,
			r,
			businessID,
		)

	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func (h *Handler) getBusinessLegalStatus(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	ctx := r.Context()

	authenticatedTenantID := strings.TrimSpace(
		tenantIDFromContext(ctx),
	)

	if authenticatedTenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	/*
		The status endpoint intentionally treats a missing
		business_legalities row as "not registered", not as 404.

		The business itself must still belong to the
		authenticated tenant.
	*/

	var (
		nib              *string
		nibStatus        string
		ahuNumber        *string
		ahuStatus        string
		legalForm        *string
		primaryKBLI      *string
		kbliVersion      *string
		kbliTitle        *string
		kbliStatus       string
		legacyVerifiedAt any
	)

	err := h.DB.QueryRow(
		ctx,
		`
		SELECT
			bl.nib,
			COALESCE(bl.nib_status, 'not_provided'),
			bl.ahu_number,
			COALESCE(bl.ahu_status, 'not_provided'),
			COALESCE(bl.legal_form, ''),
                        bl.primary_kbli,
                        bl.kbli_version,
                        bl.kbli_title,
                        COALESCE(bl.kbli_status, ''),
                        bl.verified_at
		FROM businesses b
		LEFT JOIN business_legalities bl
			ON bl.business_id = b.id
			AND bl.tenant_id = b.tenant_id
		WHERE b.id = $1
		  AND b.tenant_id = $2
		`,
		businessID,
		authenticatedTenantID,
	).Scan(
		&nib,
		&nibStatus,
		&ahuNumber,
		&ahuStatus,
		&legalForm,
		&primaryKBLI,
		&kbliVersion,
		&kbliTitle,
		&kbliStatus,
		&legacyVerifiedAt,
	)

	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "BUSINESS_NOT_FOUND",
				"message": "business not found",
			},
		})
		return
	}

	var response BusinessLegalStatusResponse

	response.BusinessStatus = "ACTIVE"

	/*
		Business management remains active.

		Legalisation is a trust/verification layer,
		not a marketplace selling blocker.
	*/
	response.CanOperate = true
	response.CanSell = true

	nibValue := ""
	if nib != nil {
		nibValue = strings.TrimSpace(*nib)
	}

	ahuValue := ""
	if ahuNumber != nil {
		ahuValue = strings.TrimSpace(*ahuNumber)
	}

	response.Legalization.NIB = registrationSummary(
		nibValue,
		nibStatus,
		"OSS",
	)

	response.Legalization.AHU = registrationSummary(
		ahuValue,
		ahuStatus,
		"AHU",
	)

	legalFormValue := ""

	if legalForm != nil {
		legalFormValue = strings.TrimSpace(*legalForm)
	}

	legalitasType := normalizeLegalitasType(
		legalFormValue,
	)

	/*
		If legal form is empty but NIB exists,
		the canonical type becomes NIB_ONLY.
	*/
	if legalitasType == LegalitasBelumAda &&
		nibValue != "" {

		legalitasType = LegalitasNIBOnly
	}

	response.LegalitasType = legalitasType

	/*
		AHU applicability follows canonical legalitas type.

		BELUM_ADA / NIB_ONLY:
			AHU is not treated as a missing requirement.

		Other legal forms:
			AHU can be part of the legalisation gap.
	*/
	ahuApplicable := legalitasAHUApplicable(
		legalitasType,
	)

	nibMissing :=
		response.Legalization.NIB.Status ==
			StatusNotRegistered

	ahuMissing :=
		ahuApplicable &&
			response.Legalization.AHU.Status ==
				StatusNotRegistered

	response.LegalizationRequired =
		nibMissing || ahuMissing

	/*
		Load all KBLI activities.

		Canonical source:
			business_kbli_activities
	*/
	rows, err := h.DB.Query(
		ctx,
		`
		SELECT
			k.kbli_code,
			k.kbli_version,
			k.kbli_title,
			k.is_primary,
			k.status,
			k.source,
			k.verified_at
		FROM business_kbli_activities k
		WHERE k.business_id = $1
		  AND k.tenant_id = $2
		ORDER BY
			k.is_primary DESC,
			k.kbli_code ASC
		`,
		businessID,
		authenticatedTenantID,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "KBLI_LOAD_FAILED",
				"message": "business KBLI activities could not be loaded",
			},
		})
		return
	}

	defer rows.Close()

	response.KBLI = make(
		[]KBLIActivityResponse,
		0,
	)

	for rows.Next() {
		var (
			code       string
			version    string
			title      *string
			isPrimary  bool
			status     string
			source     string
			verifiedAt any
		)

		if err := rows.Scan(
			&code,
			&version,
			&title,
			&isPrimary,
			&status,
			&source,
			&verifiedAt,
		); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "KBLI_LOAD_FAILED",
					"message": "business KBLI activities could not be read",
				},
			})
			return
		}

		titleValue := ""

		if title != nil {
			titleValue = strings.TrimSpace(*title)
		}

		response.KBLI = append(
			response.KBLI,
			KBLIActivityResponse{
				Code:    strings.TrimSpace(code),
				Version: strings.TrimSpace(version),
				Title:   titleValue,
				Primary: isPrimary,
				Status: strings.ToUpper(
					strings.TrimSpace(status),
				),
				Source:     strings.TrimSpace(source),
				VerifiedAt: verifiedAt,
			},
		)
	}

	if err := rows.Err(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "KBLI_LOAD_FAILED",
				"message": "business KBLI activities could not be loaded",
			},
		})
		return
	}

	/*
	   Backward compatibility:

	   Canonical KBLI source:
	           business_kbli_activities

	   Legacy KBLI source:
	           business_legalities.primary_kbli

	   If the canonical table has no activity rows,
	   expose the legacy KBLI through this status endpoint.
	*/
	if len(response.KBLI) == 0 && primaryKBLI != nil {
		code := strings.TrimSpace(*primaryKBLI)

		if code != "" {
			version := "2025"

			if kbliVersion != nil &&
				strings.TrimSpace(*kbliVersion) != "" {
				version = strings.TrimSpace(*kbliVersion)
			}

			title := ""

			if kbliTitle != nil {
				title = strings.TrimSpace(*kbliTitle)
			}

			status := strings.ToUpper(
				strings.TrimSpace(kbliStatus),
			)

			if status == "" {
				status = "ACTIVE"
			}

			response.KBLI = append(
				response.KBLI,
				KBLIActivityResponse{
					Code:       code,
					Version:    version,
					Title:      title,
					Primary:    true,
					Status:     status,
					Source:     "legacy",
					VerifiedAt: legacyVerifiedAt,
				},
			)
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    response,
	})
}

func (h *Handler) getBusinessLegality(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	ctx := r.Context()

	authenticatedTenantID := strings.TrimSpace(
		tenantIDFromContext(ctx),
	)

	if authenticatedTenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	var (
		id                 string
		tenantID           string
		legalForm          *string
		legalName          *string
		nib                *string
		nibStatus          string
		ahuNumber          *string
		ahuStatus          string
		primaryKBLI        *string
		kbliVersion        *string
		kbliTitle          *string
		kbliStatus         string
		verificationStatus string
		verifiedAt         any
		notes              *string
	)

	err := h.DB.QueryRow(
		ctx,
		`
		SELECT
			bl.id,
			bl.tenant_id,
			bl.legal_form,
			bl.legal_name,
			bl.nib,
			bl.nib_status,
			bl.ahu_number,
			bl.ahu_status,
			bl.primary_kbli,
			bl.kbli_version,
			bl.kbli_title,
			bl.kbli_status,
			bl.verification_status,
			bl.verified_at,
			bl.notes
		FROM business_legalities bl
		WHERE bl.business_id = $1
		  AND bl.tenant_id = $2
		  AND EXISTS (
				SELECT 1
				FROM businesses b
				WHERE b.id = bl.business_id
				  AND b.tenant_id = $2
		  )
		`,
		businessID,
		authenticatedTenantID,
	).Scan(
		&id,
		&tenantID,
		&legalForm,
		&legalName,
		&nib,
		&nibStatus,
		&ahuNumber,
		&ahuStatus,
		&primaryKBLI,
		&kbliVersion,
		&kbliTitle,
		&kbliStatus,
		&verificationStatus,
		&verifiedAt,
		&notes,
	)

	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "LEGALITY_NOT_FOUND",
				"message": "business legality not found",
			},
		})
		return
	}

	legalFormValue := ""

	if legalForm != nil {
		legalFormValue = strings.TrimSpace(*legalForm)
	}

	nibValue := ""

	if nib != nil {
		nibValue = strings.TrimSpace(*nib)
	}

	legalitasType := normalizeLegalitasType(
		legalFormValue,
	)

	if legalitasType == LegalitasBelumAda &&
		nibValue != "" {

		legalitasType = LegalitasNIBOnly
	}

	/*
		Load canonical KBLI activity rows.
	*/
	rows, err := h.DB.Query(
		ctx,
		`
		SELECT
			k.kbli_code,
			k.kbli_version,
			k.kbli_title,
			k.is_primary,
			k.status,
			k.source,
			k.verified_at
		FROM business_kbli_activities k
		WHERE k.business_id = $1
		  AND k.tenant_id = $2
		ORDER BY
			k.is_primary DESC,
			k.kbli_code ASC
		`,
		businessID,
		authenticatedTenantID,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "KBLI_LOAD_FAILED",
				"message": "business KBLI activities could not be loaded",
			},
		})
		return
	}

	defer rows.Close()

	kbli := make(
		[]KBLIActivityResponse,
		0,
	)

	for rows.Next() {
		var (
			code       string
			version    string
			title      *string
			isPrimary  bool
			status     string
			source     string
			verifiedAt any
		)

		if err := rows.Scan(
			&code,
			&version,
			&title,
			&isPrimary,
			&status,
			&source,
			&verifiedAt,
		); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "KBLI_LOAD_FAILED",
					"message": "business KBLI activities could not be read",
				},
			})
			return
		}

		titleValue := ""

		if title != nil {
			titleValue = strings.TrimSpace(*title)
		}

		kbli = append(
			kbli,
			KBLIActivityResponse{
				Code:    strings.TrimSpace(code),
				Version: strings.TrimSpace(version),
				Title:   titleValue,
				Primary: isPrimary,
				Status: strings.ToUpper(
					strings.TrimSpace(status),
				),
				Source:     strings.TrimSpace(source),
				VerifiedAt: verifiedAt,
			},
		)
	}

	if err := rows.Err(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "KBLI_LOAD_FAILED",
				"message": "business KBLI activities could not be loaded",
			},
		})
		return
	}

	/*
		Backward compatibility:

		If business_kbli_activities has no rows but the legacy
		primary_kbli field exists, expose that legacy value.
	*/
	if len(kbli) == 0 &&
		primaryKBLI != nil {

		code := strings.TrimSpace(
			*primaryKBLI,
		)

		if code != "" {
			version := "2025"

			if kbliVersion != nil &&
				strings.TrimSpace(*kbliVersion) != "" {

				version = strings.TrimSpace(
					*kbliVersion,
				)
			}

			title := ""

			if kbliTitle != nil {
				title = strings.TrimSpace(
					*kbliTitle,
				)
			}

			status := strings.ToUpper(
				strings.TrimSpace(kbliStatus),
			)

			if status == "" {
				status = "ACTIVE"
			}

			kbli = append(
				kbli,
				KBLIActivityResponse{
					Code:       code,
					Version:    version,
					Title:      title,
					Primary:    true,
					Status:     status,
					Source:     "legacy",
					VerifiedAt: verifiedAt,
				},
			)
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":                  id,
			"business_id":         businessID,
			"tenant_id":           tenantID,
			"legal_form":          legalForm,
			"legalitas_type":      legalitasType,
			"legal_name":          legalName,
			"nib":                 nib,
			"nib_status":          nibStatus,
			"ahu_number":          ahuNumber,
			"ahu_status":          ahuStatus,
			"primary_kbli":        primaryKBLI,
			"kbli_version":        kbliVersion,
			"kbli_title":          kbliTitle,
			"kbli_status":         kbliStatus,
			"kbli":                kbli,
			"verification_status": verificationStatus,
			"verified_at":         verifiedAt,
			"notes":               notes,

			// Legalisation does not block marketplace selling.
			"can_sell": true,
		},
	})
}

type legalityRequest struct {
	TenantID           string `json:"tenant_id"`
	LegalForm          string `json:"legal_form"`
	LegalName          string `json:"legal_name"`
	NIB                string `json:"nib"`
	NIBStatus          string `json:"nib_status"`
	AHUNumber          string `json:"ahu_number"`
	AHUStatus          string `json:"ahu_status"`
	PrimaryKBLI        string `json:"primary_kbli"`
	KBLIversion        string `json:"kbli_version"`
	KBLITitle          string `json:"kbli_title"`
	KBLIStatus         string `json:"kbli_status"`
	VerificationStatus string `json:"verification_status"`
	Notes              string `json:"notes"`
}

func (h *Handler) upsertBusinessLegality(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	ctx := r.Context()

	authenticatedTenantID := strings.TrimSpace(
		tenantIDFromContext(ctx),
	)

	if authenticatedTenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	var req legalityRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_JSON",
				"message": "invalid JSON body",
			},
		})
		return
	}

	/*
		SECURITY:
		Never trust tenant_id from request body.

		The authenticated JWT tenant is authoritative.
	*/

	var businessTenantID string

	err := h.DB.QueryRow(
		ctx,
		`
		SELECT tenant_id
		FROM businesses
		WHERE id = $1
		`,
		businessID,
	).Scan(&businessTenantID)

	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "BUSINESS_NOT_FOUND",
				"message": "business not found",
			},
		})
		return
	}

	if businessTenantID != authenticatedTenantID {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "BUSINESS_NOT_FOUND",
				"message": "business not found",
			},
		})
		return
	}

	if req.NIBStatus == "" {
		req.NIBStatus = "user_provided"
	}

	if req.AHUStatus == "" {
		req.AHUStatus = "user_provided"
	}

	if req.KBLIStatus == "" {
		req.KBLIStatus = "user_provided"
	}

	if req.VerificationStatus == "" {
		req.VerificationStatus = "user_provided"
	}

	if req.KBLIversion == "" {
		req.KBLIversion = "2025"
	}

	/*
		SECURITY:
		req.TenantID is deliberately ignored.
	*/

	_, err = h.DB.Exec(
		ctx,
		`
		INSERT INTO business_legalities (
			business_id,
			tenant_id,
			legal_form,
			legal_name,
			nib,
			nib_status,
			ahu_number,
			ahu_status,
			primary_kbli,
			kbli_version,
			kbli_title,
			kbli_status,
			verification_status,
			notes,
			updated_at
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
			$11,
			$12,
			$13,
			$14,
			NOW()
		)
		ON CONFLICT (business_id)
		DO UPDATE SET
			legal_form = EXCLUDED.legal_form,
			legal_name = EXCLUDED.legal_name,
			nib = EXCLUDED.nib,
			nib_status = EXCLUDED.nib_status,
			ahu_number = EXCLUDED.ahu_number,
			ahu_status = EXCLUDED.ahu_status,
			primary_kbli = EXCLUDED.primary_kbli,
			kbli_version = EXCLUDED.kbli_version,
			kbli_title = EXCLUDED.kbli_title,
			kbli_status = EXCLUDED.kbli_status,
			verification_status = EXCLUDED.verification_status,
			notes = EXCLUDED.notes,
			updated_at = NOW()
		`,
		businessID,
		authenticatedTenantID,
		req.LegalForm,
		req.LegalName,
		req.NIB,
		req.NIBStatus,
		req.AHUNumber,
		req.AHUStatus,
		req.PrimaryKBLI,
		req.KBLIversion,
		req.KBLITitle,
		req.KBLIStatus,
		req.VerificationStatus,
		req.Notes,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "LEGALITY_SAVE_FAILED",
				"message": "business legality could not be saved",
			},
		})
		return
	}

	/*
		Keep the canonical KBLI activity table aligned with
		the legacy primary_kbli fields.

		No destructive delete is performed here.
		Existing non-primary activities remain intact.
	*/
	primaryKBLI := strings.TrimSpace(
		req.PrimaryKBLI,
	)

	if primaryKBLI != "" {
		_, err = h.DB.Exec(
			ctx,
			`
			UPDATE business_kbli_activities
			SET
				is_primary = FALSE,
				updated_at = NOW()
			WHERE business_id = $1
			  AND tenant_id = $2
			  AND kbli_code <> $3
			  AND is_primary = TRUE
			`,
			businessID,
			authenticatedTenantID,
			primaryKBLI,
		)

		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "KBLI_SYNC_FAILED",
					"message": "business primary KBLI could not be synchronized",
				},
			})
			return
		}

		var existingKBLIID string

		err = h.DB.QueryRow(
			ctx,
			`
			SELECT id
			FROM business_kbli_activities
			WHERE business_id = $1
			  AND tenant_id = $2
			  AND kbli_code = $3
			ORDER BY is_primary DESC, created_at ASC
			LIMIT 1
			`,
			businessID,
			authenticatedTenantID,
			primaryKBLI,
		).Scan(&existingKBLIID)

		if err != nil {
			_, insertErr := h.DB.Exec(
				ctx,
				`
				INSERT INTO business_kbli_activities (
					business_id,
					tenant_id,
					kbli_code,
					kbli_version,
					kbli_title,
					is_primary,
					status,
					source
				)
				VALUES (
					$1,
					$2,
					$3,
					$4,
					$5,
					TRUE,
					$6,
					$user_source
				)
				`,
				businessID,
				authenticatedTenantID,
				primaryKBLI,
				req.KBLIversion,
				req.KBLITitle,
				req.KBLIStatus,
			)

			/*
				The SQL above intentionally cannot use a named
				parameter with pgx positional arguments. The insert
				is retried below using the canonical positional form.
			*/
			if insertErr != nil {
				_, insertErr = h.DB.Exec(
					ctx,
					`
					INSERT INTO business_kbli_activities (
						business_id,
						tenant_id,
						kbli_code,
						kbli_version,
						kbli_title,
						is_primary,
						status,
						source
					)
					VALUES (
						$1,
						$2,
						$3,
						$4,
						$5,
						TRUE,
						$6,
						'user'
					)
					`,
					businessID,
					authenticatedTenantID,
					primaryKBLI,
					req.KBLIversion,
					req.KBLITitle,
					req.KBLIStatus,
				)

				if insertErr != nil {
					writeJSON(w, http.StatusInternalServerError, map[string]any{
						"success": false,
						"error": map[string]any{
							"code":    "KBLI_SYNC_FAILED",
							"message": "business primary KBLI could not be created",
						},
					})
					return
				}
			}
		} else {
			_, err = h.DB.Exec(
				ctx,
				`
				UPDATE business_kbli_activities
				SET
					kbli_version = $4,
					kbli_title = $5,
					is_primary = TRUE,
					status = $6,
					updated_at = NOW()
				WHERE id = $1
				  AND business_id = $2
				  AND tenant_id = $3
				`,
				existingKBLIID,
				businessID,
				authenticatedTenantID,
				req.KBLIversion,
				req.KBLITitle,
				req.KBLIStatus,
			)

			if err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{
					"success": false,
					"error": map[string]any{
						"code":    "KBLI_SYNC_FAILED",
						"message": "business primary KBLI could not be updated",
					},
				})
				return
			}
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"business_id":    businessID,
			"status":         "saved",
			"legalitas_type": normalizeLegalitasType(req.LegalForm),
			"can_sell":       true,
		},
	})
}

type setupRequestPayload struct {
	TenantID           string `json:"tenant_id"`
	BusinessID         string `json:"business_id"`
	Name               string `json:"name"`
	Phone              string `json:"phone"`
	Email              string `json:"email"`
	City               string `json:"city"`
	BusinessName       string `json:"business_name"`
	RequestedService   string `json:"requested_service"`
	BusinessType       string `json:"business_type"`
	RequestedLegalForm string `json:"requested_legal_form"`
	CurrentLegalStatus string `json:"current_legal_status"`
	CurrentNIB         string `json:"current_nib"`
	CurrentAHUNumber   string `json:"current_ahu_number"`
	CurrentKBLI        string `json:"current_kbli"`
	Notes              string `json:"notes"`
}

func (h *Handler) setupRequest(
	w http.ResponseWriter,
	r *http.Request,
) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()

	authenticatedTenantID := strings.TrimSpace(
		tenantIDFromContext(ctx),
	)

	if authenticatedTenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	var req setupRequestPayload

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_JSON",
				"message": "invalid JSON body",
			},
		})
		return
	}

	if strings.TrimSpace(req.Name) == "" ||
		strings.TrimSpace(req.RequestedService) == "" {

		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "VALIDATION_ERROR",
				"message": "name and requested_service are required",
			},
		})
		return
	}

	/*
		If a business_id is supplied,
		verify ownership before creating the request.
	*/

	businessID := strings.TrimSpace(
		req.BusinessID,
	)

	if businessID != "" {
		var businessTenantID string

		err := h.DB.QueryRow(
			ctx,
			`
			SELECT tenant_id
			FROM businesses
			WHERE id = $1
			`,
			businessID,
		).Scan(&businessTenantID)

		if err != nil {
			writeJSON(w, http.StatusNotFound, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "BUSINESS_NOT_FOUND",
					"message": "business not found",
				},
			})
			return
		}

		if businessTenantID != authenticatedTenantID {
			writeJSON(w, http.StatusNotFound, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "BUSINESS_NOT_FOUND",
					"message": "business not found",
				},
			})
			return
		}
	}

	if req.CurrentLegalStatus == "" {
		req.CurrentLegalStatus = "not_provided"
	}

	/*
		req.TenantID is ignored.
		Authenticated JWT tenant is authoritative.
	*/

	var id string

	err := h.DB.QueryRow(
		ctx,
		`
		INSERT INTO business_setup_requests (
			tenant_id,
			business_id,
			name,
			phone,
			email,
			city,
			business_name,
			requested_service,
			business_type,
			requested_legal_form,
			current_legal_status,
			current_nib,
			current_ahu_number,
			current_kbli,
			notes
		)
		VALUES (
			$1,
			NULLIF($2,'')::uuid,
			$3,
			$4,
			$5,
			$6,
			$7,
			$8,
			$9,
			$10,
			$11,
			$12,
			$13,
			$14,
			$15
		)
		RETURNING id
		`,
		authenticatedTenantID,
		businessID,
		req.Name,
		req.Phone,
		req.Email,
		req.City,
		req.BusinessName,
		req.RequestedService,
		req.BusinessType,
		req.RequestedLegalForm,
		req.CurrentLegalStatus,
		req.CurrentNIB,
		req.CurrentAHUNumber,
		req.CurrentKBLI,
		req.Notes,
	).Scan(&id)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "SETUP_REQUEST_FAILED",
				"message": "business setup request could not be created",
			},
		})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":      id,
			"status":  "new",
			"message": "Request received. Business operations remain active while the legal process continues.",
		},
	})
}

func (h *Handler) publicSetupRequest(
	w http.ResponseWriter,
	r *http.Request,
) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var req setupRequestPayload

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_JSON",
				"message": "invalid JSON body",
			},
		})
		return
	}

	if strings.TrimSpace(req.Name) == "" ||
		strings.TrimSpace(req.RequestedService) == "" {

		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "VALIDATION_ERROR",
				"message": "name and requested_service are required",
			},
		})
		return
	}

	if req.CurrentLegalStatus == "" {
		req.CurrentLegalStatus = "not_provided"
	}

	var id string

	err := h.DB.QueryRow(
		r.Context(),
		`
		INSERT INTO business_setup_requests (
			tenant_id,
			business_id,
			name,
			phone,
			email,
			city,
			business_name,
			requested_service,
			business_type,
			requested_legal_form,
			current_legal_status,
			current_nib,
			current_ahu_number,
			current_kbli,
			notes,
			source
		)
		VALUES (
			NULL,
			NULL,
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
			$11,
			$12,
			$13,
			'landing_page'
		)
		RETURNING id
		`,
		req.Name,
		req.Phone,
		req.Email,
		req.City,
		req.BusinessName,
		req.RequestedService,
		req.BusinessType,
		req.RequestedLegalForm,
		req.CurrentLegalStatus,
		req.CurrentNIB,
		req.CurrentAHUNumber,
		req.CurrentKBLI,
		req.Notes,
	).Scan(&id)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "SETUP_REQUEST_FAILED",
				"message": "business setup request could not be created",
			},
		})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data": map[string]any{
			"id":      id,
			"status":  "new",
			"message": "Legal onboarding request received.",
		},
	})
}

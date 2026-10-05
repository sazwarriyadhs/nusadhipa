package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

type RegistrationRequestCreate struct {
	RegistrationType string `json:"registration_type"`
	Notes            string `json:"notes,omitempty"`
}

type RegistrationRequestResponse struct {
	ID                 string     `json:"id"`
	TenantID           string     `json:"tenant_id"`
	BusinessID         string     `json:"business_id"`
	RegistrationType   string     `json:"registration_type"`
	Status             string     `json:"status"`
	RegistrationNumber string     `json:"registration_number,omitempty"`
	Source             string     `json:"source"`
	Notes              string     `json:"notes,omitempty"`
	SubmittedAt        *time.Time `json:"submitted_at,omitempty"`
	VerifiedAt         *time.Time `json:"verified_at,omitempty"`
	RejectedAt         *time.Time `json:"rejected_at,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

func (h *Handler) registrationRequests(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	switch r.Method {
	case http.MethodGet:
		h.listRegistrationRequests(w, r, businessID)

	case http.MethodPost:
		h.createRegistrationRequest(w, r, businessID)

	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func (h *Handler) createRegistrationRequest(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	ctx := r.Context()

	tenantID := strings.TrimSpace(tenantIDFromContext(ctx))

	if tenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	var input RegistrationRequestCreate

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_REQUEST",
				"message": "invalid JSON request body",
			},
		})
		return
	}

	input.RegistrationType = strings.ToUpper(
		strings.TrimSpace(input.RegistrationType),
	)

	if input.RegistrationType != "NIB" &&
		input.RegistrationType != "AHU" {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_REGISTRATION_TYPE",
				"message": "registration_type must be NIB or AHU",
			},
		})
		return
	}

	// Verify business ownership through the authenticated tenant.
	var exists bool

	err := h.DB.QueryRow(
		ctx,
		`
        SELECT EXISTS (
            SELECT 1
            FROM businesses
            WHERE id = $1
              AND tenant_id = $2
        )
        `,
		businessID,
		tenantID,
	).Scan(&exists)

	if err != nil || !exists {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "BUSINESS_NOT_FOUND",
				"message": "business not found",
			},
		})
		return
	}

	// Do not create a second active workflow for the same
	// business and registration type.
	var activeRequestID string

	err = h.DB.QueryRow(
		ctx,
		`
        SELECT id
        FROM business_registration_requests
        WHERE business_id = $1
          AND tenant_id = $2
          AND registration_type = $3
          AND status IN ('IN_PROGRESS', 'SUBMITTED')
        ORDER BY created_at DESC
        LIMIT 1
        `,
		businessID,
		tenantID,
		input.RegistrationType,
	).Scan(&activeRequestID)

	if err == nil {
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":       "REGISTRATION_ALREADY_IN_PROGRESS",
				"message":    "an active registration workflow already exists",
				"request_id": activeRequestID,
			},
		})
		return
	}

	var result RegistrationRequestResponse

	err = h.DB.QueryRow(
		ctx,
		`
        INSERT INTO business_registration_requests (
            tenant_id,
            business_id,
            registration_type,
            status,
            source,
            notes
        )
        VALUES ($1, $2, $3, 'IN_PROGRESS', 'nusa_dhipa', $4)
        RETURNING
            id,
            tenant_id,
            business_id,
            registration_type,
            status,
            COALESCE(registration_number, ''),
            source,
            COALESCE(notes, ''),
            submitted_at,
            verified_at,
            rejected_at,
            created_at,
            updated_at
        `,
		tenantID,
		businessID,
		input.RegistrationType,
		strings.TrimSpace(input.Notes),
	).Scan(
		&result.ID,
		&result.TenantID,
		&result.BusinessID,
		&result.RegistrationType,
		&result.Status,
		&result.RegistrationNumber,
		&result.Source,
		&result.Notes,
		&result.SubmittedAt,
		&result.VerifiedAt,
		&result.RejectedAt,
		&result.CreatedAt,
		&result.UpdatedAt,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_CREATE_FAILED",
				"message": err.Error(),
			},
		})
		return
	}

	// Synchronize high-level business legality status.
	if input.RegistrationType == "NIB" {
		_, _ = h.DB.Exec(
			ctx,
			`
            INSERT INTO business_legalities (
                business_id,
                tenant_id,
                nib_status
            )
            VALUES ($1, $2, 'in_progress')
            ON CONFLICT (business_id)
            DO UPDATE SET
                nib_status = 'in_progress',
                updated_at = NOW()
            `,
			businessID,
			tenantID,
		)
	} else {
		_, _ = h.DB.Exec(
			ctx,
			`
            INSERT INTO business_legalities (
                business_id,
                tenant_id,
                ahu_status
            )
            VALUES ($1, $2, 'in_progress')
            ON CONFLICT (business_id)
            DO UPDATE SET
                ahu_status = 'in_progress',
                updated_at = NOW()
            `,
			businessID,
			tenantID,
		)
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"success": true,
		"data":    result,
	})
}

func (h *Handler) listRegistrationRequests(
	w http.ResponseWriter,
	r *http.Request,
	businessID string,
) {
	ctx := r.Context()

	tenantID := strings.TrimSpace(tenantIDFromContext(ctx))

	if tenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	// Business ownership is enforced by the same tenant predicate.
	rows, err := h.DB.Query(
		ctx,
		`
        SELECT
            rr.id,
            rr.tenant_id,
            rr.business_id,
            rr.registration_type,
            rr.status,
            COALESCE(rr.registration_number, ''),
            rr.source,
            COALESCE(rr.notes, ''),
            rr.submitted_at,
            rr.verified_at,
            rr.rejected_at,
            rr.created_at,
            rr.updated_at
        FROM business_registration_requests rr
        WHERE rr.business_id = $1
          AND rr.tenant_id = $2
        ORDER BY rr.created_at DESC
        `,
		businessID,
		tenantID,
	)

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_LIST_FAILED",
				"message": err.Error(),
			},
		})
		return
	}
	defer rows.Close()

	results := make([]RegistrationRequestResponse, 0)

	for rows.Next() {
		var item RegistrationRequestResponse

		if err := rows.Scan(
			&item.ID,
			&item.TenantID,
			&item.BusinessID,
			&item.RegistrationType,
			&item.Status,
			&item.RegistrationNumber,
			&item.Source,
			&item.Notes,
			&item.SubmittedAt,
			&item.VerifiedAt,
			&item.RejectedAt,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{
				"success": false,
				"error": map[string]any{
					"code":    "REGISTRATION_SCAN_FAILED",
					"message": err.Error(),
				},
			})
			return
		}

		results = append(results, item)
	}

	if err := rows.Err(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_LIST_FAILED",
				"message": err.Error(),
			},
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    results,
	})
}

func (h *Handler) registrationRequestByID(
	w http.ResponseWriter,
	r *http.Request,
	requestID string,
) {
	ctx := r.Context()

	tenantID := strings.TrimSpace(tenantIDFromContext(ctx))

	if tenantID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "TENANT_CONTEXT_REQUIRED",
				"message": "authenticated tenant context is required",
			},
		})
		return
	}

	var item RegistrationRequestResponse

	err := h.DB.QueryRow(
		ctx,
		`
        SELECT
            id,
            tenant_id,
            business_id,
            registration_type,
            status,
            COALESCE(registration_number, ''),
            source,
            COALESCE(notes, ''),
            submitted_at,
            verified_at,
            rejected_at,
            created_at,
            updated_at
        FROM business_registration_requests
        WHERE id = $1
          AND tenant_id = $2
        `,
		requestID,
		tenantID,
	).Scan(
		&item.ID,
		&item.TenantID,
		&item.BusinessID,
		&item.RegistrationType,
		&item.Status,
		&item.RegistrationNumber,
		&item.Source,
		&item.Notes,
		&item.SubmittedAt,
		&item.VerifiedAt,
		&item.RejectedAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)

	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_REQUEST_NOT_FOUND",
				"message": "registration request not found",
			},
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    item,
	})
}

func (h *Handler) submitRegistrationRequest(
	w http.ResponseWriter,
	r *http.Request,
	requestID string,
) {
	ctx := r.Context()

	tenantID := strings.TrimSpace(tenantIDFromContext(ctx))

	if tenantID == "" {
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
		businessID       string
		registrationType string
		status           string
	)

	err := h.DB.QueryRow(
		ctx,
		`
        SELECT business_id, registration_type, status
        FROM business_registration_requests
        WHERE id = $1
          AND tenant_id = $2
        `,
		requestID,
		tenantID,
	).Scan(
		&businessID,
		&registrationType,
		&status,
	)

	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_REQUEST_NOT_FOUND",
				"message": "registration request not found",
			},
		})
		return
	}

	if status != "IN_PROGRESS" {
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "INVALID_REGISTRATION_TRANSITION",
				"message": "only IN_PROGRESS requests can be submitted",
				"status":  status,
			},
		})
		return
	}

	var result RegistrationRequestResponse

	err = h.DB.QueryRow(
		ctx,
		`
        UPDATE business_registration_requests
        SET
            status = 'SUBMITTED',
            submitted_at = NOW(),
            updated_at = NOW()
        WHERE id = $1
          AND tenant_id = $2
          AND status = 'IN_PROGRESS'
        RETURNING
            id,
            tenant_id,
            business_id,
            registration_type,
            status,
            COALESCE(registration_number, ''),
            source,
            COALESCE(notes, ''),
            submitted_at,
            verified_at,
            rejected_at,
            created_at,
            updated_at
        `,
		requestID,
		tenantID,
	).Scan(
		&result.ID,
		&result.TenantID,
		&result.BusinessID,
		&result.RegistrationType,
		&result.Status,
		&result.RegistrationNumber,
		&result.Source,
		&result.Notes,
		&result.SubmittedAt,
		&result.VerifiedAt,
		&result.RejectedAt,
		&result.CreatedAt,
		&result.UpdatedAt,
	)

	if err != nil {
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false,
			"error": map[string]any{
				"code":    "REGISTRATION_SUBMIT_FAILED",
				"message": "registration request could not be submitted",
			},
		})
		return
	}

	if registrationType == "NIB" {
		_, _ = h.DB.Exec(
			ctx,
			`
            UPDATE business_legalities
            SET
                nib_status = 'submitted',
                updated_at = NOW()
            WHERE business_id = $1
              AND tenant_id = $2
            `,
			businessID,
			tenantID,
		)
	} else {
		_, _ = h.DB.Exec(
			ctx,
			`
            UPDATE business_legalities
            SET
                ahu_status = 'submitted',
                updated_at = NOW()
            WHERE business_id = $1
              AND tenant_id = $2
            `,
			businessID,
			tenantID,
		)
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    result,
	})
}

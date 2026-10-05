package domain

import "time"

type BusinessLegality struct {
	ID                 string     `json:"id"`
	BusinessID         string     `json:"business_id"`
	TenantID           string     `json:"tenant_id"`
	LegalForm          string     `json:"legal_form,omitempty"`
	LegalName          string     `json:"legal_name,omitempty"`
	NIB                string     `json:"nib,omitempty"`
	NIBStatus          string     `json:"nib_status"`
	AHUNumber          string     `json:"ahu_number,omitempty"`
	AHUStatus          string     `json:"ahu_status"`
	PrimaryKBLI        string     `json:"primary_kbli,omitempty"`
	KBLIversion        string     `json:"kbli_version,omitempty"`
	KBLITitle          string     `json:"kbli_title,omitempty"`
	KBLIStatus         string     `json:"kbli_status"`
	VerificationStatus string     `json:"verification_status"`
	VerifiedAt         *time.Time `json:"verified_at,omitempty"`
	Notes              string     `json:"notes,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

type BusinessSetupRequest struct {
	ID                 string    `json:"id"`
	TenantID           *string   `json:"tenant_id,omitempty"`
	BusinessID         *string   `json:"business_id,omitempty"`
	Name               string    `json:"name"`
	Phone              string    `json:"phone,omitempty"`
	Email              string    `json:"email,omitempty"`
	City               string    `json:"city,omitempty"`
	BusinessName       string    `json:"business_name,omitempty"`
	RequestedService   string    `json:"requested_service"`
	BusinessType       string    `json:"business_type,omitempty"`
	RequestedLegalForm string    `json:"requested_legal_form,omitempty"`
	CurrentLegalStatus string    `json:"current_legal_status"`
	CurrentNIB         string    `json:"current_nib,omitempty"`
	CurrentAHUNumber   string    `json:"current_ahu_number,omitempty"`
	CurrentKBLI        string    `json:"current_kbli,omitempty"`
	Notes              string    `json:"notes,omitempty"`
	Status             string    `json:"status"`
	Source             string    `json:"source"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

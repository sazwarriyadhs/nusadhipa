package httpapi

import "strings"

type LegalRegistrationStatus string

const (
	StatusNotRegistered LegalRegistrationStatus = "NOT_REGISTERED"
	StatusInProgress    LegalRegistrationStatus = "IN_PROGRESS"
	StatusSubmitted     LegalRegistrationStatus = "SUBMITTED"
	StatusVerified      LegalRegistrationStatus = "VERIFIED"
	StatusRejected      LegalRegistrationStatus = "REJECTED"
	StatusExpired       LegalRegistrationStatus = "EXPIRED"
	StatusUnknown       LegalRegistrationStatus = "UNKNOWN"
)

type RegistrationAction string

const (
	ActionOfferRegistration RegistrationAction = "OFFER_REGISTRATION"
	ActionContinue          RegistrationAction = "CONTINUE"
	ActionView              RegistrationAction = "VIEW"
	ActionReview            RegistrationAction = "REVIEW"
	ActionNone              RegistrationAction = "NONE"
)

type RegistrationSummary struct {
	Status    LegalRegistrationStatus `json:"status"`
	Number    string                  `json:"number,omitempty"`
	Source    string                  `json:"source,omitempty"`
	Action    RegistrationAction      `json:"action"`
	Available bool                    `json:"available"`
}

// LegalitasType adalah klasifikasi legalitas canonical
// yang digunakan oleh API NUSA-DHIPA.
type LegalitasType string

const (
	LegalitasBelumAda            LegalitasType = "BELUM_ADA"
	LegalitasNIBOnly             LegalitasType = "NIB_ONLY"
	LegalitasPerseroanPerorangan LegalitasType = "PERSEROAN_PERORANGAN"
	LegalitasPT                  LegalitasType = "PT"
	LegalitasCV                  LegalitasType = "CV"
	LegalitasFirma               LegalitasType = "FIRMA"
	LegalitasPersekutuanPerdata  LegalitasType = "PERSEKUTUAN_PERDATA"
	LegalitasKoperasi            LegalitasType = "KOPERASI"
	LegalitasLainnya             LegalitasType = "LAINNYA"
)

type KBLIActivityResponse struct {
	Code       string `json:"code"`
	Version    string `json:"version"`
	Title      string `json:"title,omitempty"`
	Primary    bool   `json:"primary"`
	Status     string `json:"status"`
	Source     string `json:"source"`
	VerifiedAt any    `json:"verified_at,omitempty"`
}

type BusinessLegalStatusResponse struct {
	BusinessStatus string `json:"business_status"`
	CanOperate     bool   `json:"can_operate"`
	CanSell        bool   `json:"can_sell"`

	LegalitasType LegalitasType `json:"legalitas_type"`

	Legalization struct {
		NIB RegistrationSummary `json:"nib"`
		AHU RegistrationSummary `json:"ahu"`
	} `json:"legalization"`

	KBLI []KBLIActivityResponse `json:"kbli"`

	LegalizationRequired bool `json:"legalization_required"`
}

// normalizeLegalitasType mengubah berbagai bentuk legal_form
// lama menjadi canonical LegalitasType.
//
// Catatan:
// - BELUM_ADA = belum ada legalitas/form.
// - NIB_ONLY = NIB ada tetapi legal form belum diklasifikasikan.
// - PERSEROAN_PERORANGAN tetap dibedakan dari PT biasa.
func normalizeLegalitasType(value string) LegalitasType {
	value = strings.ToLower(strings.TrimSpace(value))

	switch value {
	case "":
		return LegalitasBelumAda

	case "nib_only",
		"nib-only",
		"nib only":
		return LegalitasNIBOnly

	case "pt_perorangan",
		"perseroan_perorangan",
		"perseroan perorangan",
		"perseorangan",
		"perseroan perseorangan":
		return LegalitasPerseroanPerorangan

	case "pt":
		return LegalitasPT

	case "cv":
		return LegalitasCV

	case "firma":
		return LegalitasFirma

	case "persekutuan_perdata",
		"persekutuan perdata":
		return LegalitasPersekutuanPerdata

	case "koperasi":
		return LegalitasKoperasi

	default:
		return LegalitasLainnya
	}
}

// legalitasAHUApplicable menentukan apakah AHU relevan
// berdasarkan tipe legalitas.
//
// BELUM_ADA dan NIB_ONLY tidak memaksa AHU.
// Bentuk badan/usaha berbadan atau terdaftar lainnya
// dapat memiliki data AHU.
func legalitasAHUApplicable(
	legalitasType LegalitasType,
) bool {
	switch legalitasType {
	case LegalitasBelumAda,
		LegalitasNIBOnly:
		return false

	default:
		return true
	}
}

func normalizeLegalStatus(value string) LegalRegistrationStatus {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "verified",
		"active",
		"registered",
		"approved":
		return StatusVerified

	case "in_progress",
		"processing",
		"pending":
		return StatusInProgress

	case "submitted":
		return StatusSubmitted

	case "rejected",
		"declined":
		return StatusRejected

	case "expired":
		return StatusExpired

	case "",
		"not_provided",
		"not_registered",
		"none":
		return StatusNotRegistered

	default:
		return StatusUnknown
	}
}

func registrationSummary(
	number string,
	rawStatus string,
	source string,
) RegistrationSummary {
	status := normalizeLegalStatus(rawStatus)

	result := RegistrationSummary{
		Status: status,
		Number: strings.TrimSpace(number),
		Source: source,
	}

	switch status {
	case StatusVerified:
		result.Available = true
		result.Action = ActionView

	case StatusInProgress,
		StatusSubmitted:
		result.Available = true
		result.Action = ActionContinue

	case StatusRejected:
		result.Available = true
		result.Action = ActionReview

	case StatusNotRegistered:
		result.Available = false
		result.Action = ActionOfferRegistration

	default:
		result.Available = false
		result.Action = ActionNone
	}

	return result
}

package domain

type ListingType string

const (
    ListingProduct     ListingType = "PRODUCT"
    ListingService     ListingType = "SERVICE"
    ListingSupplier    ListingType = "SUPPLIER"
    ListingReseller    ListingType = "RESELLER"
    ListingPartnership ListingType = "PARTNERSHIP"
)

type Listing struct {
    ID           string      `json:"id"`
    BusinessID   string      `json:"business_id"`
    Name         string      `json:"name"`
    Type         ListingType `json:"type"`
    Category     string      `json:"category"`
    Price        float64     `json:"price,omitempty"`
    Unit         string      `json:"unit,omitempty"`
    Stock        float64     `json:"stock,omitempty"`
    Active       bool        `json:"active"`
    FreshnessAt  string      `json:"freshness_at,omitempty"`
    Priority     bool        `json:"priority"`
}

package domain

type Intent string

const (
    IntentProduct       Intent = "PRODUCT"
    IntentService       Intent = "SERVICE"
    IntentSupplier      Intent = "SUPPLIER"
    IntentReseller      Intent = "RESELLER"
    IntentPartnership   Intent = "PARTNERSHIP"
    IntentOpportunity   Intent = "OPPORTUNITY"
    IntentPrice         Intent = "PRICE"
)

type SearchRequest struct {
    Query     string `json:"query"`
    Latitude  float64 `json:"latitude,omitempty"`
    Longitude float64 `json:"longitude,omitempty"`
    RegionID  string  `json:"region_id,omitempty"`
}

type SearchResult struct {
    ID             string  `json:"id"`
    Type           string  `json:"type"`
    Name           string  `json:"name"`
    RelevanceScore float64 `json:"relevance_score"`
    FreshnessScore float64 `json:"freshness_score"`
    TrustScore     float64 `json:"trust_score"`
    DistanceScore  float64 `json:"distance_score"`
    PriorityBoost  float64 `json:"priority_boost"`
}

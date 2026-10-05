package partnership

type OpportunityType string

const (
    Reseller    OpportunityType = "RESELLER"
    Agent       OpportunityType = "AGENT"
    Partnership OpportunityType = "PARTNERSHIP"
)

type Opportunity struct {
    ID              string         `json:"id"`
    BusinessID      string         `json:"business_id"`
    Title           string         `json:"title"`
    Type            OpportunityType `json:"type"`
    StartingCapital float64        `json:"starting_capital,omitempty"`
    Area            string         `json:"area,omitempty"`
    Description     string         `json:"description,omitempty"`
    Active          bool           `json:"active"`
}

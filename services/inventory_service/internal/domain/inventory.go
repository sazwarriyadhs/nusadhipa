package domain

import "time"

type InventoryBalance struct {
	ID                string    `json:"id"`
	TenantID          string    `json:"tenant_id"`
	BusinessID        string    `json:"business_id"`
	BranchID          string    `json:"branch_id"`
	ProductID         string    `json:"product_id"`
	SKU               string    `json:"sku"`
	ProductName       string    `json:"product_name"`
	Quantity          float64   `json:"quantity"`
	ReservedQuantity  float64   `json:"reserved_quantity"`
	AvailableQuantity float64   `json:"available_quantity"`
	Unit              string    `json:"unit"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type InventoryMovement struct {
	ID            string    `json:"id"`
	TenantID      string    `json:"tenant_id"`
	BusinessID    string    `json:"business_id"`
	BranchID      string    `json:"branch_id"`
	ProductID     string    `json:"product_id"`
	MovementType  string    `json:"movement_type"`
	Quantity      float64   `json:"quantity"`
	ReferenceType *string   `json:"reference_type,omitempty"`
	ReferenceID   *string   `json:"reference_id,omitempty"`
	Note          string    `json:"note"`
	CreatedBy     *string   `json:"created_by,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
}

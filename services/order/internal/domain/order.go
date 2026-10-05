package domain

import "time"

type DiningTable struct {
	ID         string    `json:"id"`
	TenantID   string    `json:"tenant_id"`
	BusinessID string    `json:"business_id"`
	BranchID   string    `json:"branch_id"`
	Code       string    `json:"code"`
	Name       string    `json:"name"`
	Capacity   int       `json:"capacity"`
	Status     string    `json:"status"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type Order struct {
	ID             string      `json:"id"`
	TenantID       string      `json:"tenant_id"`
	BusinessID     string      `json:"business_id"`
	BranchID       string      `json:"branch_id"`
	OrderNumber    string      `json:"order_number"`
	TableID        string      `json:"table_id"`
	CustomerName   string      `json:"customer_name,omitempty"`
	Status         string      `json:"status"`
	PaymentStatus  string      `json:"payment_status"`
	Subtotal       float64     `json:"subtotal"`
	DiscountAmount float64     `json:"discount_amount"`
	TaxAmount      float64     `json:"tax_amount"`
	ServiceCharge  float64     `json:"service_charge"`
	GrandTotal     float64     `json:"grand_total"`
	OpenedAt       time.Time   `json:"opened_at"`
	ClosedAt       *time.Time  `json:"closed_at,omitempty"`
	CreatedBy      *string     `json:"created_by,omitempty"`
	UpdatedBy      *string     `json:"updated_by,omitempty"`
	CreatedAt      time.Time   `json:"created_at"`
	UpdatedAt      time.Time   `json:"updated_at"`
	Items          []OrderItem `json:"items,omitempty"`
}

type OrderItem struct {
	ID             string    `json:"id"`
	TenantID       string    `json:"tenant_id"`
	BusinessID     string    `json:"business_id"`
	BranchID       string    `json:"branch_id"`
	OrderID        string    `json:"order_id"`
	ProductID      string    `json:"product_id"`
	ProductName    string    `json:"product_name"`
	ProductSKU     string    `json:"product_sku"`
	Quantity       float64   `json:"quantity"`
	Unit           string    `json:"unit"`
	UnitPrice      float64   `json:"unit_price"`
	DiscountAmount float64   `json:"discount_amount"`
	Subtotal       float64   `json:"subtotal"`
	Notes          string    `json:"notes"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

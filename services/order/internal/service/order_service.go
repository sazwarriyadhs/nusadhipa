package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/nusa-dhipa/business-os/services/order/internal/domain"
	"github.com/nusa-dhipa/business-os/services/order/internal/repository"
)

type Service struct {
	Repository *repository.Repository
}

func New(repo *repository.Repository) *Service {
	return &Service{Repository: repo}
}

func (s *Service) ListTables(
	ctx context.Context,
	tenantID, businessID, branchID string,
) ([]domain.DiningTable, error) {
	return s.Repository.ListTables(ctx, tenantID, businessID, branchID)
}

func (s *Service) CreateTable(
	ctx context.Context,
	tenantID, businessID, branchID, code, name string,
	capacity int,
) (*domain.DiningTable, error) {
	code = strings.TrimSpace(code)
	name = strings.TrimSpace(name)

	if code == "" || name == "" {
		return nil, fmt.Errorf("code and name are required")
	}

	return s.Repository.CreateTable(
		ctx,
		tenantID,
		businessID,
		branchID,
		code,
		name,
		capacity,
	)
}

func (s *Service) UpdateTableStatus(
	ctx context.Context,
	tenantID, businessID, branchID, tableID, status string,
) error {
	status = strings.ToLower(strings.TrimSpace(status))

	switch status {
	case "available", "occupied", "reserved", "inactive":
	default:
		return fmt.Errorf("invalid table status")
	}

	return s.Repository.UpdateTableStatus(
		ctx,
		tenantID,
		businessID,
		branchID,
		tableID,
		status,
	)
}

type CreateOrderInput struct {
	TenantID     string
	BusinessID   string
	BranchID     string
	TableID      string
	OrderNumber  string
	CustomerName string
	CreatedBy    string
}

func (s *Service) CreateOrder(
	ctx context.Context,
	input CreateOrderInput,
) (*domain.Order, error) {
	input.TableID = strings.TrimSpace(input.TableID)
	input.OrderNumber = strings.TrimSpace(input.OrderNumber)
	input.CustomerName = strings.TrimSpace(input.CustomerName)

	if input.TableID == "" {
		return nil, fmt.Errorf("table_id is required")
	}

	if input.OrderNumber == "" {
		input.OrderNumber = fmt.Sprintf(
			"ORD-%s-%s",
			time.Now().Format("20060102150405"),
			uuid.NewString()[:8],
		)
	}

	return s.Repository.CreateOrder(
		ctx,
		input.TenantID,
		input.BusinessID,
		input.BranchID,
		input.TableID,
		input.OrderNumber,
		input.CustomerName,
		input.CreatedBy,
	)
}

func (s *Service) ListOrders(
	ctx context.Context,
	tenantID, businessID, branchID, status string,
) ([]domain.Order, error) {
	return s.Repository.ListOrders(
		ctx,
		tenantID,
		businessID,
		branchID,
		strings.ToLower(strings.TrimSpace(status)),
	)
}

func (s *Service) GetOrder(
	ctx context.Context,
	tenantID, businessID, branchID, orderID string,
) (*domain.Order, error) {
	return s.Repository.GetOrder(
		ctx,
		tenantID,
		businessID,
		branchID,
		orderID,
	)
}

type AddItemInput struct {
	TenantID   string
	BusinessID string
	BranchID   string
	OrderID    string
	ProductID  string
	Quantity   float64
	Discount   float64
	Notes      string
}

func (s *Service) AddItem(
	ctx context.Context,
	input AddItemInput,
) (*domain.OrderItem, error) {
	input.ProductID = strings.TrimSpace(input.ProductID)
	input.Notes = strings.TrimSpace(input.Notes)

	if input.ProductID == "" {
		return nil, fmt.Errorf("product_id is required")
	}

	if input.Quantity <= 0 {
		return nil, fmt.Errorf("quantity must be greater than zero")
	}

	if input.Discount < 0 {
		return nil, fmt.Errorf("discount cannot be negative")
	}

	return s.Repository.AddItem(
		ctx,
		input.TenantID,
		input.BusinessID,
		input.BranchID,
		input.OrderID,
		input.ProductID,
		input.Quantity,
		input.Discount,
		input.Notes,
	)
}

type UpdateItemInput struct {
	TenantID   string
	BusinessID string
	BranchID   string
	OrderID    string
	ItemID     string
	Quantity   float64
	Discount   float64
	Notes      string
}

func (s *Service) UpdateItem(
	ctx context.Context,
	input UpdateItemInput,
) (*domain.OrderItem, error) {
	if input.Quantity <= 0 {
		return nil, fmt.Errorf("quantity must be greater than zero")
	}

	if input.Discount < 0 {
		return nil, fmt.Errorf("discount cannot be negative")
	}

	return s.Repository.UpdateItem(
		ctx,
		input.TenantID,
		input.BusinessID,
		input.BranchID,
		input.OrderID,
		input.ItemID,
		input.Quantity,
		input.Discount,
		strings.TrimSpace(input.Notes),
	)
}

func (s *Service) DeleteItem(
	ctx context.Context,
	tenantID, businessID, branchID, orderID, itemID string,
) error {
	return s.Repository.DeleteItem(
		ctx,
		tenantID,
		businessID,
		branchID,
		orderID,
		itemID,
	)
}

func (s *Service) Transition(
	ctx context.Context,
	tenantID, businessID, branchID,
	orderID, target, updatedBy string,
) error {
	target = strings.ToLower(strings.TrimSpace(target))

	switch target {
	case "confirmed", "cooking", "ready",
		"served", "completed", "cancelled":
	default:
		return fmt.Errorf("invalid target status")
	}

	return s.Repository.Transition(
		ctx,
		tenantID,
		businessID,
		branchID,
		orderID,
		target,
		updatedBy,
	)
}

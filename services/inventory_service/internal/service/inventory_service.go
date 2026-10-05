package service

import (
	"context"
	"strings"

	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/domain"
	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/repository"
)

type Service struct {
	Repository *repository.Repository
}

func New(repo *repository.Repository) *Service {
	return &Service{Repository: repo}
}

func (s *Service) ListBalances(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
) ([]domain.InventoryBalance, error) {
	return s.Repository.ListBalances(
		ctx,
		tenantID,
		businessID,
		branchID,
	)
}

func (s *Service) GetBalance(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
	productID string,
) (*domain.InventoryBalance, error) {
	return s.Repository.GetBalance(
		ctx,
		tenantID,
		businessID,
		branchID,
		productID,
	)
}

func (s *Service) ListMovements(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
	productID string,
) ([]domain.InventoryMovement, error) {
	return s.Repository.ListMovements(
		ctx,
		tenantID,
		businessID,
		branchID,
		productID,
	)
}

type CreateMovementInput struct {
	TenantID      string
	BusinessID    string
	BranchID      string
	ProductID     string
	MovementType  string
	Quantity      float64
	ReferenceType *string
	ReferenceID   *string
	Note          string
	CreatedBy     string
}

func (s *Service) CreateMovement(
	ctx context.Context,
	input CreateMovementInput,
) (*domain.InventoryMovement, *domain.InventoryBalance, error) {
	input.MovementType = strings.ToLower(strings.TrimSpace(input.MovementType))
	input.Note = strings.TrimSpace(input.Note)

	return s.Repository.CreateMovement(
		ctx,
		input.TenantID,
		input.BusinessID,
		input.BranchID,
		input.ProductID,
		input.MovementType,
		input.Quantity,
		input.ReferenceType,
		input.ReferenceID,
		input.Note,
		input.CreatedBy,
	)
}

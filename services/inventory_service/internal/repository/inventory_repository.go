package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/domain"
)

var (
	ErrNotFound        = errors.New("inventory not found")
	ErrInvalidContext  = errors.New("invalid tenant/business/branch context")
	ErrInsufficient    = errors.New("insufficient inventory")
	ErrInvalidMovement = errors.New("invalid movement type")
)

type Repository struct {
	DB *pgxpool.Pool
}

func New(db *pgxpool.Pool) *Repository {
	return &Repository{DB: db}
}

func (r *Repository) ListBalances(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
) ([]domain.InventoryBalance, error) {
	rows, err := r.DB.Query(
		ctx,
		`
        SELECT
            id,
            tenant_id,
            business_id,
            branch_id,
            product_id,
            sku,
            product_name,
            quantity,
            reserved_quantity,
            available_quantity,
            unit,
            created_at,
            updated_at
        FROM inventory_balance_view
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
        ORDER BY product_name, sku
        `,
		tenantID,
		businessID,
		branchID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.InventoryBalance, 0)

	for rows.Next() {
		var item domain.InventoryBalance

		if err := rows.Scan(
			&item.ID,
			&item.TenantID,
			&item.BusinessID,
			&item.BranchID,
			&item.ProductID,
			&item.SKU,
			&item.ProductName,
			&item.Quantity,
			&item.ReservedQuantity,
			&item.AvailableQuantity,
			&item.Unit,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *Repository) GetBalance(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
	productID string,
) (*domain.InventoryBalance, error) {
	var item domain.InventoryBalance

	err := r.DB.QueryRow(
		ctx,
		`
        SELECT
            id,
            tenant_id,
            business_id,
            branch_id,
            product_id,
            sku,
            product_name,
            quantity,
            reserved_quantity,
            available_quantity,
            unit,
            created_at,
            updated_at
        FROM inventory_balance_view
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
          AND product_id = $4
        `,
		tenantID,
		businessID,
		branchID,
		productID,
	).Scan(
		&item.ID,
		&item.TenantID,
		&item.BusinessID,
		&item.BranchID,
		&item.ProductID,
		&item.SKU,
		&item.ProductName,
		&item.Quantity,
		&item.ReservedQuantity,
		&item.AvailableQuantity,
		&item.Unit,
		&item.CreatedAt,
		&item.UpdatedAt,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	return &item, nil
}

func (r *Repository) ListMovements(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
	productID string,
) ([]domain.InventoryMovement, error) {
	query := `
        SELECT
            id,
            tenant_id,
            business_id,
            branch_id,
            product_id,
            movement_type,
            quantity,
            reference_type,
            reference_id,
            note,
            created_by,
            created_at
        FROM inventory_movements
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
    `

	args := []any{
		tenantID,
		businessID,
		branchID,
	}

	if productID != "" {
		query += ` AND product_id = $4`
		args = append(args, productID)
	}

	query += ` ORDER BY created_at DESC LIMIT 200`

	rows, err := r.DB.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]domain.InventoryMovement, 0)

	for rows.Next() {
		var item domain.InventoryMovement

		if err := rows.Scan(
			&item.ID,
			&item.TenantID,
			&item.BusinessID,
			&item.BranchID,
			&item.ProductID,
			&item.MovementType,
			&item.Quantity,
			&item.ReferenceType,
			&item.ReferenceID,
			&item.Note,
			&item.CreatedBy,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *Repository) CreateMovement(
	ctx context.Context,
	tenantID string,
	businessID string,
	branchID string,
	productID string,
	movementType string,
	quantity float64,
	referenceType *string,
	referenceID *string,
	note string,
	createdBy string,
) (*domain.InventoryMovement, *domain.InventoryBalance, error) {
	allowed := map[string]bool{
		"opening":         true,
		"purchase":        true,
		"sale":            true,
		"sale_return":     true,
		"purchase_return": true,
		"adjustment_in":   true,
		"adjustment_out":  true,
		"transfer_in":     true,
		"transfer_out":    true,
		"damage":          true,
		"expired":         true,
	}

	if !allowed[movementType] {
		return nil, nil, ErrInvalidMovement
	}

	if quantity <= 0 {
		return nil, nil, fmt.Errorf("quantity must be greater than zero")
	}

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback(ctx)

	// Validate tenant/business/branch/product relationship first.
	var valid bool

	err = tx.QueryRow(
		ctx,
		`
        SELECT EXISTS (
            SELECT 1
            FROM businesses b
            JOIN branches br
              ON br.business_id = b.id
             AND br.tenant_id = b.tenant_id
            JOIN catalog_products p
              ON p.business_id = b.id
             AND p.tenant_id = b.tenant_id
            WHERE b.id = $1
              AND b.tenant_id = $2
              AND br.id = $3
              AND p.id = $4
        )
        `,
		businessID,
		tenantID,
		branchID,
		productID,
	).Scan(&valid)

	if err != nil {
		return nil, nil, err
	}

	if !valid {
		return nil, nil, ErrInvalidContext
	}

	var (
		balanceID        uuid.UUID
		currentQuantity  float64
		reservedQuantity float64
		unit             string
		createdAt        any
		updatedAt        any
	)

	err = tx.QueryRow(
		ctx,
		`
        SELECT
            id,
            quantity,
            reserved_quantity,
            unit,
            created_at,
            updated_at
        FROM inventory_balances
        WHERE tenant_id = $1
          AND business_id = $2
          AND branch_id = $3
          AND product_id = $4
        FOR UPDATE
        `,
		tenantID,
		businessID,
		branchID,
		productID,
	).Scan(
		&balanceID,
		&currentQuantity,
		&reservedQuantity,
		&unit,
		&createdAt,
		&updatedAt,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil, ErrNotFound
	}

	if err != nil {
		return nil, nil, err
	}

	increases := map[string]bool{
		"opening":       true,
		"purchase":      true,
		"sale_return":   true,
		"adjustment_in": true,
		"transfer_in":   true,
	}

	decreases := map[string]bool{
		"sale":            true,
		"purchase_return": true,
		"adjustment_out":  true,
		"transfer_out":    true,
		"damage":          true,
		"expired":         true,
	}

	newQuantity := currentQuantity

	if increases[movementType] {
		newQuantity += quantity
	} else if decreases[movementType] {
		newQuantity -= quantity

		if newQuantity < 0 {
			return nil, nil, ErrInsufficient
		}
	} else {
		return nil, nil, ErrInvalidMovement
	}

	if newQuantity < reservedQuantity {
		return nil, nil, ErrInsufficient
	}

	_, err = tx.Exec(
		ctx,
		`
        UPDATE inventory_balances
        SET quantity = $1,
            updated_at = NOW()
        WHERE id = $2
        `,
		newQuantity,
		balanceID,
	)

	if err != nil {
		return nil, nil, err
	}

	movementID := uuid.New()

	_, err = tx.Exec(
		ctx,
		`
        INSERT INTO inventory_movements (
            id,
            tenant_id,
            business_id,
            branch_id,
            product_id,
            movement_type,
            quantity,
            reference_type,
            reference_id,
            note,
            created_by
        )
        VALUES (
            $1, $2, $3, $4, $5,
            $6, $7, $8, $9, $10, $11
        )
        `,
		movementID,
		tenantID,
		businessID,
		branchID,
		productID,
		movementType,
		quantity,
		referenceType,
		referenceID,
		note,
		createdBy,
	)

	if err != nil {
		return nil, nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, nil, err
	}

	movement := &domain.InventoryMovement{
		ID:            movementID.String(),
		TenantID:      tenantID,
		BusinessID:    businessID,
		BranchID:      branchID,
		ProductID:     productID,
		MovementType:  movementType,
		Quantity:      quantity,
		ReferenceType: referenceType,
		ReferenceID:   referenceID,
		Note:          note,
	}

	balance := &domain.InventoryBalance{
		ID:                balanceID.String(),
		TenantID:          tenantID,
		BusinessID:        businessID,
		BranchID:          branchID,
		ProductID:         productID,
		Quantity:          newQuantity,
		ReservedQuantity:  reservedQuantity,
		AvailableQuantity: newQuantity - reservedQuantity,
		Unit:              unit,
	}

	return movement, balance, nil
}

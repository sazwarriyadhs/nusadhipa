-- ============================================================
-- NUSA-DHIPA BUSINESS OS
-- Migration 005 - Inventory V1
--
-- Design:
-- tenant -> business -> branch -> inventory balance
-- inventory movements provide immutable stock audit trail
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- Inventory balances
-- One balance row per branch + product.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inventory_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    product_id UUID NOT NULL,

    quantity NUMERIC(18,3) NOT NULL DEFAULT 0,
    reserved_quantity NUMERIC(18,3) NOT NULL DEFAULT 0,

    unit VARCHAR(50) NOT NULL DEFAULT 'pcs',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT inventory_balances_quantity_nonnegative
        CHECK (quantity >= 0),

    CONSTRAINT inventory_balances_reserved_nonnegative
        CHECK (reserved_quantity >= 0),

    CONSTRAINT inventory_balances_reserved_not_exceed_quantity
        CHECK (reserved_quantity <= quantity),

    CONSTRAINT inventory_balances_branch_product_unique
        UNIQUE (branch_id, product_id),

    CONSTRAINT inventory_balances_tenant_fk
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_balances_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_balances_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_balances_product_fk
        FOREIGN KEY (product_id)
        REFERENCES catalog_products(id)
        ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Inventory movements
-- Immutable operational history.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    product_id UUID NOT NULL,

    movement_type VARCHAR(30) NOT NULL,

    quantity NUMERIC(18,3) NOT NULL,

    reference_type VARCHAR(50),
    reference_id UUID,

    note TEXT NOT NULL DEFAULT '',

    created_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT inventory_movements_quantity_positive
        CHECK (quantity > 0),

    CONSTRAINT inventory_movements_type_check
        CHECK (
            movement_type IN (
                'opening',
                'purchase',
                'sale',
                'sale_return',
                'purchase_return',
                'adjustment_in',
                'adjustment_out',
                'transfer_in',
                'transfer_out',
                'damage',
                'expired'
            )
        ),

    CONSTRAINT inventory_movements_tenant_fk
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_movements_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_movements_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_movements_product_fk
        FOREIGN KEY (product_id)
        REFERENCES catalog_products(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_movements_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_inventory_balances_tenant
    ON inventory_balances (tenant_id);

CREATE INDEX IF NOT EXISTS idx_inventory_balances_business
    ON inventory_balances (business_id);

CREATE INDEX IF NOT EXISTS idx_inventory_balances_branch
    ON inventory_balances (branch_id);

CREATE INDEX IF NOT EXISTS idx_inventory_balances_product
    ON inventory_balances (product_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_tenant
    ON inventory_movements (tenant_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_business
    ON inventory_movements (business_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch
    ON inventory_movements (branch_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_product
    ON inventory_movements (product_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_created_at
    ON inventory_movements (created_at DESC);

-- ------------------------------------------------------------
-- Available quantity helper
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW inventory_balance_view AS
SELECT
    ib.id,
    ib.tenant_id,
    ib.business_id,
    ib.branch_id,
    ib.product_id,
    p.sku,
    p.name AS product_name,
    ib.quantity,
    ib.reserved_quantity,
    (ib.quantity - ib.reserved_quantity) AS available_quantity,
    ib.unit,
    ib.created_at,
    ib.updated_at
FROM inventory_balances ib
JOIN catalog_products p
    ON p.id = ib.product_id;

COMMIT;

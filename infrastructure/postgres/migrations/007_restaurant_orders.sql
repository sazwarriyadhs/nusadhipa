BEGIN;

-- ============================================================
-- NUSA-DHIPA BUSINESS OS
-- Migration 007: Restaurant / Dine-in Orders
--
-- Scope:
--   - Dine-in
--   - Table management
--   - Waiter/Pelayan catalog ordering
--   - Kitchen workflow
--   - Cashier/payment lifecycle
--
-- Explicitly NOT included:
--   - Online ordering
--   - Delivery
--   - Pickup
--   - Marketplace ordering
--
-- Multi-tenant isolation:
--   tenant_id/business_id/branch_id are stored explicitly.
--   Cross-tenant/business validation is enforced by application
--   service/repository before mutations.
-- ============================================================


-- ============================================================
-- 1. DINING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS dining_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    capacity INTEGER NOT NULL DEFAULT 4,

    status VARCHAR(30) NOT NULL DEFAULT 'available',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT dining_tables_capacity_check
        CHECK (capacity > 0),

    CONSTRAINT dining_tables_status_check
        CHECK (
            status IN (
                'available',
                'occupied',
                'reserved',
                'inactive'
            )
        ),

    CONSTRAINT dining_tables_tenant_fk
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT dining_tables_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT dining_tables_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE,

    CONSTRAINT dining_tables_business_code_unique
        UNIQUE (business_id, code)
);

CREATE INDEX IF NOT EXISTS idx_dining_tables_tenant_business
    ON dining_tables (tenant_id, business_id);

CREATE INDEX IF NOT EXISTS idx_dining_tables_branch
    ON dining_tables (branch_id);

CREATE INDEX IF NOT EXISTS idx_dining_tables_status
    ON dining_tables (branch_id, status);


-- ============================================================
-- 2. RESTAURANT ORDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS restaurant_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,

    order_number VARCHAR(50) NOT NULL,

    table_id UUID NOT NULL,

    customer_name VARCHAR(150),

    status VARCHAR(30) NOT NULL DEFAULT 'open',

    payment_status VARCHAR(30) NOT NULL DEFAULT 'unpaid',

    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    service_charge NUMERIC(18,2) NOT NULL DEFAULT 0,
    grand_total NUMERIC(18,2) NOT NULL DEFAULT 0,

    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,

    created_by UUID,
    updated_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT restaurant_orders_tenant_fk
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_orders_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_orders_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_orders_table_fk
        FOREIGN KEY (table_id)
        REFERENCES dining_tables(id)
        ON DELETE RESTRICT,

    CONSTRAINT restaurant_orders_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL,

    CONSTRAINT restaurant_orders_updated_by_fk
        FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL,

    CONSTRAINT restaurant_orders_status_check
        CHECK (
            status IN (
                'open',
                'confirmed',
                'cooking',
                'ready',
                'served',
                'completed',
                'cancelled'
            )
        ),

    CONSTRAINT restaurant_orders_payment_status_check
        CHECK (
            payment_status IN (
                'unpaid',
                'partial',
                'paid',
                'refunded'
            )
        ),

    CONSTRAINT restaurant_orders_subtotal_check
        CHECK (subtotal >= 0),

    CONSTRAINT restaurant_orders_discount_check
        CHECK (discount_amount >= 0),

    CONSTRAINT restaurant_orders_tax_check
        CHECK (tax_amount >= 0),

    CONSTRAINT restaurant_orders_service_charge_check
        CHECK (service_charge >= 0),

    CONSTRAINT restaurant_orders_grand_total_check
        CHECK (grand_total >= 0),

    CONSTRAINT restaurant_orders_business_order_unique
        UNIQUE (business_id, order_number)
);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_tenant_business
    ON restaurant_orders (tenant_id, business_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_branch
    ON restaurant_orders (branch_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_table
    ON restaurant_orders (table_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_status
    ON restaurant_orders (branch_id, status);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_payment_status
    ON restaurant_orders (branch_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_opened_at
    ON restaurant_orders (branch_id, opened_at DESC);


-- ============================================================
-- 3. RESTAURANT ORDER ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS restaurant_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,

    order_id UUID NOT NULL,

    product_id UUID NOT NULL,

    -- Snapshot fields.
    -- Menu may change later, but historical order must remain intact.
    product_name VARCHAR(250) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,

    quantity NUMERIC(18,3) NOT NULL DEFAULT 1,

    unit VARCHAR(50) NOT NULL,

    unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,

    discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,

    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,

    notes TEXT NOT NULL DEFAULT '',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT restaurant_order_items_tenant_fk
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_order_items_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_order_items_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_order_items_order_fk
        FOREIGN KEY (order_id)
        REFERENCES restaurant_orders(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_order_items_product_fk
        FOREIGN KEY (product_id)
        REFERENCES catalog_products(id)
        ON DELETE RESTRICT,

    CONSTRAINT restaurant_order_items_quantity_check
        CHECK (quantity > 0),

    CONSTRAINT restaurant_order_items_price_check
        CHECK (unit_price >= 0),

    CONSTRAINT restaurant_order_items_discount_check
        CHECK (discount_amount >= 0),

    CONSTRAINT restaurant_order_items_subtotal_check
        CHECK (subtotal >= 0)
);

CREATE INDEX IF NOT EXISTS idx_restaurant_order_items_order
    ON restaurant_order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_order_items_product
    ON restaurant_order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_order_items_tenant_business
    ON restaurant_order_items (tenant_id, business_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_order_items_branch
    ON restaurant_order_items (branch_id);


-- ============================================================
-- 4. UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION set_restaurant_orders_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dining_tables_updated_at
    ON dining_tables;

CREATE TRIGGER trg_dining_tables_updated_at
BEFORE UPDATE ON dining_tables
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_orders_updated_at();


DROP TRIGGER IF EXISTS trg_restaurant_orders_updated_at
    ON restaurant_orders;

CREATE TRIGGER trg_restaurant_orders_updated_at
BEFORE UPDATE ON restaurant_orders
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_orders_updated_at();


DROP TRIGGER IF EXISTS trg_restaurant_order_items_updated_at
    ON restaurant_order_items;

CREATE TRIGGER trg_restaurant_order_items_updated_at
BEFORE UPDATE ON restaurant_order_items
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_orders_updated_at();


-- ============================================================
-- 5. DOCUMENTATION
-- ============================================================

COMMENT ON TABLE dining_tables IS
'RM/restaurant dine-in tables. Tenant/business/branch scoped.';

COMMENT ON TABLE restaurant_orders IS
'Dine-in restaurant orders. Supports waiter ordering, kitchen workflow and delayed/partial payment.';

COMMENT ON TABLE restaurant_order_items IS
'Restaurant order line items with historical product snapshots.';

COMMENT ON COLUMN restaurant_orders.customer_name IS
'Optional customer name for the current dine-in order.';

COMMENT ON COLUMN restaurant_orders.payment_status IS
'Payment lifecycle independent from food service lifecycle. Allows unpaid/partial orders before completion.';

COMMENT ON COLUMN restaurant_order_items.product_name IS
'Historical product name snapshot at order time.';

COMMENT ON COLUMN restaurant_order_items.unit_price IS
'Historical selling price snapshot at order time.';


COMMIT;

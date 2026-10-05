-- ============================================================
-- NUSA-DHIPA BUSINESS OS
-- Restaurant Order Foundation
--
-- Scope:
--   - Dining tables
--   - Dine-in orders
--   - Order items
--
-- Explicitly NOT included:
--   - Online ordering
--   - Delivery
--   - Pickup
--   - Marketplace order
--   - External order channel
-- ============================================================

BEGIN;

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

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

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

    CONSTRAINT dining_tables_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT dining_tables_branch_fk
        FOREIGN KEY (branch_id)
        REFERENCES branches(id)
        ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS
    ux_dining_tables_business_branch_code
ON dining_tables (
    business_id,
    branch_id,
    code
);

CREATE INDEX IF NOT EXISTS
    ix_dining_tables_tenant_business_branch
ON dining_tables (
    tenant_id,
    business_id,
    branch_id
);

CREATE INDEX IF NOT EXISTS
    ix_dining_tables_status
ON dining_tables (
    tenant_id,
    business_id,
    branch_id,
    status
);


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

    customer_name VARCHAR(150) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'open',

    payment_status VARCHAR(30) NOT NULL DEFAULT 'unpaid',

    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    service_charge NUMERIC(18,2) NOT NULL DEFAULT 0,
    grand_total NUMERIC(18,2) NOT NULL DEFAULT 0,

    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,

    created_by UUID,
    updated_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT restaurant_orders_customer_name_check
        CHECK (length(trim(customer_name)) > 0),

    CONSTRAINT restaurant_orders_amount_check
        CHECK (
            subtotal >= 0
            AND discount_amount >= 0
            AND tax_amount >= 0
            AND service_charge >= 0
            AND grand_total >= 0
        ),

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

    CONSTRAINT restaurant_orders_table_fk
        FOREIGN KEY (table_id)
        REFERENCES dining_tables(id)
        ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS
    ux_restaurant_orders_business_branch_order_number
ON restaurant_orders (
    business_id,
    branch_id,
    order_number
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_orders_tenant_business_branch
ON restaurant_orders (
    tenant_id,
    business_id,
    branch_id
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_orders_table
ON restaurant_orders (
    tenant_id,
    business_id,
    branch_id,
    table_id
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_orders_status
ON restaurant_orders (
    tenant_id,
    business_id,
    branch_id,
    status
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_orders_payment_status
ON restaurant_orders (
    tenant_id,
    business_id,
    branch_id,
    payment_status
);


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

    product_name VARCHAR(200) NOT NULL,
    product_sku VARCHAR(100),

    quantity NUMERIC(18,3) NOT NULL,
    unit VARCHAR(30) NOT NULL DEFAULT 'pcs',

    unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT restaurant_order_items_quantity_check
        CHECK (quantity > 0),

    CONSTRAINT restaurant_order_items_amount_check
        CHECK (
            unit_price >= 0
            AND discount_amount >= 0
            AND subtotal >= 0
        ),

    CONSTRAINT restaurant_order_items_order_fk
        FOREIGN KEY (order_id)
        REFERENCES restaurant_orders(id)
        ON DELETE CASCADE,

    CONSTRAINT restaurant_order_items_product_fk
        FOREIGN KEY (product_id)
        REFERENCES catalog_products(id)
        ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_order_items_order
ON restaurant_order_items (
    tenant_id,
    business_id,
    branch_id,
    order_id
);

CREATE INDEX IF NOT EXISTS
    ix_restaurant_order_items_product
ON restaurant_order_items (
    tenant_id,
    business_id,
    branch_id,
    product_id
);


-- ============================================================
-- 4. TRIGGER: UPDATED_AT
-- ============================================================

CREATE OR REPLACE FUNCTION set_restaurant_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_dining_tables_updated_at
ON dining_tables;

CREATE TRIGGER trg_dining_tables_updated_at
BEFORE UPDATE ON dining_tables
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_updated_at();


DROP TRIGGER IF EXISTS trg_restaurant_orders_updated_at
ON restaurant_orders;

CREATE TRIGGER trg_restaurant_orders_updated_at
BEFORE UPDATE ON restaurant_orders
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_updated_at();


DROP TRIGGER IF EXISTS trg_restaurant_order_items_updated_at
ON restaurant_order_items;

CREATE TRIGGER trg_restaurant_order_items_updated_at
BEFORE UPDATE ON restaurant_order_items
FOR EACH ROW
EXECUTE FUNCTION set_restaurant_updated_at();


-- ============================================================
-- 5. TENANT/BUSINESS/BRANCH CONSISTENCY
-- ============================================================

ALTER TABLE dining_tables
    DROP CONSTRAINT IF EXISTS dining_tables_tenant_business_branch_check;

ALTER TABLE restaurant_orders
    DROP CONSTRAINT IF EXISTS restaurant_orders_tenant_business_branch_check;

ALTER TABLE restaurant_order_items
    DROP CONSTRAINT IF EXISTS restaurant_order_items_tenant_business_branch_check;


-- ============================================================
-- 6. DOCUMENTATION COMMENTS
-- ============================================================

COMMENT ON TABLE dining_tables IS
    'Restaurant dine-in tables. Multi-tenant and branch scoped.';

COMMENT ON TABLE restaurant_orders IS
    'Internal restaurant dine-in orders. Not online ordering.';

COMMENT ON TABLE restaurant_order_items IS
    'Immutable product snapshot within a restaurant order.';

COMMENT ON COLUMN restaurant_orders.customer_name IS
    'Customer name entered by waiter/cashier for the dine-in order.';

COMMENT ON COLUMN restaurant_orders.table_id IS
    'Dining table associated with the active dine-in session.';

COMMENT ON COLUMN restaurant_order_items.product_name IS
    'Snapshot of catalog product name at the time the item is added.';

COMMENT ON COLUMN restaurant_order_items.unit_price IS
    'Snapshot of catalog selling price at the time the item is added.';


COMMIT;

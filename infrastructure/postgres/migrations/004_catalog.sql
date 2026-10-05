CREATE TABLE IF NOT EXISTS catalog_categories (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT catalog_categories_business_name_key
        UNIQUE (business_id, name)
);

CREATE INDEX IF NOT EXISTS idx_catalog_categories_tenant_business
    ON catalog_categories(tenant_id, business_id);

CREATE INDEX IF NOT EXISTS idx_catalog_categories_status
    ON catalog_categories(status);


CREATE TABLE IF NOT EXISTS catalog_products (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID NULL REFERENCES catalog_categories(id) ON DELETE SET NULL,

    sku VARCHAR(100) NOT NULL,
    name VARCHAR(250) NOT NULL,
    description TEXT NOT NULL DEFAULT '',

    product_type VARCHAR(50) NOT NULL DEFAULT 'product',
    unit VARCHAR(50) NOT NULL DEFAULT 'pcs',

    price NUMERIC(18,2) NOT NULL DEFAULT 0,
    cost_price NUMERIC(18,2) NOT NULL DEFAULT 0,

    track_inventory BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(30) NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT catalog_products_business_sku_key
        UNIQUE (business_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_catalog_products_tenant_business
    ON catalog_products(tenant_id, business_id);

CREATE INDEX IF NOT EXISTS idx_catalog_products_category
    ON catalog_products(category_id);

CREATE INDEX IF NOT EXISTS idx_catalog_products_status
    ON catalog_products(status);

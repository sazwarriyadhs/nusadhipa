-- ============================================================
-- NUSA DHIPA BUSINESS OS
-- Migration 003 - Legal Business Layer
-- ============================================================

CREATE TABLE IF NOT EXISTS business_legalities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    tenant_id UUID NOT NULL
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    legal_form VARCHAR(50),

    legal_name VARCHAR(255),

    nib VARCHAR(100),
    nib_status VARCHAR(50) NOT NULL DEFAULT 'not_provided',

    ahu_number VARCHAR(150),
    ahu_status VARCHAR(50) NOT NULL DEFAULT 'not_provided',

    primary_kbli VARCHAR(20),
    kbli_version VARCHAR(20) DEFAULT '2025',
    kbli_title VARCHAR(255),
    kbli_status VARCHAR(50) NOT NULL DEFAULT 'not_provided',

    verification_status VARCHAR(50) NOT NULL DEFAULT 'user_provided',

    verified_at TIMESTAMPTZ,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(business_id)
);

CREATE INDEX IF NOT EXISTS idx_business_legalities_tenant
    ON business_legalities(tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_legalities_nib
    ON business_legalities(nib);

CREATE INDEX IF NOT EXISTS idx_business_legalities_ahu
    ON business_legalities(ahu_number);

CREATE INDEX IF NOT EXISTS idx_business_legalities_kbli
    ON business_legalities(primary_kbli);

CREATE TABLE IF NOT EXISTS business_setup_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID
        REFERENCES tenants(id)
        ON DELETE SET NULL,

    business_id UUID
        REFERENCES businesses(id)
        ON DELETE SET NULL,

    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255),

    city VARCHAR(150),

    business_name VARCHAR(255),

    requested_service VARCHAR(100) NOT NULL,

    business_type VARCHAR(100),

    requested_legal_form VARCHAR(50),

    current_legal_status VARCHAR(50)
        NOT NULL DEFAULT 'not_provided',

    current_nib VARCHAR(100),
    current_ahu_number VARCHAR(150),
    current_kbli VARCHAR(20),

    notes TEXT,

    status VARCHAR(50) NOT NULL DEFAULT 'new',

    source VARCHAR(100) NOT NULL DEFAULT 'nusa_dhipa',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_setup_requests_tenant
    ON business_setup_requests(tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_setup_requests_business
    ON business_setup_requests(business_id);

CREATE INDEX IF NOT EXISTS idx_business_setup_requests_status
    ON business_setup_requests(status);

CREATE INDEX IF NOT EXISTS idx_business_setup_requests_service
    ON business_setup_requests(requested_service);

CREATE TABLE IF NOT EXISTS business_kbli_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    tenant_id UUID NOT NULL
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    kbli_code VARCHAR(20) NOT NULL,

    kbli_version VARCHAR(20) NOT NULL DEFAULT '2025',

    kbli_title VARCHAR(255),

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    status VARCHAR(50) NOT NULL DEFAULT 'active',

    source VARCHAR(50) NOT NULL DEFAULT 'user',

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_kbli_business
    ON business_kbli_activities(business_id);

CREATE INDEX IF NOT EXISTS idx_business_kbli_tenant
    ON business_kbli_activities(tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_kbli_code
    ON business_kbli_activities(kbli_code);

CREATE INDEX IF NOT EXISTS idx_business_kbli_primary
    ON business_kbli_activities(business_id, is_primary);

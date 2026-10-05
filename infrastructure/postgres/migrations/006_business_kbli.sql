CREATE TABLE IF NOT EXISTS business_kbli_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    business_id UUID NOT NULL
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    kbli_id UUID NOT NULL
        REFERENCES kbli_master(id),

    role VARCHAR(30) NOT NULL DEFAULT 'secondary',

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    notes TEXT NOT NULL DEFAULT '',

    status VARCHAR(30) NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT business_kbli_role_check
        CHECK (role IN ('primary', 'secondary')),

    CONSTRAINT business_kbli_status_check
        CHECK (status IN ('active', 'inactive')),

    CONSTRAINT business_kbli_unique_activity
        UNIQUE (business_id, kbli_id)
);

CREATE INDEX IF NOT EXISTS idx_business_kbli_business
    ON business_kbli_activities(business_id);

CREATE INDEX IF NOT EXISTS idx_business_kbli_tenant
    ON business_kbli_activities(tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_kbli_primary
    ON business_kbli_activities(business_id, is_primary);

CREATE UNIQUE INDEX IF NOT EXISTS business_kbli_one_primary
    ON business_kbli_activities(business_id)
    WHERE is_primary = TRUE
    AND status = 'active';

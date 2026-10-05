-- ============================================================
-- NUSA DHIPA BUSINESS OS
-- Migration 004 - Legal Registration Workflow
-- ============================================================

CREATE TABLE IF NOT EXISTS business_registration_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    business_id UUID NOT NULL
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    registration_type VARCHAR(20) NOT NULL,

    status VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS',

    registration_number VARCHAR(150),

    source VARCHAR(100) NOT NULL DEFAULT 'nusa_dhipa',

    notes TEXT,

    submitted_at TIMESTAMPTZ,

    verified_at TIMESTAMPTZ,

    rejected_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_registration_type
        CHECK (registration_type IN ('NIB', 'AHU')),

    CONSTRAINT chk_registration_status
        CHECK (
            status IN (
                'IN_PROGRESS',
                'SUBMITTED',
                'VERIFIED',
                'REJECTED',
                'EXPIRED'
            )
        )
);

CREATE INDEX IF NOT EXISTS idx_registration_requests_tenant
    ON business_registration_requests(tenant_id);

CREATE INDEX IF NOT EXISTS idx_registration_requests_business
    ON business_registration_requests(business_id);

CREATE INDEX IF NOT EXISTS idx_registration_requests_type
    ON business_registration_requests(registration_type);

CREATE INDEX IF NOT EXISTS idx_registration_requests_status
    ON business_registration_requests(status);

CREATE INDEX IF NOT EXISTS idx_registration_requests_business_type
    ON business_registration_requests(business_id, registration_type);

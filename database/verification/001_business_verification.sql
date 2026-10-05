CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- NUSA-DHIPA BUSINESS VERIFICATION
-- Tenant-aware verification layer
-- IMPORTANT: This file defines schema only.
-- Migration must be executed separately.
-- ============================================================

CREATE TABLE IF NOT EXISTS business_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,

    status VARCHAR(32) NOT NULL DEFAULT 'unverified',
    verification_level VARCHAR(32) NOT NULL DEFAULT 'basic',
    verified BOOLEAN NOT NULL DEFAULT FALSE,

    business_name VARCHAR(255) NOT NULL,

    -- Snapshot/reference fields used by the verification record.
    -- Canonical legal data remains in business_legalities.
    legal_form VARCHAR(64) NOT NULL DEFAULT 'none',
    legal_status VARCHAR(32) NOT NULL DEFAULT 'unregistered',

    kbli_code VARCHAR(16),
    kbli_name TEXT,

    nib VARCHAR(64),
    ahu_number VARCHAR(128),

    verification_source VARCHAR(32) NOT NULL DEFAULT 'manual',

    verification_code VARCHAR(32) NOT NULL UNIQUE,
    qr_token VARCHAR(128) NOT NULL UNIQUE,
    public_url TEXT NOT NULL,

    verified_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    verified_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_business_verifications_tenant_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_business_verifications_tenant_business
        UNIQUE (tenant_id, business_id),

    CONSTRAINT chk_business_verification_status
        CHECK (
            status IN (
                'unverified',
                'in_process',
                'verified',
                'suspended',
                'expired'
            )
        ),

    CONSTRAINT chk_business_verification_level
        CHECK (
            verification_level IN (
                'basic',
                'legal'
            )
        ),

    CONSTRAINT chk_business_verification_legal_status
        CHECK (
            legal_status IN (
                'unregistered',
                'in_process',
                'registered'
            )
        ),

    CONSTRAINT chk_business_verification_legal_form
        CHECK (
            legal_form IN (
                'none',
                'pt_perorangan',
                'cv',
                'pt',
                'koperasi',
                'other'
            )
        ),

    CONSTRAINT chk_verified_requires_verified_status
        CHECK (
            verified = FALSE
            OR status = 'verified'
        )
);

CREATE INDEX IF NOT EXISTS idx_business_verifications_tenant
    ON business_verifications(tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_verifications_business
    ON business_verifications(business_id);

CREATE INDEX IF NOT EXISTS idx_business_verifications_status
    ON business_verifications(status);

CREATE INDEX IF NOT EXISTS idx_business_verifications_verified
    ON business_verifications(verified);

CREATE INDEX IF NOT EXISTS idx_business_verifications_code
    ON business_verifications(verification_code);

-- ============================================================
-- Verification audit trail
-- ============================================================

CREATE TABLE IF NOT EXISTS verification_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    business_id UUID NOT NULL,
    verification_id UUID NOT NULL,

    action VARCHAR(32) NOT NULL,

    previous_status VARCHAR(32),
    new_status VARCHAR(32),

    reason TEXT,
    source VARCHAR(32),
    performed_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_verification_audits_verification
        FOREIGN KEY (verification_id)
        REFERENCES business_verifications(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_verification_audit_action
        CHECK (
            action IN (
                'submitted',
                'reviewed',
                'approved',
                'rejected',
                'suspended',
                'renewed'
            )
        )
);

CREATE INDEX IF NOT EXISTS idx_verification_audits_tenant
    ON verification_audits(tenant_id);

CREATE INDEX IF NOT EXISTS idx_verification_audits_business
    ON verification_audits(business_id);

CREATE INDEX IF NOT EXISTS idx_verification_audits_verification
    ON verification_audits(verification_id);

CREATE INDEX IF NOT EXISTS idx_verification_audits_created
    ON verification_audits(created_at);

-- ============================================================
-- Public verification view
--
-- IMPORTANT:
-- Only VERIFIED businesses are exposed.
-- Sensitive legal documents / full identifiers are not exposed.
-- Unverified businesses are NOT considered illegal.
-- ============================================================

CREATE OR REPLACE VIEW public_business_verifications AS
SELECT
    id,
    business_id,
    business_name,
    legal_form,
    legal_status,
    kbli_code,
    kbli_name,
    verification_level,
    status,
    verified,
    verification_code,
    public_url,
    verified_at,
    expires_at
FROM business_verifications
WHERE status = 'verified'
  AND verified = TRUE
  AND (
      expires_at IS NULL
      OR expires_at > NOW()
  );

COMMENT ON TABLE business_verifications IS
    'Tenant-aware NUSA-DHIPA business verification state. Legal source of truth remains business_legalities.';

COMMENT ON TABLE verification_audits IS
    'Audit trail for NUSA-DHIPA business verification lifecycle.';

COMMENT ON VIEW public_business_verifications IS
    'Safe public verification view. Only active verified businesses are exposed.';
ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS slug VARCHAR(200);

ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'active';

CREATE UNIQUE INDEX IF NOT EXISTS businesses_tenant_slug_key
    ON businesses(tenant_id, slug);

CREATE INDEX IF NOT EXISTS idx_businesses_status
    ON businesses(status);
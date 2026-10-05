CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS service_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,

    customer_name VARCHAR(160) NOT NULL,
    customer_whatsapp VARCHAR(40) NOT NULL,
    customer_email VARCHAR(255),

    brief TEXT NOT NULL,
    budget VARCHAR(64),
    deadline VARCHAR(128),
    notes TEXT,

    status VARCHAR(32) NOT NULL DEFAULT 'pending',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_quotes_business_id
    ON service_quotes(business_id);

CREATE INDEX IF NOT EXISTS idx_service_quotes_status
    ON service_quotes(status);

CREATE INDEX IF NOT EXISTS idx_service_quotes_created_at
    ON service_quotes(created_at DESC);
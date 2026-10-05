ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS activity TEXT;

ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS kbli_code VARCHAR(20);

ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS kbli_name VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_businesses_kbli_code
    ON businesses(kbli_code);

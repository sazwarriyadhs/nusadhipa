CREATE TABLE IF NOT EXISTS kbli_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    version VARCHAR(10) NOT NULL DEFAULT '2025',

    code VARCHAR(10) NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',

    level VARCHAR(30) NOT NULL,

    category_code VARCHAR(10),
    category_title TEXT,

    group_code VARCHAR(10),
    group_title TEXT,

    subgroup_code VARCHAR(10),
    subgroup_title TEXT,

    parent_code VARCHAR(10),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    source VARCHAR(50) NOT NULL DEFAULT 'BPS',
    source_reference TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT kbli_master_version_code_key
        UNIQUE (version, code)
);

CREATE INDEX IF NOT EXISTS idx_kbli_master_code
    ON kbli_master(code);

CREATE INDEX IF NOT EXISTS idx_kbli_master_title
    ON kbli_master
    USING GIN (to_tsvector('simple', title));

CREATE INDEX IF NOT EXISTS idx_kbli_master_description
    ON kbli_master
    USING GIN (to_tsvector('simple', description));

CREATE INDEX IF NOT EXISTS idx_kbli_master_category
    ON kbli_master(category_code);

CREATE INDEX IF NOT EXISTS idx_kbli_master_level
    ON kbli_master(level);

CREATE INDEX IF NOT EXISTS idx_kbli_master_active
    ON kbli_master(is_active);

COMMENT ON TABLE kbli_master IS
'Master KBLI Indonesia. Source utama BPS KBLI 2025.';

COMMENT ON COLUMN kbli_master.version IS
'KBLI version, currently 2025.';

COMMENT ON COLUMN kbli_master.source IS
'Official source authority, normally BPS.';

COMMENT ON COLUMN kbli_master.source_reference IS
'Reference URL/document identifier for auditability.';

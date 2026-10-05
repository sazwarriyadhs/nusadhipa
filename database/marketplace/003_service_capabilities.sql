CREATE TABLE IF NOT EXISTS service_capabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kbli_code VARCHAR(16) NOT NULL,
    capability VARCHAR(32) NOT NULL,
    label VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (kbli_code, capability)
);

CREATE INDEX IF NOT EXISTS idx_service_capabilities_kbli
    ON service_capabilities(kbli_code);

INSERT INTO service_capabilities
    (kbli_code, capability, label, description, sort_order)
VALUES
    (
        '62090',
        'quotation',
        'Minta Penawaran',
        'Kirim kebutuhan dan minta penawaran layanan.',
        1
    ),
    (
        '62090',
        'consultation',
        'Konsultasi',
        'Kirim kebutuhan untuk konsultasi awal.',
        2
    ),
    (
        '62090',
        'contact',
        'Hubungi Usaha',
        'Hubungi penyedia jasa secara langsung.',
        3
    )
ON CONFLICT (kbli_code, capability)
DO UPDATE SET
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    sort_order = EXCLUDED.sort_order,
    active = EXCLUDED.active;

CREATE TABLE IF NOT EXISTS kbli_service_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kbli_code VARCHAR(16) NOT NULL UNIQUE,
    service_type VARCHAR(32) NOT NULL DEFAULT 'general',
    display_label VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO kbli_service_rules
    (kbli_code, service_type, display_label)
VALUES
    (
        '62090',
        'professional_service',
        'Layanan Teknologi Informasi & Jasa Komputer'
    )
ON CONFLICT (kbli_code)
DO UPDATE SET
    service_type = EXCLUDED.service_type,
    display_label = EXCLUDED.display_label,
    updated_at = NOW();
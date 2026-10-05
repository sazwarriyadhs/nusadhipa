BEGIN;

DO $$
DECLARE
    v_tenant_id uuid;
    v_business_id uuid;
    v_verification_code varchar(32);
    v_qr_token varchar(128);
BEGIN

    SELECT tenant_id
    INTO v_tenant_id
    FROM businesses
    WHERE name = 'Raja Telur'
    LIMIT 1;

    IF v_tenant_id IS NULL THEN
        RAISE EXCEPTION 'Tenant Raja Telur tidak ditemukan';
    END IF;

    SELECT id
    INTO v_business_id
    FROM businesses
    WHERE name = 'PT DIGI MEDIA KOMUNIKA'
    LIMIT 1;

    IF v_business_id IS NULL THEN

        INSERT INTO businesses (
            id,
            tenant_id,
            name,
            business_type,
            phone,
            email,
            address,
            created_at,
            updated_at,
            slug,
            status,
            activity,
            kbli_code,
            kbli_name,
            short_name,
            tagline,
            description,
            whatsapp,
            website,
            logo_url,
            cover_image_url,
            brand_color
        )
        VALUES (
            gen_random_uuid(),
            v_tenant_id,
            'PT DIGI MEDIA KOMUNIKA',
            'service',
            NULL,
            NULL,
            'Cimahpar Stoneyard No. E1, Jl. Guru Muchtar, Cimahpar, Bogor Utara, Kota Bogor, Jawa Barat 16155',
            now(),
            now(),
            'pt-digi-media-komunika',
            'active',
            'Aktivitas Teknologi Informasi dan Jasa Komputer Lainnya',
            '62090',
            'Aktivitas Teknologi Informasi dan Jasa Komputer Lainnya',
            'PT DIGI MEDIA KOMUNIKA',
            'Technology & Computer Services',
            'Penyedia jasa teknologi informasi dan jasa komputer lainnya.',
            NULL,
            NULL,
            '/digi/logo.png',
            NULL,
            '#2563EB'
        )
        RETURNING id INTO v_business_id;

    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM business_legalities
        WHERE business_id = v_business_id
    ) THEN

        INSERT INTO business_legalities (
            id,
            business_id,
            tenant_id,
            legal_form,
            legal_name,
            nib,
            nib_status,
            ahu_number,
            ahu_status,
            primary_kbli,
            kbli_version,
            kbli_title,
            kbli_status,
            verification_status,
            verified_at,
            notes,
            created_at,
            updated_at
        )
        VALUES (
            gen_random_uuid(),
            v_business_id,
            v_tenant_id,
            'pt_perorangan',
            'PT DIGI MEDIA KOMUNIKA',
            '2203230003021',
            'active',
            'AHU-022246.AH.01.30.Tahun 2023',
            'active',
            '62090',
            'KBLI 2025',
            'Aktivitas Teknologi Informasi dan Jasa Komputer Lainnya',
            'active',
            'verified',
            now(),
            'Perseroan Perorangan. PMDN. Skala Usaha Mikro. Tingkat risiko KBLI rendah. NIB terbit 22 Maret 2023. Berkedudukan di Kota Bogor.',
            now(),
            now()
        );

    END IF;

    SELECT verification_code
    INTO v_verification_code
    FROM business_verifications
    WHERE business_id = v_business_id
    LIMIT 1;

    IF v_verification_code IS NULL THEN

        v_verification_code :=
            'NDH-' ||
            upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

        v_qr_token :=
            'NDHQ-' ||
            replace(gen_random_uuid()::text, '-', '');

        INSERT INTO business_verifications (
            id,
            tenant_id,
            business_id,
            status,
            verification_level,
            verified,
            business_name,
            legal_form,
            legal_status,
            kbli_code,
            kbli_name,
            nib,
            ahu_number,
            verification_source,
            verification_code,
            qr_token,
            public_url,
            verified_at,
            expires_at,
            verified_by,
            created_at,
            updated_at
        )
        VALUES (
            gen_random_uuid(),
            v_tenant_id,
            v_business_id,
            'verified',
            'legal',
            true,
            'PT DIGI MEDIA KOMUNIKA',
            'pt_perorangan',
            'registered',
            '62090',
            'Aktivitas Teknologi Informasi dan Jasa Komputer Lainnya',
            '2203230003021',
            'AHU-022246.AH.01.30.Tahun 2023',
            'manual',
            v_verification_code,
            v_qr_token,
            'http://localhost:3010/verify/' || v_verification_code,
            now(),
            NULL,
            NULL,
            now(),
            now()
        );

    ELSE

        UPDATE business_verifications
        SET
            status = 'verified',
            verification_level = 'legal',
            verified = true,
            business_name = 'PT DIGI MEDIA KOMUNIKA',
            legal_form = 'pt_perorangan',
            legal_status = 'registered',
            kbli_code = '62090',
            kbli_name = 'Aktivitas Teknologi Informasi dan Jasa Komputer Lainnya',
            nib = '2203230003021',
            ahu_number = 'AHU-022246.AH.01.30.Tahun 2023',
            verification_source = 'manual',
            verified_at = now(),
            updated_at = now()
        WHERE business_id = v_business_id;

    END IF;

END $$;

COMMIT;
package httpapi

import (
	"context"
	"strings"
)

type marketplaceCapability struct {
	Capability      string  `json:"capability"`
	Label           string  `json:"label"`
	Description     *string `json:"description,omitempty"`
	SortOrder       int     `json:"sort_order"`
	Source          string  `json:"source,omitempty"`
	TransactionType string  `json:"transaction_type"`
}

type marketplaceBusinessContext struct {
	BusinessType        string                  `json:"business_type"`
	BusinessMode        string                  `json:"business_mode"`
	MarketplaceTemplate string                  `json:"marketplace_template"`
	KbliCode            string                  `json:"kbli_code,omitempty"`
	ProductCount        int                     `json:"product_count"`
	ServiceCount        int                     `json:"service_count"`
	Capabilities        []marketplaceCapability `json:"capabilities"`
	BusinessProfile     businessProfile         `json:"business_profile"`
	MobileModules       []string                `json:"mobile_modules"`
}

func normalizeMarketplaceBusinessMode(
	businessType string,
	productCount int,
	serviceCount int,
) string {
	raw := strings.ToLower(strings.TrimSpace(businessType))

	switch raw {
	case "hybrid",
		"mixed",
		"product+service",
		"product + service",
		"produk+jasa",
		"produk + jasa":
		return "hybrid"
	}

	switch raw {
	case "food",
		"f&b",
		"fnb",
		"restaurant",
		"restoran",
		"kuliner":

		if productCount > 0 && serviceCount > 0 {
			return "hybrid"
		}

		return "food"

	case "workshop",
		"bengkel":
		return "workshop"

	case "course",
		"kursus",
		"education",
		"pendidikan":
		return "course"

	case "travel",
		"tour",
		"wisata",
		"pariwisata":
		return "travel"

	case "ticketing",
		"event",
		"tiket":
		return "ticketing"
	}

	// ------------------------------------------------------------
	// Catalog aktual menjadi sumber utama jika business_type
	// belum secara eksplisit menentukan mode.
	// ------------------------------------------------------------

	if productCount > 0 && serviceCount > 0 {
		return "hybrid"
	}

	if serviceCount > 0 {
		return "service"
	}

	if productCount > 0 {
		return "product"
	}

	// ------------------------------------------------------------
	// Fallback ke business_type lama ketika katalog masih kosong.
	// ------------------------------------------------------------

	switch raw {
	case "service",
		"services",
		"jasa":
		return "service"

	case "retail",
		"product",
		"products",
		"produk",
		"barang",
		"wholesale",
		"supplier",
		"reseller":
		return "product"

	case "general",
		"":
		return "general"
	}

	return "general"
}

// normalizeMarketplaceTemplate menentukan template UI/UX Marketplace.
// Template bukan transaksi. Template menentukan bentuk pengalaman,
// sedangkan capabilities menentukan action yang benar-benar tersedia.
func normalizeMarketplaceTemplate(
	businessType string,
	businessMode string,
) string {
	raw := strings.ToLower(strings.TrimSpace(businessType))

	switch raw {
	case "food",
		"f&b",
		"fnb",
		"restaurant",
		"restoran",
		"kuliner":
		return "restaurant"

	case "workshop",
		"bengkel":
		return "workshop"

	case "course",
		"kursus",
		"education",
		"pendidikan":
		return "course"

	case "travel",
		"tour",
		"wisata",
		"pariwisata":
		return "travel"

	case "ticketing",
		"event",
		"tiket":
		return "ticketing"
	}

	switch businessMode {
	case "product":
		return "product"

	case "service":
		return "service"

	case "hybrid":
		return "hybrid"

	case "food":
		return "restaurant"

	case "workshop":
		return "workshop"

	case "course":
		return "course"

	case "travel":
		return "travel"

	case "ticketing":
		return "ticketing"
	}

	return "general"
}

// marketplaceTransactionType memberikan makna transaksi untuk capability.
// Frontend tidak perlu menebak action hanya dari business_mode.
func marketplaceTransactionType(capability string) string {
	switch strings.ToLower(strings.TrimSpace(capability)) {
	case "products",
		"services",
		"menu",
		"spareparts",
		"ticketing":
		return "browse"

	case "orders",
		"online_order",
		"table_order",
		"dine_in":
		return "order"

	case "additional_order":
		return "order_addition"

	case "reservation":
		return "reservation"

	case "booking",
		"service_booking":
		return "booking"

	case "quotation":
		return "quotation"

	case "consultation":
		return "consultation"

	case "contact":
		return "contact"

	case "registration":
		return "registration"

	default:
		return "custom"
	}
}

func (h *Handler) resolveMarketplaceBusinessContext(
	ctx context.Context,
	businessID string,
	businessType string,
	kbliCode string,
) (marketplaceBusinessContext, error) {
	var (
		productCount int
		serviceCount int
	)

	err := h.DB.QueryRow(
		ctx,
		`
        SELECT
            COUNT(*) FILTER (
                WHERE LOWER(COALESCE(product_type, 'product'))
                    NOT IN ('service', 'jasa')
            ),
            COUNT(*) FILTER (
                WHERE LOWER(COALESCE(product_type, ''))
                    IN ('service', 'jasa')
            )
        FROM catalog_products
        WHERE business_id = $1
          AND status = 'active'
        `,
		businessID,
	).Scan(
		&productCount,
		&serviceCount,
	)

	if err != nil {
		return marketplaceBusinessContext{}, err
	}

	mode := normalizeMarketplaceBusinessMode(
		businessType,
		productCount,
		serviceCount,
	)

	template := normalizeMarketplaceTemplate(
		businessType,
		mode,
	)

	capabilities := make([]marketplaceCapability, 0, 20)

	// ------------------------------------------------------------
	// Capability registration
	// ------------------------------------------------------------

	seen := map[string]bool{}

	addCapability := func(
		name string,
		label string,
		description *string,
		sortOrder int,
		source string,
	) {
		name = strings.ToLower(strings.TrimSpace(name))

		if name == "" {
			return
		}

		if seen[name] {
			return
		}

		seen[name] = true

		capabilities = append(
			capabilities,
			marketplaceCapability{
				Capability:      name,
				Label:           label,
				Description:     description,
				SortOrder:       sortOrder,
				Source:          source,
				TransactionType: marketplaceTransactionType(name),
			},
		)
	}

	// ------------------------------------------------------------
	// Actual catalog capabilities
	// ------------------------------------------------------------

	if productCount > 0 ||
		mode == "product" ||
		mode == "food" ||
		mode == "workshop" {

		addCapability(
			"products",
			"Produk",
			nil,
			10,
			"catalog",
		)
	}

	if serviceCount > 0 ||
		mode == "service" ||
		mode == "hybrid" ||
		mode == "workshop" {

		addCapability(
			"services",
			"Layanan",
			nil,
			20,
			"catalog",
		)
	}

	// ------------------------------------------------------------
	// Default capabilities by marketplace template
	// ------------------------------------------------------------

	switch template {

	// ============================================================
	// PRODUCT
	// ============================================================

	case "product":

		addCapability(
			"online_order",
			"Pesan Sekarang",
			nil,
			30,
			"default",
		)

	// ============================================================
	// SERVICE
	// ============================================================

	case "service":

		addCapability(
			"quotation",
			"Minta Penawaran",
			nil,
			30,
			"default",
		)

		addCapability(
			"consultation",
			"Konsultasi",
			nil,
			40,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			50,
			"default",
		)

	// ============================================================
	// HYBRID
	//
	// Produk + Jasa.
	//
	// Tidak otomatis mengaktifkan reservation/booking.
	// Capability tambahan datang dari konfigurasi/KBLI.
	// ============================================================

	case "hybrid":

		if productCount > 0 {
			addCapability(
				"online_order",
				"Pesan Sekarang",
				nil,
				30,
				"default",
			)
		}

		if serviceCount > 0 {
			addCapability(
				"quotation",
				"Minta Penawaran",
				nil,
				40,
				"default",
			)

			addCapability(
				"consultation",
				"Konsultasi",
				nil,
				50,
				"default",
			)
		}

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			60,
			"default",
		)

	// ============================================================
	// RESTAURANT / FOOD
	//
	// Ini template khusus RM / restoran / kuliner.
	//
	// Customer flow:
	// Menu
	// -> Online Order
	// -> Dine In
	// -> Table Order
	// -> Additional Order
	// -> Reservation
	//
	// Payment tidak ditangani capability ini.
	// Payment lifecycle berada di Order/Payment domain.
	// ============================================================

	case "restaurant":

		addCapability(
			"menu",
			"Menu",
			nil,
			30,
			"default",
		)

		addCapability(
			"online_order",
			"Pesan Sekarang",
			nil,
			40,
			"default",
		)

		addCapability(
			"dine_in",
			"Makan di Tempat",
			nil,
			50,
			"default",
		)

		addCapability(
			"table_order",
			"Pesan dari Meja",
			nil,
			60,
			"default",
		)

		addCapability(
			"additional_order",
			"Tambah Menu",
			nil,
			70,
			"default",
		)

		addCapability(
			"reservation",
			"Reservasi",
			nil,
			80,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			90,
			"default",
		)

	// ============================================================
	// WORKSHOP
	// ============================================================

	case "workshop":

		addCapability(
			"spareparts",
			"Sparepart",
			nil,
			30,
			"default",
		)

		addCapability(
			"service_booking",
			"Booking Service",
			nil,
			40,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			50,
			"default",
		)

	// ============================================================
	// COURSE / EDUCATION
	// ============================================================

	case "course":

		addCapability(
			"booking",
			"Daftar / Booking",
			nil,
			30,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			40,
			"default",
		)

	// ============================================================
	// TRAVEL
	// ============================================================

	case "travel":

		addCapability(
			"booking",
			"Booking",
			nil,
			30,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			40,
			"default",
		)

	// ============================================================
	// TICKETING
	// ============================================================

	case "ticketing":

		addCapability(
			"ticketing",
			"Tiket",
			nil,
			30,
			"default",
		)

		addCapability(
			"contact",
			"Hubungi Usaha",
			nil,
			40,
			"default",
		)

	// ============================================================
	// GENERAL
	// ============================================================

	default:

		if productCount > 0 {
			addCapability(
				"online_order",
				"Pesan",
				nil,
				30,
				"default",
			)
		}

		if serviceCount > 0 {
			addCapability(
				"quotation",
				"Minta Penawaran",
				nil,
				40,
				"default",
			)

			addCapability(
				"contact",
				"Hubungi Usaha",
				nil,
				50,
				"default",
			)
		}
	}

	// ------------------------------------------------------------
	// KBLI-specific capabilities
	//
	// KBLI menambahkan capability domain-specific.
	// Tidak menghapus default capability yang sudah ada.
	// ------------------------------------------------------------

	if strings.TrimSpace(kbliCode) != "" {
		rows, err := h.DB.Query(
			ctx,
			`
            SELECT
                capability,
                label,
                description,
                sort_order
            FROM service_capabilities
            WHERE kbli_code = $1
              AND active = TRUE
            ORDER BY sort_order, capability
            `,
			strings.TrimSpace(kbliCode),
		)

		if err != nil {
			return marketplaceBusinessContext{}, err
		}

		defer rows.Close()

		for rows.Next() {
			var (
				capability  string
				label       string
				description *string
				sortOrder   int
			)

			if err := rows.Scan(
				&capability,
				&label,
				&description,
				&sortOrder,
			); err != nil {
				return marketplaceBusinessContext{}, err
			}

			addCapability(
				capability,
				label,
				description,
				100+sortOrder,
				"kbli",
			)
		}

		if err := rows.Err(); err != nil {
			return marketplaceBusinessContext{}, err
		}
	}

	sortMarketplaceCapabilities(capabilities)

	businessProfile, err := resolveBusinessProfile(
		ctx,
		h.DB,
		mode,
		template,
		kbliCode,
		capabilities,
	)
	if err != nil {
		return marketplaceBusinessContext{}, err
	}

	return marketplaceBusinessContext{
		BusinessType:        businessType,
		BusinessMode:        mode,
		MarketplaceTemplate: template,
		KbliCode:            kbliCode,
		ProductCount:        productCount,
		ServiceCount:        serviceCount,
		Capabilities:        capabilities,
		BusinessProfile:     businessProfile,
		MobileModules:       businessProfile.MobileModules,
	}, nil
}

func sortMarketplaceCapabilities(
	items []marketplaceCapability,
) {
	for i := 1; i < len(items); i++ {
		current := items[i]
		j := i - 1

		for j >= 0 &&
			(items[j].SortOrder > current.SortOrder ||
				(items[j].SortOrder == current.SortOrder &&
					items[j].Capability > current.Capability)) {

			items[j+1] = items[j]
			j--
		}

		items[j+1] = current
	}
}

func (h *Handler) marketplaceCapabilities(
	ctx context.Context,
	businessID string,
	businessType string,
	kbliCode string,
) (marketplaceBusinessContext, error) {
	return h.resolveMarketplaceBusinessContext(
		ctx,
		businessID,
		businessType,
		kbliCode,
	)
}

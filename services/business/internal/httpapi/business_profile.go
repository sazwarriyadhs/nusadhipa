package httpapi

import (
	"context"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type businessProfile struct {
	Profile       string   `json:"profile"`
	ServiceType   string   `json:"service_type,omitempty"`
	DisplayLabel  string   `json:"display_label,omitempty"`
	MobileModules []string `json:"mobile_modules"`
}

func resolveBusinessProfile(
	ctx context.Context,
	db *pgxpool.Pool,
	businessMode string,
	marketplaceTemplate string,
	kbliCode string,
	capabilities []marketplaceCapability,
) (businessProfile, error) {
	profileName := normalizeBusinessProfile(
		businessMode,
		marketplaceTemplate,
		capabilities,
	)

	profile := businessProfile{
		Profile: profileName,
	}

	if strings.TrimSpace(kbliCode) != "" {
		var (
			serviceType  string
			displayLabel *string
		)

		err := db.QueryRow(
			ctx,
			`
            SELECT service_type, display_label
            FROM kbli_service_rules
            WHERE kbli_code = $1
            LIMIT 1
            `,
			strings.TrimSpace(kbliCode),
		).Scan(&serviceType, &displayLabel)

		if err != nil && err != pgx.ErrNoRows {
			return businessProfile{}, err
		}

		if err == nil {
			profile.ServiceType = serviceType

			if displayLabel != nil {
				profile.DisplayLabel = *displayLabel
			}
		}
	}

	profile.MobileModules = resolveMobileModules(
		profile.Profile,
		businessMode,
		capabilities,
	)

	return profile, nil
}

func normalizeBusinessProfile(
	businessMode string,
	marketplaceTemplate string,
	capabilities []marketplaceCapability,
) string {
	template := strings.ToLower(strings.TrimSpace(marketplaceTemplate))
	mode := strings.ToLower(strings.TrimSpace(businessMode))

	switch template {
	case "restaurant":
		return "restaurant"
	case "workshop":
		return "workshop"
	case "course":
		return "course"
	case "travel":
		return "travel"
	case "ticketing":
		return "ticketing"
	case "product":
		return "product"
	case "service":
		return "service"
	case "hybrid":
		return "hybrid"
	}

	switch mode {
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
	case "product":
		return "product"
	case "service":
		return "service"
	case "hybrid":
		return "hybrid"
	}

	hasProduct := false
	hasService := false

	for _, capability := range capabilities {
		switch strings.ToLower(strings.TrimSpace(capability.Capability)) {
		case "products", "online_order", "menu":
			hasProduct = true

		case "services", "quotation", "consultation", "service_booking":
			hasService = true
		}
	}

	if hasProduct && hasService {
		return "hybrid"
	}

	if hasService {
		return "service"
	}

	if hasProduct {
		return "product"
	}

	return "general"
}

func resolveMobileModules(
	profile string,
	businessMode string,
	capabilities []marketplaceCapability,
) []string {
	seen := make(map[string]bool)
	modules := make([]string, 0, 8)

	add := func(module string) {
		module = strings.TrimSpace(module)

		if module == "" || seen[module] {
			return
		}

		seen[module] = true
		modules = append(modules, module)
	}

	switch profile {
	case "restaurant":
		add("catalog")
		add("order")
		add("table_order")
		add("reservation")

	case "workshop":
		add("service_catalog")
		add("booking")
		add("customer")

	case "course":
		add("service_catalog")
		add("booking")
		add("customer")

	case "travel":
		add("service_catalog")
		add("booking")
		add("customer")

	case "ticketing":
		add("catalog")
		add("ticketing")
		add("customer")

	case "product":
		add("catalog")
		add("order")
		add("customer")

	case "service":
		add("business")
		add("service_catalog")
		add("customer")

	case "hybrid":
		add("business")
		add("catalog")
		add("service_catalog")
		add("customer")

	default:
		switch strings.ToLower(strings.TrimSpace(businessMode)) {
		case "product":
			add("catalog")
			add("order")

		case "service":
			add("business")
			add("service_catalog")
			add("customer")

		default:
			add("business")
		}
	}

	for _, capability := range capabilities {
		switch strings.ToLower(strings.TrimSpace(capability.Capability)) {
		case "quotation":
			add("quotation")

		case "consultation":
			add("consultation")

		case "contact":
			add("customer")

		case "reservation":
			add("reservation")

		case "booking", "service_booking":
			add("booking")

		case "ticketing":
			add("ticketing")

		case "dine_in", "table_order":
			add("table_order")

		case "additional_order":
			add("order_addition")
		}
	}

	return modules
}

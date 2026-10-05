package kbli

import (
	"fmt"
	"strings"
)

func (r *Repository) ValidateHierarchy() error {
	// Build the set of category roots represented by category_code.
	//
	// KBLI 2025 stores category roots such as "A", "B", "C", etc.
	// in category_code rather than as standalone records where
	// Record.Code == category_code.
	categories := make(map[string]struct{})

	for _, record := range r.records {
		category := strings.TrimSpace(strings.ToUpper(record.CategoryCode))

		if category != "" {
			categories[category] = struct{}{}
		}
	}

	for _, record := range r.records {
		parent := strings.TrimSpace(strings.ToUpper(record.ParentCode))

		if parent == "" {
			continue
		}

		// Normal hierarchy:
		//
		// 0111 -> 011
		// 011  -> 01
		// 01   -> A
		//
		// All non-root parents are represented by Record.Code.
		if _, ok := r.byCode[parent]; ok {
			continue
		}

		// Category roots such as A/B/C/... are represented through
		// category_code and do not have standalone records.
		if _, ok := categories[parent]; ok {
			continue
		}

		return fmt.Errorf(
			"orphan KBLI record %s: parent %s not found",
			record.Code,
			record.ParentCode,
		)
	}

	return nil
}

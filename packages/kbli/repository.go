package kbli

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strings"
)

type Repository struct {
	byCode     map[string]Record
	children   map[string][]Record
	records    []Record
	activities []Record
}

func NewRepository(csvPath string) (*Repository, error) {
	f, err := os.Open(csvPath)
	if err != nil {
		return nil, fmt.Errorf("open KBLI CSV: %w", err)
	}
	defer f.Close()

	reader := csv.NewReader(f)
	reader.FieldsPerRecord = -1
	reader.LazyQuotes = false

	header, err := reader.Read()
	if err != nil {
		return nil, fmt.Errorf("read KBLI header: %w", err)
	}

	index := make(map[string]int, len(header))
	for i, name := range header {
		index[strings.TrimSpace(strings.ToLower(strings.TrimPrefix(name, "\uFEFF")))] = i
	}

	required := []string{
		"version",
		"code",
		"title",
		"description",
		"level",
		"category_code",
		"category_title",
		"group_code",
		"group_title",
		"subgroup_code",
		"subgroup_title",
		"parent_code",
		"source",
		"source_reference",
	}

	for _, field := range required {
		if _, ok := index[field]; !ok {
			return nil, fmt.Errorf("missing required KBLI column %q", field)
		}
	}

	repo := &Repository{
		byCode:   make(map[string]Record),
		children: make(map[string][]Record),
	}

	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("read KBLI record: %w", err)
		}

		get := func(name string) string {
			i := index[name]
			if i >= len(row) {
				return ""
			}
			return strings.TrimSpace(row[i])
		}

		record := Record{
			Version:         get("version"),
			Code:            get("code"),
			Title:           get("title"),
			Description:     get("description"),
			Level:           get("level"),
			CategoryCode:    get("category_code"),
			CategoryTitle:   get("category_title"),
			GroupCode:       get("group_code"),
			GroupTitle:      get("group_title"),
			SubgroupCode:    get("subgroup_code"),
			SubgroupTitle:   get("subgroup_title"),
			ParentCode:      get("parent_code"),
			Source:          get("source"),
			SourceReference: get("source_reference"),
		}

		if record.Code == "" {
			return nil, fmt.Errorf("KBLI record has empty code")
		}

		if record.Title == "" {
			return nil, fmt.Errorf("KBLI %s has empty title", record.Code)
		}

		if !record.Canonical() {
			return nil, fmt.Errorf(
				"KBLI %s is not canonical: version=%q source=%q",
				record.Code,
				record.Version,
				record.Source,
			)
		}

		if _, exists := repo.byCode[record.Code]; exists {
			return nil, fmt.Errorf("duplicate KBLI code %s", record.Code)
		}

		repo.byCode[record.Code] = record
		repo.records = append(repo.records, record)

		if record.Level == "activity" {
			repo.activities = append(repo.activities, record)
		}

		if record.ParentCode != "" {
			repo.children[record.ParentCode] =
				append(repo.children[record.ParentCode], record)
		}
	}

	if len(repo.records) == 0 {
		return nil, fmt.Errorf("KBLI CSV contains no records")
	}

	return repo, nil
}

func (r *Repository) Count() int {
	return len(r.records)
}

func (r *Repository) ActivityCount() int {
	return len(r.activities)
}

func (r *Repository) Get(code string) (Record, bool) {
	record, ok := r.byCode[strings.TrimSpace(strings.ToUpper(code))]
	return record, ok
}

func (r *Repository) Validate(code string) (Record, bool) {
	record, ok := r.Get(code)
	if !ok {
		return Record{}, false
	}

	return record, record.Canonical()
}

func (r *Repository) Children(code string) []Record {
	items := r.children[strings.TrimSpace(strings.ToUpper(code))]

	result := make([]Record, len(items))
	copy(result, items)

	return result
}

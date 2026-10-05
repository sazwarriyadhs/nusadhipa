package kbli

import "strings"

const (
    CanonicalVersion = "2025"
    CanonicalSource  = "BPS"
)

type Record struct {
    Version        string `json:"version"`
    Code           string `json:"code"`
    Title          string `json:"title"`
    Description    string `json:"description"`
    Level          string `json:"level"`
    CategoryCode   string `json:"category_code"`
    CategoryTitle  string `json:"category_title"`
    GroupCode      string `json:"group_code"`
    GroupTitle     string `json:"group_title"`
    SubgroupCode   string `json:"subgroup_code"`
    SubgroupTitle  string `json:"subgroup_title"`
    ParentCode     string `json:"parent_code"`
    Source         string `json:"source"`
    SourceReference string `json:"source_reference"`
}

func (r Record) Canonical() bool {
    return strings.TrimSpace(r.Version) == CanonicalVersion &&
        strings.EqualFold(strings.TrimSpace(r.Source), CanonicalSource)
}

type SearchResult struct {
    Record
    Score float64 `json:"score"`
}

type ClassificationCandidate struct {
    Code           string  `json:"code"`
    Title          string  `json:"title"`
    Level          string  `json:"level"`
    Score          float64 `json:"score"`
    Canonical      bool    `json:"canonical"`
    Validated      bool    `json:"validated"`
    Version        string  `json:"version"`
    Source         string  `json:"source"`
    Reason         string  `json:"reason,omitempty"`
}

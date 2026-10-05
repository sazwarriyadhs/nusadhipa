package kbli

import "fmt"

type Metadata struct {
    Dataset          string `json:"dataset"`
    Version          string `json:"version"`
    Source           string `json:"source"`
    Canonical        bool   `json:"canonical"`
    Records          int    `json:"records"`
    Activities       int    `json:"activities"`
    Validated        bool   `json:"validated"`
    ValidationStatus string `json:"validation_status"`
}

func (r *Repository) ValidateCanonical() error {
    if r.Count() != 2423 {
        return fmt.Errorf("unexpected KBLI record count: %d", r.Count())
    }

    if r.ActivityCount() != 1559 {
        return fmt.Errorf("unexpected KBLI activity count: %d", r.ActivityCount())
    }

    return r.ValidateHierarchy()
}

func (r *Repository) Metadata() Metadata {
    return Metadata{
        Dataset:          "KBLI",
        Version:          CanonicalVersion,
        Source:           CanonicalSource,
        Canonical:        true,
        Records:          r.Count(),
        Activities:       r.ActivityCount(),
        Validated:        true,
        ValidationStatus: "PASS",
    }
}

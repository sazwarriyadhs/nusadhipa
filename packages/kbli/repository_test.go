package kbli

import (
    "os"
    "path/filepath"
    "testing"
)

func testCSVPath(t *testing.T) string {
    t.Helper()

    root, err := filepath.Abs(filepath.Join("..", ".."))
    if err != nil {
        t.Fatal(err)
    }

    path := filepath.Join(root, "data", "kbli", "kbli_2025.csv")

    if _, err := os.Stat(path); err != nil {
        t.Fatalf("KBLI CSV not found: %s: %v", path, err)
    }

    return path
}

func TestLoadCanonical(t *testing.T) {
    repo, err := NewRepository(testCSVPath(t))
    if err != nil {
        t.Fatalf("load failed: %v", err)
    }

    if repo.Count() != 2423 {
        t.Fatalf("expected 2423 records, got %d", repo.Count())
    }

    if repo.ActivityCount() != 1559 {
        t.Fatalf("expected 1559 activities, got %d", repo.ActivityCount())
    }

    if err := repo.ValidateCanonical(); err != nil {
        t.Fatalf("canonical validation failed: %v", err)
    }
}

func TestExactLookup(t *testing.T) {
    repo, err := NewRepository(testCSVPath(t))
    if err != nil {
        t.Fatal(err)
    }

    record, ok := repo.Get("01111")
    if !ok {
        t.Fatal("01111 not found")
    }

    if record.Title != "PERTANIAN JAGUNG" {
        t.Fatalf("unexpected title: %s", record.Title)
    }

    if record.Version != "2025" {
        t.Fatalf("unexpected version: %s", record.Version)
    }

    if record.Source != "BPS" {
        t.Fatalf("unexpected source: %s", record.Source)
    }
}

func TestSearch(t *testing.T) {
    repo, err := NewRepository(testCSVPath(t))
    if err != nil {
        t.Fatal(err)
    }

    results := repo.Search("jagung", 10)

    if len(results) == 0 {
        t.Fatal("expected search results")
    }

    found := false

    for _, result := range results {
        if result.Code == "01111" {
            found = true
            break
        }
    }

    if !found {
        t.Fatal("expected 01111 in search results")
    }
}

func TestCanonicalValidation(t *testing.T) {
    repo, err := NewRepository(testCSVPath(t))
    if err != nil {
        t.Fatal(err)
    }

    record, valid := repo.Validate("01111")

    if !valid {
        t.Fatal("expected 01111 to be canonical")
    }

    if !record.Canonical() {
        t.Fatal("record should be canonical")
    }

    _, valid = repo.Validate("99999")

    if valid {
        t.Fatal("unknown code must not validate")
    }
}

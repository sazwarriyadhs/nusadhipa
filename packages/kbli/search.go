package kbli

import (
    "sort"
    "strings"
)

func normalize(value string) string {
    value = strings.ToLower(value)
    value = strings.ReplaceAll(value, "-", " ")
    value = strings.ReplaceAll(value, "/", " ")
    value = strings.ReplaceAll(value, ",", " ")
    value = strings.ReplaceAll(value, ".", " ")

    return strings.Join(strings.Fields(value), " ")
}

func tokenize(value string) []string {
    value = normalize(value)

    if value == "" {
        return nil
    }

    return strings.Fields(value)
}

func scoreRecord(query string, record Record) float64 {
    query = normalize(query)
    if query == "" {
        return 0
    }

    title := normalize(record.Title)
    description := normalize(record.Description)

    if title == query {
        return 1.0
    }

    if strings.Contains(title, query) {
        return 0.95
    }

    queryTokens := tokenize(query)
    if len(queryTokens) == 0 {
        return 0
    }

    var matched float64

    for _, token := range queryTokens {
        if strings.Contains(title, token) {
            matched += 2
            continue
        }

        if strings.Contains(description, token) {
            matched += 1
        }
    }

    score := matched / float64(len(queryTokens)*2)

    if score > 1 {
        score = 1
    }

    return score
}

func (r *Repository) Search(query string, limit int) []SearchResult {
    if limit <= 0 {
        limit = 20
    }

    var results []SearchResult

    for _, record := range r.activities {
        score := scoreRecord(query, record)

        if score <= 0 {
            continue
        }

        results = append(results, SearchResult{
            Record: record,
            Score:  score,
        })
    }

    sort.SliceStable(results, func(i, j int) bool {
        if results[i].Score == results[j].Score {
            return results[i].Code < results[j].Code
        }

        return results[i].Score > results[j].Score
    })

    if len(results) > limit {
        results = results[:limit]
    }

    return results
}

func (r *Repository) Classify(description string, limit int) []ClassificationCandidate {
    if limit <= 0 {
        limit = 5
    }

    results := r.Search(description, limit)

    candidates := make([]ClassificationCandidate, 0, len(results))

    for _, result := range results {
        record, valid := r.Validate(result.Code)

        if !valid {
            continue
        }

        candidates = append(candidates, ClassificationCandidate{
            Code:      record.Code,
            Title:     record.Title,
            Level:     record.Level,
            Score:     result.Score,
            Canonical: true,
            Validated: true,
            Version:   record.Version,
            Source:    record.Source,
            Reason:    "matched against canonical KBLI 2025 title and description",
        })
    }

    return candidates
}

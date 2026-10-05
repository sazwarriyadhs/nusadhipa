package ranking

type Factors struct {
    Relevance   float64
    Location    float64
    Availability float64
    Freshness   float64
    Trust       float64
    Rating      float64
    Priority    float64
}

func Score(f Factors) float64 {
    return f.Relevance +
        f.Location +
        f.Availability +
        f.Freshness +
        f.Trust +
        f.Rating +
        f.Priority
}

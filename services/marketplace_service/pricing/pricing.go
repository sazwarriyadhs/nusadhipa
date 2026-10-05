package pricing

type PriceRecommendation struct {
    BasePrice         float64 `json:"base_price"`
    RecommendedPrice  float64 `json:"recommended_price"`
    ServiceCost       float64 `json:"service_cost,omitempty"`
    Reason            string  `json:"reason,omitempty"`
}

func Recommend(base float64, serviceCost float64) PriceRecommendation {
    return PriceRecommendation{
        BasePrice:        base,
        RecommendedPrice: base + serviceCost,
        ServiceCost:      serviceCost,
        Reason:           "Rekomendasi harga untuk membantu memperhitungkan biaya layanan marketplace.",
    }
}

import os
from typing import List


CAPABILITY_ALIASES = {
    "product": "products",
    "products": "products",
    "service": "services",
    "services": "services",
    "hybrid": "products",
    "customer": "customers",
    "customer": "customers",
    "copilot": "aiCopilot",
}


def normalize_business_type(value: str) -> str:
    value = (value or "").strip().lower()

    aliases = {
        "produk": "product",
        "product": "product",
        "barang": "product",

        "jasa": "service",
        "service": "service",
        "services": "service",

        "produk+jasa": "hybrid",
        "produk + jasa": "hybrid",
        "product+service": "hybrid",
        "product + service": "hybrid",
        "hybrid": "hybrid",
        "mixed": "hybrid",

        "food": "food",
        "f&b": "food",
        "restaurant": "food",
        "restoran": "food",
        "hotel": "food",

        "workshop": "workshop",
        "bengkel": "workshop",

        "course": "course",
        "kursus": "course",
        "education": "course",

        "travel": "travel",
        "tour": "travel",
        "wisata": "travel",

        "ticketing": "ticketing",
        "event": "ticketing",

        "general": "general",
    }

    return aliases.get(value, "general")


def normalize_capabilities(values: List[str]) -> List[str]:
    result = []

    for value in values:
        normalized = (value or "").strip()

        if not normalized:
            continue

        normalized = CAPABILITY_ALIASES.get(
            normalized.lower(),
            normalized,
        )

        if normalized not in result:
            result.append(normalized)

    return result


BUSINESS_SERVICE_URL = os.getenv(
    "BUSINESS_SERVICE_URL",
    "http://localhost:8303",
).rstrip("/")


CATALOG_SERVICE_URL = os.getenv(
    "CATALOG_SERVICE_URL",
    "http://localhost:8304",
).rstrip("/")

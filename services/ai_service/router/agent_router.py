from typing import List

from core.config import normalize_business_type, normalize_capabilities


AGENT_CAPABILITIES = {
    "business_advisor": {
        "general",
        "products",
        "services",
        "sales",
        "customers",
        "finance",
    },
    "sales_insight": {
        "products",
        "services",
        "sales",
        "orders",
    },
    "inventory_forecast": {
        "products",
        "inventory",
        "purchases",
        "suppliers",
        "spareparts",
    },
    "customer_intelligence": {
        "customers",
        "orders",
        "sales",
        "services",
    },
    "financial_insight": {
        "finance",
        "sales",
        "payments",
        "invoices",
    },
    "marketing": {
        "products",
        "services",
        "customers",
        "sales",
        "menu",
    },
    "shopping_assistant": {
        "products",
        "menu",
        "orders",
    },
    "course_advisor": {
        "course",
        "students",
        "attendance",
    },
    "ticketing_advisor": {
        "ticketing",
        "events",
        "orders",
    },
    "travel_advisor": {
        "travel",
        "booking",
        "customers",
    },
}


MODE_AGENTS = {
    "product": [
        "sales_insight",
        "inventory_forecast",
        "customer_intelligence",
        "marketing",
        "shopping_assistant",
    ],
    "service": [
        "business_advisor",
        "customer_intelligence",
        "financial_insight",
        "marketing",
    ],
    "hybrid": [
        "business_advisor",
        "sales_insight",
        "inventory_forecast",
        "customer_intelligence",
        "financial_insight",
        "marketing",
    ],
    "food": [
        "business_advisor",
        "sales_insight",
        "inventory_forecast",
        "customer_intelligence",
        "marketing",
    ],
    "workshop": [
        "business_advisor",
        "inventory_forecast",
        "customer_intelligence",
        "financial_insight",
    ],
    "course": [
        "business_advisor",
        "customer_intelligence",
        "marketing",
        "course_advisor",
    ],
    "travel": [
        "business_advisor",
        "customer_intelligence",
        "marketing",
        "travel_advisor",
    ],
    "ticketing": [
        "business_advisor",
        "customer_intelligence",
        "marketing",
        "ticketing_advisor",
    ],
    "general": [
        "business_advisor",
        "customer_intelligence",
        "financial_insight",
        "marketing",
    ],
}


def resolve_agents(
    business_type: str,
    capabilities: List[str],
) -> List[str]:

    mode = normalize_business_type(business_type)
    normalized = set(normalize_capabilities(capabilities))

    candidates = MODE_AGENTS.get(
        mode,
        MODE_AGENTS["general"],
    )

    selected = []

    for agent in candidates:
        supported = AGENT_CAPABILITIES.get(agent, set())

        if not normalized:
            if agent == "business_advisor":
                selected.append(agent)
            continue

        if supported.intersection(normalized):
            selected.append(agent)

    if not selected:
        selected.append("business_advisor")

    return selected

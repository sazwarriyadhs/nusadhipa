from typing import Any, Dict, List, Optional

import httpx

from core.config import (
    BUSINESS_SERVICE_URL,
    CATALOG_SERVICE_URL,
    normalize_business_type,
)


class BusinessContextResolver:
    """
    Mengambil konteks bisnis aktual dari service internal.

    Sumber authoritative:
    - Business Service
    - Catalog Service

    Authorization JWT diteruskan dari request user.
    """

    def __init__(self):
        self.timeout = httpx.Timeout(
            connect=5.0,
            read=15.0,
            write=10.0,
            pool=5.0,
        )

    def resolve(
        self,
        business_id: str,
        authorization: str,
    ) -> Dict[str, Any]:
        business = self._get_business(
            business_id=business_id,
            authorization=authorization,
        )

        products = self._get_catalog(
            business_id=business_id,
            authorization=authorization,
        )

        context = self._build_context(
            business=business,
            products=products,
        )

        return context

    def _headers(self, authorization: str) -> Dict[str, str]:
        return {
            "Authorization": authorization,
            "Accept": "application/json",
        }

    def _get_business(
        self,
        business_id: str,
        authorization: str,
    ) -> Dict[str, Any]:
        url = (
            f"{BUSINESS_SERVICE_URL}"
            f"/api/v1/businesses/{business_id}"
        )

        response = httpx.get(
            url,
            headers=self._headers(authorization),
            timeout=self.timeout,
        )

        response.raise_for_status()

        payload = response.json()

        if isinstance(payload, dict):
            data = payload.get("data")

            if isinstance(data, dict):
                return data

            return payload

        raise ValueError(
            "Business service returned invalid response"
        )

    def _get_catalog(
        self,
        business_id: str,
        authorization: str,
    ) -> List[Dict[str, Any]]:
        url = (
            f"{CATALOG_SERVICE_URL}"
            f"/api/v1/catalog/products/"
        )

        response = httpx.get(
            url,
            params={"business_id": business_id},
            headers=self._headers(authorization),
            timeout=self.timeout,
        )

        response.raise_for_status()

        payload = response.json()

        if not isinstance(payload, dict):
            return []

        data = payload.get("data")

        if isinstance(data, list):
            return [
                item
                for item in data
                if isinstance(item, dict)
            ]

        return []

    def _build_context(
        self,
        business: Dict[str, Any],
        products: List[Dict[str, Any]],
    ) -> Dict[str, Any]:

        raw_business_type = str(
            business.get("business_type") or "general"
        )

        business_mode = normalize_business_type(
            raw_business_type
        )

        product_items = [
            item
            for item in products
            if str(item.get("product_type", "")).lower()
            not in {"service", "jasa"}
        ]

        service_items = [
            item
            for item in products
            if str(item.get("product_type", "")).lower()
            in {"service", "jasa"}
        ]

        capabilities = self._derive_capabilities(
            business_mode=business_mode,
            product_count=len(product_items),
            service_count=len(service_items),
        )

        return {
            "business": {
                "id": business.get("id"),
                "name": business.get("name"),
                "short_name": business.get("short_name"),
                "business_type": business_mode,
                "activity": business.get("activity"),
                "kbli_code": business.get("kbli_code"),
                "kbli_name": business.get("kbli_name"),
                "status": business.get("status"),
                "description": business.get("description"),
                "tagline": business.get("tagline"),
            },
            "catalog": {
                "total_items": len(products),
                "product_count": len(product_items),
                "service_count": len(service_items),
                "active_product_count": sum(
                    1
                    for item in product_items
                    if str(item.get("status", "")).lower()
                    == "active"
                ),
                "active_service_count": sum(
                    1
                    for item in service_items
                    if str(item.get("status", "")).lower()
                    == "active"
                ),
                "products": product_items,
                "services": service_items,
            },
            "capabilities": capabilities,
        }

    def _derive_capabilities(
        self,
        business_mode: str,
        product_count: int,
        service_count: int,
    ) -> List[str]:

        capabilities = []

        if product_count > 0:
            capabilities.append("products")

        if service_count > 0:
            capabilities.append("services")

        if business_mode == "product":
            if "products" not in capabilities:
                capabilities.append("products")

        elif business_mode == "service":
            if "services" not in capabilities:
                capabilities.append("services")

        elif business_mode == "hybrid":
            if "products" not in capabilities:
                capabilities.append("products")

            if "services" not in capabilities:
                capabilities.append("services")

        elif business_mode == "food":
            capabilities.extend(
                capability
                for capability in ["menu", "orders"]
                if capability not in capabilities
            )

        elif business_mode == "workshop":
            capabilities.extend(
                capability
                for capability in ["services", "spareparts"]
                if capability not in capabilities
            )

        elif business_mode == "course":
            if "course" not in capabilities:
                capabilities.append("course")

        elif business_mode == "travel":
            if "travel" not in capabilities:
                capabilities.append("travel")

        elif business_mode == "ticketing":
            if "ticketing" not in capabilities:
                capabilities.append("ticketing")

        return capabilities

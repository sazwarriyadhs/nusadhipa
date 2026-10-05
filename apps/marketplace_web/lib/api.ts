import { Business, BusinessMode, BusinessType } from "@/types/marketplace";

const API_BASE =
  process.env.NEXT_PUBLIC_MARKETPLACE_API_URL ||
  "http://localhost:8300";

export async function apiFetch<T>(
  path: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options?.headers || {}),
    },
  });

  if (!response.ok) {
    throw new Error(`API request failed: ${response.status}`);
  }

  return response.json();
}

function normalizeBusinessMode(value: unknown): BusinessMode {
  const mode = String(value || "")
    .trim()
    .toLowerCase();

  switch (mode) {
    case "product":
    case "service":
    case "hybrid":
    case "food":
    case "workshop":
    case "course":
    case "travel":
    case "ticketing":
      return mode;

    default:
      return "general";
  }
}

function normalizeBusinessType(
  businessType: unknown,
  businessMode: BusinessMode
): BusinessType {
  const raw = String(businessType || "")
    .trim()
    .toLowerCase();

  switch (raw) {
    case "product":
    case "products":
    case "produk":
    case "retail":
    case "wholesale":
      return "PRODUCT";

    case "service":
    case "services":
    case "jasa":
      return "SERVICE";

    case "hybrid":
    case "mixed":
    case "product+service":
    case "product + service":
    case "produk+jasa":
    case "produk + jasa":
      return "HYBRID";

    case "food":
    case "f&b":
    case "restaurant":
    case "restoran":
    case "kuliner":
      return "FOOD";

    case "workshop":
    case "bengkel":
      return "WORKSHOP";

    case "course":
    case "kursus":
    case "education":
      return "COURSE";

    case "travel":
    case "tour":
    case "wisata":
      return "TRAVEL";

    case "ticketing":
    case "event":
      return "TICKETING";

    case "supplier":
      return "SUPPLIER";

    case "reseller":
      return "RESELLER";

    case "partnership":
    case "kemitraan":
      return "PARTNERSHIP";

    default:
      break;
  }

  switch (businessMode) {
    case "product":
      return "PRODUCT";
    case "service":
      return "SERVICE";
    case "hybrid":
      return "HYBRID";
    case "food":
      return "FOOD";
    case "workshop":
      return "WORKSHOP";
    case "course":
      return "COURSE";
    case "travel":
      return "TRAVEL";
    case "ticketing":
      return "TICKETING";
    default:
      return "GENERAL";
  }
}

function businessCategory(
  item: any,
  businessMode: BusinessMode
): string {
  const kbliName = String(item.kbli_name || "").trim();

  if (kbliName) {
    return kbliName;
  }

  switch (businessMode) {
    case "product":
      return "Produk";
    case "service":
      return "Layanan";
    case "hybrid":
      return "Produk & Layanan";
    case "food":
      return "Kuliner";
    case "workshop":
      return "Bengkel";
    case "course":
      return "Kursus";
    case "travel":
      return "Travel";
    case "ticketing":
      return "Tiket & Event";
    default:
      return "UMKM";
  }
}

function mapBusiness(item: any): Business {
  const businessMode = normalizeBusinessMode(item.business_mode);

  const businessType = normalizeBusinessType(
    item.business_type,
    businessMode
  );

  const capabilities = Array.isArray(item.capabilities)
    ? item.capabilities.map((capability: any) => ({
        capability: String(capability?.capability || ""),
        label: String(capability?.label || capability?.capability || ""),
        description: capability?.description ?? null,
        sort_order:
          typeof capability?.sort_order === "number"
            ? capability.sort_order
            : undefined,
        source: capability?.source,
      }))
    : [];

  const address = String(item.address || "").trim();

  return {
    id: String(item.id || ""),
    name: String(item.name || ""),
    category: businessCategory(item, businessMode),
    location: address,

    businessType,
    businessMode,

    activity: item.activity ?? undefined,
    kbliCode: item.kbli_code ?? undefined,
    kbliName: item.kbli_name ?? undefined,

    productCount:
      typeof item.product_count === "number"
        ? item.product_count
        : 0,

    serviceCount:
      typeof item.service_count === "number"
        ? item.service_count
        : 0,

    capabilities,

    logoUrl:
      typeof item.logo_url === "string" && item.logo_url.trim()
        ? item.logo_url
        : undefined,

    coverImageUrl:
      typeof item.cover_image_url === "string" &&
      item.cover_image_url.trim()
        ? item.cover_image_url
        : undefined,

    brandColor: item.brand_color ?? undefined,

    phone: item.phone ?? undefined,
    email: item.email ?? undefined,
    whatsapp: item.whatsapp ?? undefined,
    website: item.website ?? undefined,

    tagline: item.tagline ?? undefined,
    description: item.description ?? undefined,

    legalStatus:
      item.verification?.verified === true
        ? "LEGAL_VERIFIED"
        : item.verification?.status === "in_process"
          ? "LEGALIZATION_IN_PROGRESS"
          : "NOT_ASSESSED",

    storeStatus:
      item.verification?.verified === true
        ? "VERIFIED_STORE"
        : "BASIC_STORE",

    verification: item.verification
      ? {
          status: item.verification.status,
          verified: item.verification.verified === true,
          level: item.verification.level || "basic",
          badge:
            item.verification.badge ||
            "BELUM TERVERIFIKASI",
          verification_code:
            item.verification.verification_code ?? null,
          public_url:
            item.verification.public_url ?? null,
        }
      : {
          status: "unverified",
          verified: false,
          level: "basic",
          badge: "BELUM TERVERIFIKASI",
          verification_code: null,
          public_url: null,
        },
  };
}

function extractBusinessItems(json: any): any[] {
  const candidates = [
    json?.data?.items,
    json?.data?.data?.items,
    json?.items,
  ];

  for (const value of candidates) {
    if (Array.isArray(value)) {
      return value;
    }
  }

  return [];
}

export async function getMarketplaceBusinesses(): Promise<Business[]> {
  const json = await apiFetch<any>(
    "/api/v1/marketplace/businesses"
  );

  return extractBusinessItems(json).map(mapBusiness);
}

export async function searchMarketplaceBusinesses(
  query: string
): Promise<Business[]> {
  const q = query.trim();

  const json = await apiFetch<any>(
    `/api/v1/marketplace/businesses?query=${encodeURIComponent(q)}`
  );

  return extractBusinessItems(json).map(mapBusiness);
}

export async function getMarketplaceBusiness(
  businessId: string
): Promise<Business | null> {
  try {
    const json = await apiFetch<any>(
      `/api/v1/marketplace/businesses/${businessId}`
    );

    const item =
      json?.data?.data ??
      json?.data ??
      null;

    return item ? mapBusiness(item) : null;
  } catch {
    return null;
  }
}

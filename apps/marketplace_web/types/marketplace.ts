export type LegalStatus =
  | "LEGAL_VERIFIED"
  | "LEGALIZATION_IN_PROGRESS"
  | "COMPLIANCE_IN_PROGRESS"
  | "NOT_ASSESSED";

export type StoreStatus =
  | "VERIFIED_STORE"
  | "STORE_IN_PROGRESS"
  | "BASIC_STORE";

export type BusinessType =
  | "PRODUCT"
  | "SERVICE"
  | "HYBRID"
  | "FOOD"
  | "WORKSHOP"
  | "COURSE"
  | "TRAVEL"
  | "TICKETING"
  | "SUPPLIER"
  | "RESELLER"
  | "PARTNERSHIP"
  | "GENERAL";

export type BusinessMode =
  | "product"
  | "service"
  | "hybrid"
  | "food"
  | "workshop"
  | "course"
  | "travel"
  | "ticketing"
  | "general";

export type VerificationStatus =
  | "unverified"
  | "in_process"
  | "verified"
  | "suspended"
  | "expired";

export interface BusinessCapability {
  capability: string;
  label: string;
  description?: string | null;
  sort_order?: number;
  source?: string;
}

export interface BusinessVerification {
  status: VerificationStatus;
  verified: boolean;
  level: "basic" | "legal";
  badge: string;
  verification_code?: string | null;
  public_url?: string | null;
}

export interface Business {
  id: string;
  name: string;

  category: string;
  location: string;

  businessType?: BusinessType;
  businessMode?: BusinessMode;

  activity?: string;
  kbliCode?: string;
  kbliName?: string;

  productCount?: number;
  serviceCount?: number;

  capabilities?: BusinessCapability[];

  logoUrl?: string;
  coverImageUrl?: string;
  brandColor?: string;

  phone?: string;
  email?: string;
  whatsapp?: string;
  website?: string;

  tagline?: string;
  description?: string;

  distanceKm?: number;

  legalStatus: LegalStatus;
  storeStatus: StoreStatus;

  verification?: BusinessVerification;

  rating?: number;
  freshnessMinutes?: number;
  prioritySearch?: boolean;
}

export interface Product {
  id: string;
  businessId: string;
  name: string;
  category: string;
  price: number;
  unit: string;
  stock: number;
  image?: string;
  business: Business;
}

export interface Opportunity {
  id: string;
  title: string;
  type: "RESELLER" | "AGENT" | "PARTNERSHIP";
  business: Business;
  startingCapital?: number;
  marginNote?: string;
  area: string;
}

export interface CommodityPrice {
  name: string;
  price: number;
  unit: string;
  change: "UP" | "DOWN" | "STABLE";
  source: string;
}

import Link from "next/link";
import ServiceCapabilityPanel from "@/components/service/ServiceCapabilityPanel";

interface BusinessDetail {
  id: string;
  name: string; legal_name?: string;
  short_name?: string;
  tagline?: string;
  description?: string;
  activity?: string;
  kbli_name?: string;
  address?: string;
  phone?: string;
  email?: string;
  whatsapp?: string;
  website?: string;
  logo_url?: string;
  cover_image_url?: string;
  brand_color?: string;
  status?: string;
  business_type?: string;
  business_mode?: string;
  kbli_code?: string;

  /*
   * Optional future field.
   * Backend tidak wajib mengirim sekarang.
   */
  sales_channels?: string[];
}

interface ServiceCapability {
  capability: string;
  label: string;
  description?: string | null;
  sort_order: number;
  source?: string;
}

interface Product {
  id: string;
  sku?: string;
  name: string;
  product_type?: string;
  unit?: string;
  selling_price?: number;
  price?: number;
  available_quantity?: number;
  status?: string;
  description?: string;

  // Marketplace product image fields.
  image_url?: string;
  cover_image_url?: string;
  image?: string;
}

const API_BASE =
  process.env.NEXT_PUBLIC_MARKETPLACE_API_URL ||
  "http://localhost:8300";

/*
 * =========================================================
 * NUSA-DHIPA ORIGINAL BRAND ASSET
 * =========================================================
 *
 * IMPORTANT:
 * File asli berada di:
 *
 * apps/marketplace_web/public/logo.png
 *
 * Browser URL:
 *
 * /logo.png
 *
 * Jangan mengganti dengan text-only branding,
 * initials, generated logo, atau logo business.
 */
const NUSA_DHIPA_LOGO = "/logo.png";

/* =========================================================
   API
   ========================================================= */

async function getBusiness(
  id: string
): Promise<BusinessDetail | null> {
  try {
    const response = await fetch(
      `${API_BASE}/api/v1/marketplace/businesses/${id}`,
      {
        cache: "no-store",
      }
    );

    if (!response.ok) {
      return null;
    }

    const json = await response.json();

    return json?.data?.data ?? json?.data ?? null;
  } catch {
    return null;
  }
}

async function getProducts(
  id: string
): Promise<Product[]> {
  try {
    const response = await fetch(
      `${API_BASE}/api/v1/marketplace/businesses/${id}/products`,
      {
        cache: "no-store",
      }
    );

    if (!response.ok) {
      return [];
    }

    const json = await response.json();

    const items =
      json?.data?.data?.items ??
      json?.data?.items ??
      json?.data?.data ??
      json?.data ??
      [];

    return Array.isArray(items) ? items : [];
  } catch {
    return [];
  }
}

async function getServiceCapabilities(
  id: string
): Promise<ServiceCapability[]> {
  try {
    const response = await fetch(
      `${API_BASE}/api/v1/marketplace/businesses/${id}/service-capabilities`,
      {
        cache: "no-store",
      }
    );

    if (!response.ok) {
      return [];
    }

    const json = await response.json();

    const capabilities =
      json?.data?.capabilities ??
      json?.data?.data?.capabilities ??
      [];

    return Array.isArray(capabilities)
      ? capabilities
      : [];
  } catch {
    return [];
  }
}

/* =========================================================
   NORMALIZATION
   ========================================================= */

function normalizeBusinessType(
  business?: BusinessDetail
): string {
  return String(
    business?.business_type || ""
  )
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_");
}

function normalizeBusinessMode(
  business?: BusinessDetail
): string {
  return String(
    business?.business_mode || ""
  )
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_");
}

function normalizeChannel(
  value: string
): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_");
}

function normalizeProductType(
  product: Product
): "product" | "service" {
  const type = String(
    product.product_type || "product"
  )
    .trim()
    .toLowerCase();

  if (
    type === "service" ||
    type === "jasa"
  ) {
    return "service";
  }

  return "product";
}

function hasCapability(
  capabilities: ServiceCapability[],
  name: string
): boolean {
  return capabilities.some(
    (item) =>
      item.capability.trim().toLowerCase() ===
      name.trim().toLowerCase()
  );
}

/* =========================================================
   BUSINESS TYPE
   ========================================================= */

interface BusinessTypeConfig {
  id: string;
  label: string;
  eyebrow: string;
  catalogTitle: string;
  catalogDescription: string;
  emptyTitle: string;
  emptyText: string;
  primaryAction: string;
}

function getBusinessTypeConfig(
  businessType: string,
  businessMode: string
): BusinessTypeConfig {
  switch (businessType) {
    case "supplier":
    case "wholesaler":
    case "wholesale":
      return {
        id: "supplier",
        label: "SUPPLIER",
        eyebrow: "SUPPLIER MARKETPLACE",
        catalogTitle: "Produk Supplier",
        catalogDescription:
          "Produk yang tersedia untuk kebutuhan eceran maupun grosir.",
        emptyTitle:
          "Katalog produk belum tersedia",
        emptyText:
          "Stok dan harga dapat dikonfirmasi langsung kepada supplier.",
        primaryAction:
          "Hubungi Supplier",
      };

    case "service":
    case "jasa":
      return {
        id: "service",
        label: "JASA & LAYANAN",
        eyebrow: "SERVICE MARKETPLACE",
        catalogTitle: "Layanan",
        catalogDescription:
          "Layanan yang tersedia dari usaha ini.",
        emptyTitle:
          "Layanan belum tersedia",
        emptyText:
          "Informasi layanan dapat dikonfirmasi langsung kepada penyedia.",
        primaryAction:
          "Hubungi Penyedia Jasa",
      };

    case "restaurant":
    case "resto":
    case "food":
    case "kuliner":
      return {
        id: "restaurant",
        label: "KULINER",
        eyebrow: "CULINARY MARKETPLACE",
        catalogTitle: "Menu",
        catalogDescription:
          "Menu yang tersedia dari usaha ini.",
        emptyTitle:
          "Menu belum tersedia",
        emptyText:
          "Menu dapat dikonfirmasi langsung kepada usaha.",
        primaryAction:
          "Pesan Sekarang",
      };

    case "retail":
    case "toko":
      return {
        id: "retail",
        label: "TOKO",
        eyebrow: "RETAIL MARKETPLACE",
        catalogTitle: "Produk",
        catalogDescription:
          "Produk yang tersedia dari toko ini.",
        emptyTitle:
          "Produk belum tersedia",
        emptyText:
          "Produk dapat dikonfirmasi langsung kepada toko.",
        primaryAction:
          "Hubungi Toko",
      };

    case "workshop":
    case "bengkel":
      return {
        id: "workshop",
        label: "BENGKEL",
        eyebrow: "WORKSHOP MARKETPLACE",
        catalogTitle: "Produk & Layanan",
        catalogDescription:
          "Produk dan layanan yang tersedia.",
        emptyTitle:
          "Produk atau layanan belum tersedia",
        emptyText:
          "Hubungi bengkel untuk informasi terbaru.",
        primaryAction:
          "Hubungi Bengkel",
      };

    case "course":
    case "education":
    case "pendidikan":
      return {
        id: "education",
        label: "PENDIDIKAN",
        eyebrow: "EDUCATION MARKETPLACE",
        catalogTitle: "Program",
        catalogDescription:
          "Program pendidikan dan pelatihan.",
        emptyTitle:
          "Program belum tersedia",
        emptyText:
          "Hubungi penyedia untuk informasi program.",
        primaryAction:
          "Hubungi Penyedia",
      };

    case "travel":
      return {
        id: "travel",
        label: "TRAVEL",
        eyebrow: "TRAVEL MARKETPLACE",
        catalogTitle: "Paket & Layanan",
        catalogDescription:
          "Paket perjalanan dan layanan travel.",
        emptyTitle:
          "Paket belum tersedia",
        emptyText:
          "Hubungi travel untuk informasi terbaru.",
        primaryAction:
          "Hubungi Travel",
      };

    case "ticketing":
      return {
        id: "ticketing",
        label: "TICKETING",
        eyebrow: "TICKETING MARKETPLACE",
        catalogTitle: "Tiket",
        catalogDescription:
          "Tiket yang tersedia.",
        emptyTitle:
          "Tiket belum tersedia",
        emptyText:
          "Hubungi penyedia untuk informasi tiket.",
        primaryAction:
          "Lihat Tiket",
      };

    case "product":
      return {
        id: "product",
        label: "PRODUK",
        eyebrow: "PRODUCT MARKETPLACE",
        catalogTitle: "Produk",
        catalogDescription:
          "Produk yang tersedia dari usaha ini.",
        emptyTitle:
          "Produk belum tersedia",
        emptyText:
          "Produk belum ditampilkan.",
        primaryAction:
          "Hubungi Usaha",
      };

    case "hybrid":
      return {
        id: "hybrid",
        label: "PRODUK & JASA",
        eyebrow: "BUSINESS MARKETPLACE",
        catalogTitle: "Produk & Layanan",
        catalogDescription:
          "Produk dan layanan yang tersedia.",
        emptyTitle:
          "Produk atau layanan belum tersedia",
        emptyText:
          "Hubungi usaha untuk informasi terbaru.",
        primaryAction:
          "Hubungi Usaha",
      };

    default:
      return {
        id: businessMode || "general",
        label: "USAHA",
        eyebrow: "BUSINESS MARKETPLACE",
        catalogTitle: "Produk & Layanan",
        catalogDescription:
          "Informasi produk dan layanan usaha.",
        emptyTitle:
          "Katalog belum tersedia",
        emptyText:
          "Informasi dapat dikonfirmasi langsung kepada usaha.",
        primaryAction:
          "Hubungi Usaha",
      };
  }
}

/* =========================================================
   SALES CHANNELS
   ========================================================= */

function getSalesChannels(
  business: BusinessDetail,
  businessType: string
): string[] {
  const explicitChannels =
    Array.isArray(
      business.sales_channels
    )
      ? business.sales_channels
          .map(normalizeChannel)
          .filter(Boolean)
      : [];

  if (explicitChannels.length > 0) {
    return Array.from(
      new Set(explicitChannels)
    );
  }

  /*
   * Backward compatible fallback.
   *
   * Supplier tanpa sales_channels dari backend
   * tetap dianggap dapat melayani:
   *
   * - retail / eceran
   * - wholesale / grosir
   */
  if (
    businessType === "supplier" ||
    businessType === "wholesaler" ||
    businessType === "wholesale"
  ) {
    return [
      "retail",
      "wholesale",
    ];
  }

  return [];
}

/* =========================================================
   LABELS
   ========================================================= */

function channelLabel(
  channel: string
): string {
  switch (
    normalizeChannel(channel)
  ) {
    case "retail":
    case "eceran":
      return "ECERAN";

    case "wholesale":
    case "grosir":
      return "GROSIR";

    case "reseller":
      return "RESELLER";

    case "partnership":
      return "KEMITRAAN";

    default:
      return channel
        .replace(/_/g, " ")
        .toUpperCase();
  }
}

/* =========================================================
   HELPERS
   ========================================================= */

function formatPrice(
  value?: number
): string {
  if (value == null) {
    return "Harga melalui usaha";
  }

  return new Intl.NumberFormat(
    "id-ID",
    {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0,
    }
  ).format(value);
}

function getImageUrl(
  value?: string
): string | null {
  if (!value) {
    return null;
  }

  const trimmed =
    value.trim();

  if (!trimmed) {
    return null;
  }

  if (
    trimmed.startsWith(
      "http://"
    ) ||
    trimmed.startsWith(
      "https://"
    ) ||
    trimmed.startsWith(
      "data:"
    )
  ) {
    return trimmed;
  }

  if (
    trimmed.startsWith("/")
  ) {
    return trimmed;
  }

  return `/${trimmed}`;
}

function getInitials(
  name: string
): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map(
      (word) =>
        word
          .charAt(0)
          .toUpperCase()
    )
    .join("");
}

function whatsappUrl(
  whatsapp?: string
): string | null {
  if (!whatsapp) {
    return null;
  }

  const digits =
    whatsapp.replace(
      /\D/g,
      ""
    );

  if (!digits) {
    return null;
  }

  let normalized =
    digits;

  if (
    normalized.startsWith("0")
  ) {
    normalized =
      "62" +
      normalized.slice(1);
  }

  if (
    !normalized.startsWith("62")
  ) {
    normalized =
      "62" + normalized;
  }

  return `https://wa.me/${normalized}`;
}

function phoneUrl(
  phone?: string
): string | null {
  if (!phone) {
    return null;
  }

  const value =
    phone.trim();

  if (!value) {
    return null;
  }

  return `tel:${value.replace(
    /[^0-9+]/g,
    ""
  )}`;
}

function websiteUrl(
  website?: string
): string | null {
  if (!website) {
    return null;
  }

  const value =
    website.trim();

  if (!value) {
    return null;
  }

  if (
    value.startsWith(
      "http://"
    ) ||
    value.startsWith(
      "https://"
    )
  ) {
    return value;
  }

  return `https://${value}`;
}

function getSupplierSignals(
  business: BusinessDetail
): string[] {
  const source = [
    business.activity,
    business.description,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const signals: string[] = [];

  if (
    source.includes("grosir") ||
    source.includes("wholesale")
  ) {
    signals.push(
      "MELAYANI GROSIR"
    );
  }

  if (
    source.includes("eceran") ||
    source.includes("retail")
  ) {
    signals.push(
      "MELAYANI ECERAN"
    );
  }

  if (
    source.includes("partai") ||
    source.includes("tonase")
  ) {
    signals.push(
      "PARTAI / TONASE"
    );
  }

  if (
    source.includes(
      "warehouse"
    ) ||
    source.includes(
      "gudang"
    ) ||
    source.includes(
      "pengambilan langsung"
    )
  ) {
    signals.push(
      "PICKUP WAREHOUSE"
    );
  }

  return Array.from(
    new Set(signals)
  );
}

/* =========================================================
   NUSA-DHIPA ORIGINAL LOGO
   ========================================================= */

function NusaDhipaLogo({
  className = "",
}: {
  className?: string;
}) {
  return (
    <img
      src={NUSA_DHIPA_LOGO}
      alt="NUSA-DHIPA"
      className={`block h-auto w-auto object-contain ${className}`}
    />
  );
}

/* =========================================================
   PAGE
   ========================================================= */

export default async function BusinessDetailPage({
  params,
}: {
  params: Promise<{
    businessId: string;
  }>;
}) {
  const {
    businessId,
  } = await params;

  const [
    business,
    catalogItems,
    serviceCapabilities,
  ] = await Promise.all([
    getBusiness(
      businessId
    ),
    getProducts(
      businessId
    ),
    getServiceCapabilities(
      businessId
    ),
  ]);

  /* =======================================================
     NOT FOUND
     ======================================================= */

  if (!business) {
    return (
      <main className="min-h-screen bg-white px-6 py-16">
        <div className="mx-auto max-w-4xl">

          <div className="mb-10 flex items-center justify-between gap-6">
            <Link
              href="/"
              className="font-bold text-[#e5232e] transition hover:text-[#c91c26]"
            >
              ← Kembali ke Marketplace
            </Link>

            <Link
              href="/"
              aria-label="NUSA-DHIPA Marketplace"
            >
              <NusaDhipaLogo
                className="max-h-12 max-w-[180px]"
              />
            </Link>
          </div>

          <div className="rounded-[2rem] border-2 border-[#e5232e]/10 bg-white p-10 text-center shadow-sm">

            <div className="mx-auto grid size-16 place-items-center rounded-2xl bg-[#e5232e] text-2xl font-black text-white">
              !
            </div>

            <h1 className="mt-5 text-2xl font-black">
              Usaha tidak ditemukan
            </h1>

            <p className="mt-2 text-sm text-black/50">
              Data usaha tidak tersedia atau
              sudah tidak aktif.
            </p>

          </div>
        </div>
      </main>
    );
  }

  /* =======================================================
     BUSINESS CONTEXT
     ======================================================= */

  const businessType =
    normalizeBusinessType(
      business
    );

  const businessMode =
    normalizeBusinessMode(
      business
    );

  /*
   * business_type = identity utama usaha.
   * business_mode = model konten/capability.
   * sales_channels = cara usaha menjual.
   */
  const config =
    getBusinessTypeConfig(
      businessType,
      businessMode
    );

  const salesChannels =
    getSalesChannels(
      business,
      businessType
    );

  const products =
    catalogItems.filter(
      (item) =>
        normalizeProductType(
          item
        ) === "product"
    );

  const services =
    catalogItems.filter(
      (item) =>
        normalizeProductType(
          item
        ) === "service"
    );

  const isSupplier =
    config.id === "supplier";

  const isRestaurant =
    config.id === "restaurant";

  const isHybrid =
    config.id === "hybrid";

  const showProducts =
    products.length > 0 ||
    hasCapability(
      serviceCapabilities,
      "products"
    ) ||
    hasCapability(
      serviceCapabilities,
      "menu"
    ) ||
    businessMode === "product" ||
    businessMode === "hybrid" ||
    businessMode === "food" ||
    businessMode === "workshop";

  const showServices =
    services.length > 0 ||
    hasCapability(
      serviceCapabilities,
      "services"
    ) ||
    businessMode === "service" ||
    businessMode === "hybrid" ||
    businessMode === "workshop";

  const showServicePanel =
    serviceCapabilities.length > 0;

  /* =======================================================
     TENANT MARKETPLACE BRANDING
     ======================================================= */

  /*
   * Backend remains the primary source of tenant branding.
   *
   * The Sauri assets below are only fallback assets when
   * the tenant does not yet have logo/cover data persisted
   * in the Business OS.
   *
   * IMPORTANT:
   * - NUSA-DHIPA logo remains /logo.png
   * - Business logo remains tenant-specific
   * - Sauri branding must never become the default for
   *   other tenants.
   */

  const businessNameForBranding =
    String(
      business.legal_name ||
      business.name ||
      ""
    )
      .trim()
      .toLowerCase();

  const isSauriTenant =
    businessNameForBranding.includes(
      "sauri"
    );

  /*
   * KBLI-aware signal.
   *
   * 46322 = Perdagangan Besar Daging Ayam
   * dan Daging Ayam Olahan.
   *
   * We intentionally use this only as a Sauri
   * reinforcement signal, not as a global hard-code
   * for every tenant with the same KBLI.
   */
  const kbliCode =
    String(
      business.kbli_code ||
      ""
    )
      .trim()
      .toUpperCase();

  const isSauriPoultry =
    isSauriTenant &&
    (
      kbliCode === "46322" ||
      String(
        business.kbli_name ||
        ""
      )
        .toLowerCase()
        .includes("daging ayam")
    );

  const coverImage =
    getImageUrl(
      business.cover_image_url
    ) ||
    (
      isSauriPoultry
        ? "/sauri/header-poultry-processing.png"
        : isSauriTenant
          ? "/sauri/header-poultry-processing.png"
          : null
    );

  /*
   * Ini KHUSUS logo bisnis.
   * Tidak pernah dipakai sebagai logo NUSA-DHIPA.
   */
  const logoImage =
    getImageUrl(
      business.logo_url
    ) ||
    (
      isSauriTenant
        ? "/sauri/logo.png"
        : null
    );

  /*
   * Secondary visual untuk tenant Sauri.
   * Tidak digunakan sebagai global marketplace asset.
   */
  const secondaryBusinessImage =
    isSauriPoultry
      ? "/sauri/poultry-processing-facility.png"
      : null;

  /* =======================================================
     CONTACT
     ======================================================= */

  const whatsapp =
    whatsappUrl(
      business.whatsapp
    );

  const phone =
    phoneUrl(
      business.phone
    );

  const website =
    websiteUrl(
      business.website
    );

  /* =======================================================
     SUPPLIER SIGNALS
     ======================================================= */

  const supplierSignals =
    getSupplierSignals(
      business
    );

  return (
    <main className="min-h-screen bg-white">

      {/* =================================================
          NAV
          ================================================= */}

      <header className="border-b border-[#e5232e]/10 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-6 px-6 py-4">

          <Link
            href="/"
            className="shrink-0 text-sm font-black text-[#e5232e] transition hover:text-[#c91c26]"
          >
            ← Marketplace
          </Link>

          {/* ORIGINAL NUSA-DHIPA LOGO */}
          <Link
            href="/"
            aria-label="NUSA-DHIPA Marketplace"
            className="flex shrink-0 items-center"
          >
            <NusaDhipaLogo
              className="max-h-12 max-w-[190px] md:max-h-14 md:max-w-[220px]"
            />
          </Link>

        </div>
      </header>

      {/* =================================================
          HERO
          ================================================= */}

      <section className="relative overflow-hidden bg-[#fff5f5]">

        <div className="pointer-events-none absolute right-[-100px] top-[-100px] size-80 rounded-full bg-[#e5232e]/10" />

        <div className="pointer-events-none absolute bottom-[-140px] left-[-80px] size-72 rounded-full bg-[#e5232e]/10" />

        <div className="relative mx-auto max-w-7xl px-6 py-8 md:py-12">

          <div className="overflow-hidden rounded-[2rem] border border-[#e5232e]/15 bg-white shadow-[0_20px_70px_rgba(229,35,46,0.12)]">

            {/* =================================================
                BUSINESS COVER
                ================================================= */}

            {coverImage && (
              <div className="relative h-48 overflow-hidden border-b border-[#e5232e]/10 md:h-64">

                <img
                  src={coverImage}
                  alt=""
                  className="h-full w-full object-cover"
                />

                <div className="absolute inset-0 bg-gradient-to-t from-[#e5232e]/40 to-transparent" />

                <div className="absolute bottom-5 left-6">

                  <span className="rounded-full bg-white px-4 py-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#e5232e]">
                    {config.eyebrow}
                  </span>

                </div>

              </div>
            )}

            <div className="p-6 md:p-10">

              <div className="flex flex-col gap-8 lg:flex-row lg:items-center lg:justify-between">

                {/* =================================================
                    BUSINESS IDENTITY
                    ================================================= */}

                <div className="flex min-w-0 items-center gap-5">

                  {/* BUSINESS LOGO ONLY */}
                  <div className="size-24 shrink-0 overflow-hidden rounded-[1.5rem] border-2 border-[#e5232e]/15 bg-[#fff5f5] md:size-28">

                    {logoImage ? (
                      <img
                        src={logoImage}
                        alt={`${business.name} logo`}
                        className="h-full w-full object-contain p-2"
                      />
                    ) : (
                      <div className="grid h-full w-full place-items-center bg-[#e5232e] text-3xl font-black text-white">
                        {getInitials(
                          business.name
                        )}
                      </div>
                    )}

                  </div>

                  <div className="min-w-0">

                    <div className="flex flex-wrap items-center gap-2">

                      <span className="rounded-full bg-[#e5232e] px-3 py-1 text-[10px] font-black uppercase tracking-[0.15em] text-white">
                        {config.label}
                      </span>

                      {business.status && (
                        <span className="rounded-full border border-[#e5232e]/15 bg-white px-3 py-1 text-[10px] font-black uppercase tracking-wider text-[#e5232e]">
                          {business.status}
                        </span>
                      )}

                    </div>

                    <h1 className="mt-3 text-3xl font-black tracking-tight text-[#17191d] md:text-5xl">
  {business.legal_name || business.name}
</h1>

{business.legal_name &&
  business.name &&
  business.name !== business.legal_name && (
    <p className="mt-2 text-base font-bold text-[#e5232e] md:text-lg">
      {business.name}
    </p>
  )}

{business.tagline && (
  <p className="mt-2 max-w-3xl text-sm text-black/50 md:text-base">
    {business.tagline}
  </p>
)}
                  </div>

                </div>

                {/* =================================================
                    ACTIONS
                    ================================================= */}

                <div className="flex shrink-0 flex-wrap gap-3">

                  {whatsapp && (
                    <a
                      href={whatsapp}
                      target="_blank"
                      rel="noreferrer"
                      className="rounded-2xl bg-[#e5232e] px-6 py-3 text-sm font-black text-white shadow-lg shadow-[#e5232e]/20 transition hover:-translate-y-0.5 hover:bg-[#c91c26]"
                    >
                      {config.primaryAction}
                    </a>
                  )}

                  {phone && (
                    <a
                      href={phone}
                      className="rounded-2xl border-2 border-[#e5232e] bg-white px-6 py-3 text-sm font-black text-[#e5232e] transition hover:bg-[#fff5f5]"
                    >
                      Telepon
                    </a>
                  )}

                </div>

              </div>

              {/* =================================================
                  SALES CHANNEL
                  ================================================= */}

              {salesChannels.length > 0 && (
                <div className="mt-8 border-t border-[#e5232e]/10 pt-7">

                  <div className="text-[10px] font-black uppercase tracking-[0.2em] text-[#e5232e]">
                    CHANNEL PENJUALAN
                  </div>

                  <div className="mt-3 flex flex-wrap gap-3">

                    {salesChannels.map(
                      (channel) => (
                        <div
                          key={channel}
                          className="rounded-2xl border-2 border-[#e5232e] bg-white px-5 py-3 text-sm font-black text-[#e5232e]"
                        >
                          {channelLabel(
                            channel
                          )}
                        </div>
                      )
                    )}

                  </div>

                </div>
              )}

              {/* =================================================
                  META
                  ================================================= */}

              <div className="mt-7 grid gap-3 md:grid-cols-2 lg:grid-cols-4">

                {business.address && (
                  <MetaCard
                    label="Lokasi"
                    value={
                      business.address
                    }
                  />
                )}

                {business.activity && (
                  <MetaCard
                    label="Kegiatan Usaha"
                    value={
                      business.activity
                    }
                  />
                )}

                {business.kbli_code && (
                  <MetaCard
                    label="KBLI"
                    value={`${business.kbli_code}${
                      business.kbli_name
                        ? ` · ${business.kbli_name}`
                        : ""
                    }`}
                  />
                )}

                {business.phone && (
                  <MetaCard
                    label="Kontak"
                    value={
                      business.phone
                    }
                  />
                )}

              </div>

            </div>
          </div>
        </div>
      </section>

      {/* =================================================
          MAIN
          ================================================= */}

      <section className="mx-auto max-w-7xl px-6 py-10">

        {/* =================================================
            TENANT BRAND VISUAL
            ================================================= */}

        {secondaryBusinessImage && (
          <section className="mb-10 overflow-hidden rounded-[2rem] border border-[#e5232e]/10 bg-white shadow-sm">

            <div className="relative h-56 overflow-hidden md:h-72">

              <img
                src={secondaryBusinessImage}
                alt={`${business.name} production facility`}
                className="h-full w-full object-cover"
              />

              <div className="absolute inset-0 bg-gradient-to-t from-black/45 via-black/5 to-transparent" />

              <div className="absolute bottom-6 left-6 right-6">
                <div className="max-w-3xl">

                  <div className="text-[10px] font-black uppercase tracking-[0.2em] text-white/80">
                    BUSINESS PROFILE
                  </div>

                  <h2 className="mt-1 text-2xl font-black text-white md:text-3xl">
                    Processed Chicken • Fish • Petfood
                  </h2>

                  <p className="mt-2 max-w-2xl text-sm leading-6 text-white/85">
                    PT Sauri Unggul Sejahtera — supplier dan produsen
                    untuk kebutuhan B2B, retail, dan marketplace.
                  </p>

                </div>
              </div>

            </div>

          </section>
        )}

        {/* =================================================
            SUPPLIER
            ================================================= */}

        {isSupplier && (
          <section className="grid gap-6 lg:grid-cols-[1.35fr_0.65fr]">

            <div className="rounded-[2rem] border border-[#e5232e]/15 bg-white p-7 shadow-sm md:p-9">

              <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
                PROFIL SUPPLIER
              </div>

              <h2 className="mt-2 text-2xl font-black text-[#17191d] md:text-3xl">
                Supplier & Penjualan Eceran
              </h2>

              <p className="mt-4 max-w-3xl leading-7 text-black/60">
                {business.description ||
                  config.catalogDescription}
              </p>

              <div className="mt-7 grid gap-3 sm:grid-cols-2">

                <ChannelCard
                  label="ECERAN"
                  title="Pembelian langsung"
                  description="Melayani kebutuhan pelanggan secara eceran."
                  active={salesChannels.some(
                    (item) => {
                      const normalized =
                        normalizeChannel(
                          item
                        );

                      return (
                        normalized ===
                          "retail" ||
                        normalized ===
                          "eceran"
                      );
                    }
                  )}
                />

                <ChannelCard
                  label="GROSIR"
                  title="Pembelian partai"
                  description="Melayani kebutuhan usaha secara grosir."
                  active={salesChannels.some(
                    (item) => {
                      const normalized =
                        normalizeChannel(
                          item
                        );

                      return (
                        normalized ===
                          "wholesale" ||
                        normalized ===
                          "grosir"
                      );
                    }
                  )}
                />

              </div>

              {supplierSignals.length > 0 && (
                <div className="mt-6 flex flex-wrap gap-2">

                  {supplierSignals.map(
                    (signal) => (
                      <span
                        key={signal}
                        className="rounded-full bg-[#fff5f5] px-4 py-2 text-xs font-black text-[#e5232e]"
                      >
                        {signal}
                      </span>
                    )
                  )}

                </div>
              )}

            </div>

            {/* =================================================
                SUPPLIER CTA
                ================================================= */}

            <div className="rounded-[2rem] border-2 border-[#e5232e] bg-[#e5232e] p-7 text-white md:p-8">

              <div className="text-xs font-black uppercase tracking-[0.2em] text-white/70">
                PESAN SEKARANG
              </div>

              <h2 className="mt-2 text-2xl font-black">
                Butuh stok?
              </h2>

              <p className="mt-3 text-sm leading-6 text-white/80">
                Hubungi supplier untuk
                mengecek stok, harga,
                minimum pembelian, dan
                pemesanan.
              </p>

              {whatsapp && (
                <a
                  href={whatsapp}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-7 block rounded-2xl bg-white px-5 py-4 text-center text-sm font-black text-[#e5232e] transition hover:bg-[#fff5f5]"
                >
                  Hubungi Supplier →
                </a>
              )}

              {phone && (
                <a
                  href={phone}
                  className="mt-3 block rounded-2xl border-2 border-white/60 px-5 py-4 text-center text-sm font-black text-white transition hover:bg-white/10"
                >
                  Telepon Supplier
                </a>
              )}

            </div>

          </section>
        )}

        {/* =================================================
            ABOUT NON SUPPLIER
            ================================================= */}

        {!isSupplier &&
          business.description && (
            <section className="rounded-[2rem] border border-[#e5232e]/15 bg-white p-7 shadow-sm md:p-9">

              <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
                TENTANG USAHA
              </div>

              <h2 className="mt-2 text-2xl font-black">
                {business.short_name ||
                  business.name}
              </h2>

              <p className="mt-4 max-w-4xl leading-7 text-black/60">
                {business.description}
              </p>

            </section>
          )}

        {/* =================================================
            CAPABILITIES
            ================================================= */}

        {showServicePanel &&
          !isSupplier && (
            <section className="mt-10">

              <ServiceCapabilityPanel
                businessId={
                  business.id
                }
                businessName={
                  business.name
                }
                capabilities={
                  serviceCapabilities
                }
                whatsapp={
                  business.whatsapp
                }
                phone={
                  business.phone
                }
                email={
                  business.email
                }
              />

            </section>
          )}

        {/* =================================================
            SUPPLIER PRODUCTS
            ================================================= */}

        {isSupplier && (
          <section className="mt-10">

            <CatalogSection
              title="Produk Supplier"
              description={`Produk ${business.name} untuk pembelian eceran maupun grosir.`}
              items={products}
              emptyTitle="Katalog produk belum tersedia"
              emptyText="Daftar produk dan harga belum dimasukkan ke katalog online."
              emptyAction={
                whatsapp
                  ? {
                      label:
                        "Tanya Stok & Harga",
                      href:
                        whatsapp,
                    }
                  : undefined
              }
              supplier
            />

          </section>
        )}

        {/* =================================================
            RESTAURANT
            ================================================= */}

        {isRestaurant &&
          showProducts && (
            <section className="mt-10">

              <CatalogSection
                title="Menu"
                description={`Menu yang tersedia dari ${business.name}.`}
                items={products}
                emptyTitle="Menu belum tersedia"
                emptyText="Menu belum dimasukkan ke katalog online."
                emptyAction={
                  whatsapp
                    ? {
                        label:
                          "Pesan Sekarang",
                        href:
                          whatsapp,
                      }
                    : undefined
                }
              />

            </section>
          )}

        {/* =================================================
            PRODUCTS
            ================================================= */}

        {!isSupplier &&
          !isRestaurant &&
          showProducts && (
            <section className="mt-10">

              <CatalogSection
                title={
                  isHybrid
                    ? "Produk"
                    : config.catalogTitle
                }
                description={`Produk yang tersedia dari ${business.name}.`}
                items={products}
                emptyTitle={
                  config.emptyTitle
                }
                emptyText={
                  config.emptyText
                }
                emptyAction={
                  whatsapp
                    ? {
                        label:
                          config.primaryAction,
                        href:
                          whatsapp,
                      }
                    : undefined
                }
              />

            </section>
          )}

        {/* =================================================
            SERVICES
            ================================================= */}

        {!isSupplier &&
          showServices && (
            <section className="mt-10">

              <CatalogSection
                title="Layanan"
                description={`Layanan yang tersedia dari ${business.name}.`}
                items={services}
                emptyTitle="Layanan belum tersedia"
                emptyText="Layanan belum dimasukkan ke katalog online."
                emptyAction={
                  whatsapp
                    ? {
                        label:
                          config.primaryAction,
                        href:
                          whatsapp,
                      }
                    : undefined
                }
              />

            </section>
          )}

        {/* =================================================
            CONTACT
            ================================================= */}

        <section className="mt-10 rounded-[2rem] border-2 border-[#e5232e] bg-[#fff5f5] p-7 md:p-9">

          <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">

            <div>

              <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
                HUBUNGI USAHA
              </div>

              <h2 className="mt-2 text-2xl font-black text-[#17191d] md:text-3xl">
                Tertarik dengan{" "}
                {business.name}?
              </h2>

              <p className="mt-2 max-w-2xl text-sm leading-6 text-black/55">
                Hubungi langsung untuk
                informasi produk, stok,
                harga, layanan, atau
                pemesanan.
              </p>

            </div>

            <div className="flex shrink-0 flex-wrap gap-3">

              {whatsapp && (
                <a
                  href={whatsapp}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl bg-[#e5232e] px-6 py-3 text-sm font-black text-white shadow-lg shadow-[#e5232e]/20 transition hover:bg-[#c91c26]"
                >
                  WhatsApp
                </a>
              )}

              {phone && (
                <a
                  href={phone}
                  className="rounded-2xl border-2 border-[#e5232e] bg-white px-6 py-3 text-sm font-black text-[#e5232e] transition hover:bg-[#fff5f5]"
                >
                  Telepon
                </a>
              )}

              {website && (
                <a
                  href={website}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl border-2 border-[#e5232e] bg-white px-6 py-3 text-sm font-black text-[#e5232e] transition hover:bg-[#fff5f5]"
                >
                  Website
                </a>
              )}

            </div>

          </div>

        </section>

      </section>

      {/* =================================================
          FOOTER
          ================================================= */}

      <footer className="border-t border-[#e5232e]/10 bg-white">

        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-6 py-8 md:flex-row md:items-center md:justify-between">

          <div>

            {/* ORIGINAL NUSA-DHIPA LOGO */}
            <Link
              href="/"
              aria-label="NUSA-DHIPA Marketplace"
              className="inline-flex items-center"
            >
              <NusaDhipaLogo
                className="max-h-10 max-w-[180px]"
              />
            </Link>

            <div className="mt-2 text-xs text-black/40">
              Marketplace UMKM &
              Business Ecosystem
            </div>

          </div>

          <div className="text-xs font-black text-[#e5232e]">
            {config.label}
          </div>

        </div>

      </footer>

    </main>
  );
}

/* =========================================================
   META CARD
   ========================================================= */

function MetaCard({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl border border-[#e5232e]/10 bg-white p-4">

      <div className="text-[10px] font-black uppercase tracking-[0.16em] text-[#e5232e]">
        {label}
      </div>

      <div className="mt-2 text-sm font-bold leading-5 text-black/65">
        {value}
      </div>

    </div>
  );
}

/* =========================================================
   CHANNEL CARD
   ========================================================= */

function ChannelCard({
  label,
  title,
  description,
  active,
}: {
  label: string;
  title: string;
  description: string;
  active: boolean;
}) {
  return (
    <div
      className={`rounded-2xl border-2 p-5 ${
        active
          ? "border-[#e5232e] bg-[#fff5f5]"
          : "border-[#e5232e]/10 bg-white"
      }`}
    >

      <div className="flex items-center justify-between gap-3">

        <span className="text-xs font-black tracking-[0.16em] text-[#e5232e]">
          {label}
        </span>

        {active && (
          <span className="rounded-full bg-[#e5232e] px-2 py-1 text-[9px] font-black text-white">
            AKTIF
          </span>
        )}

      </div>

      <div className="mt-3 font-black">
        {title}
      </div>

      <p className="mt-1 text-xs leading-5 text-black/50">
        {description}
      </p>

    </div>
  );
}

/* =========================================================
   CATALOG
   ========================================================= */

/* =========================================================
   PRODUCT IMAGE
   ========================================================= */

function formatProductPrice(
  value?: number
): string {
  if (
    value == null ||
    !Number.isFinite(Number(value)) ||
    Number(value) <= 0
  ) {
    return "Harga berdasarkan permintaan";
  }

  return formatPrice(Number(value));
}
function getProductImageUrl(
  product: Product
): string | null {
  const raw =
    product.image_url ||
    product.cover_image_url ||
    product.image ||
    "";

  const value = String(raw).trim();

  if (!value) {
    return null;
  }

  // Already absolute.
  if (
    value.startsWith("http://") ||
    value.startsWith("https://") ||
    value.startsWith("data:")
  ) {
    return value;
  }

  // Already an application-relative URL.
  if (value.startsWith("/")) {
    return value;
  }

  // Defensive fallback for a plain filename.
  if (product.id && value) {
    return `/media/catalog/products/${product.id}/${value}`;
  }

  return null;
}
function CatalogSection({
  title,
  description,
  items,
  emptyTitle,
  emptyText,
  emptyAction,
  supplier = false,
}: {
  title: string;
  description: string;
  items: Product[];
  emptyTitle: string;
  emptyText: string;
  emptyAction?: {
    label: string;
    href: string;
  };
  supplier?: boolean;
}) {
  return (
    <div>

      <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">

        <div>

          <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
            KATALOG
          </div>

          <h2 className="mt-1 text-2xl font-black md:text-3xl">
            {title}
          </h2>

          <p className="mt-1 text-sm text-black/50">
            {description}
          </p>

        </div>

        {items.length > 0 && (
          <span className="text-sm font-black text-[#e5232e]">
            {items.length} ITEM
          </span>
        )}

      </div>

      {items.length === 0 ? (
        <div className="mt-5 rounded-[2rem] border-2 border-dashed border-[#e5232e]/20 bg-[#fff5f5] p-10 text-center">

          <div className="mx-auto grid size-16 place-items-center rounded-2xl bg-[#e5232e] text-2xl font-black text-white">
            {supplier
              ? "S"
              : "N"}
          </div>

          <h3 className="mt-5 text-xl font-black">
            {emptyTitle}
          </h3>

          <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-black/50">
            {emptyText}
          </p>

          {emptyAction && (
            <a
              href={
                emptyAction.href
              }
              target={
                emptyAction.href.startsWith(
                  "https://wa.me/"
                )
                  ? "_blank"
                  : undefined
              }
              rel={
                emptyAction.href.startsWith(
                  "https://wa.me/"
                )
                  ? "noreferrer"
                  : undefined
              }
              className="mt-6 inline-flex rounded-2xl bg-[#e5232e] px-6 py-3 text-sm font-black text-white shadow-lg shadow-[#e5232e]/20 transition hover:-translate-y-0.5 hover:bg-[#c91c26]"
            >
              {emptyAction.label} →
            </a>
          )}

        </div>
      ) : (
        <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">

          {items.map(
            (item) => (
              <article
                key={item.id}
                className="group overflow-hidden rounded-[1.5rem] border border-black/[0.06] bg-white shadow-[0_8px_30px_rgba(0,0,0,0.04)] transition-all duration-300 hover:-translate-y-1.5 hover:border-[#e5232e]/25 hover:shadow-[0_20px_45px_rgba(229,35,46,0.12)]"
              >

                {(() => {
                  const imageUrl =
                    getProductImageUrl(item);

                  return imageUrl ? (
                    <div className="relative aspect-[4/3] w-full overflow-hidden bg-gradient-to-br from-[#fff7f7] via-white to-[#fff0f0]">
                      <img
                        src={imageUrl}
                        alt={item.name}
                        className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                        loading="lazy"
                      />

                      <div className="absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-black/15 to-transparent pointer-events-none" />

        <div className="absolute left-3 top-3 rounded-xl bg-[#e5232e] px-2.5 py-1 text-[10px] font-black uppercase tracking-[0.15em] text-white shadow-md">
                        {normalizeProductType(
                          item
                        ) === "service"
                          ? "JASA"
                          : "PRODUK"}
                      </div>
                    </div>
                  ) : (
                    <div className="grid aspect-[4/3] w-full place-items-center bg-[#fff5f5]">
                      <div className="grid size-16 place-items-center rounded-2xl bg-[#e5232e] text-sm font-black uppercase text-white shadow-md">
                        {normalizeProductType(
                          item
                        ) === "service"
                          ? "J"
                          : "P"}
                      </div>
                    </div>
                  );
                })()}

                <div className="p-5">

                  {item.sku && (
                    <div className="text-[10px] font-black uppercase tracking-[0.16em] text-[#e5232e]/70">
                      SKU {item.sku}
                    </div>
                  )}

                  <h3 className="mt-1 font-black text-[#17191d]">
                    {item.name}
                  </h3>

                  {item.description && (
                    <p className="mt-2 line-clamp-3 text-sm leading-6 text-black/50">
                      {item.description}
                    </p>
                  )}

                  {item.unit && (
                    <p className="mt-2 text-sm text-black/50">
                      Satuan:{" "}
                      {item.unit}
                    </p>
                  )}

                  <div className="mt-4 font-black text-[#e5232e]">
                    {formatPrice(
                      item.selling_price ??
                        item.price
                    )}
                  </div>

                  {item.available_quantity !=
                    null && (
                    <div className="mt-2 text-xs font-semibold text-black/40">
                      Ketersediaan:{" "}
                      {
                        item.available_quantity
                      }
                    </div>
                  )}

                </div>

              </article>
            )
          )}

        </div>
      )}

    </div>
  );
}




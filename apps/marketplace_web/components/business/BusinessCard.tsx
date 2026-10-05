
import Link from "next/link";
import {
  ArrowRight,
  CheckCircle2,
  FileCheck2,
  MapPin,
  ShieldCheck,
  Star,
  Zap,
  Store,
  BriefcaseBusiness,
  Truck,
} from "lucide-react";
import { Business } from "@/types/marketplace";

function legalLabel(status: Business["legalStatus"]) {
  switch (status) {
    case "LEGAL_VERIFIED":
      return "LEGAL VERIFIED";
    case "LEGALIZATION_IN_PROGRESS":
      return "LEGALIZATION IN PROGRESS";
    case "COMPLIANCE_IN_PROGRESS":
      return "COMPLIANCE IN PROGRESS";
    default:
      return "LEGAL BELUM TERVERIFIKASI";
  }
}

function legalTone(status: Business["legalStatus"]) {
  switch (status) {
    case "LEGAL_VERIFIED":
      return "border-green-200 bg-green-50 text-green-700";
    case "LEGALIZATION_IN_PROGRESS":
      return "border-amber-200 bg-amber-50 text-amber-700";
    case "COMPLIANCE_IN_PROGRESS":
      return "border-blue-200 bg-blue-50 text-blue-700";
    default:
      return "border-gray-200 bg-gray-50 text-gray-600";
  }
}

function businessTypeLabel(type?: string) {
  switch (String(type || "").trim().toUpperCase()) {
    case "SERVICE":
      return "JASA & LAYANAN";

    case "SUPPLIER":
      return "SUPPLIER";

    case "RESTAURANT":
      return "KULINER";

    case "RETAIL":
      return "TOKO";

    case "PRODUCT":
      return "PRODUK";

    case "WHOLESALE":
      return "GROSIR";

    default:
      return "USAHA";
  }
}

function businessTypeIcon(type?: string) {
  switch (String(type || "").trim().toUpperCase()) {
    case "SERVICE":
      return BriefcaseBusiness;

    case "SUPPLIER":
    case "WHOLESALE":
      return Truck;

    default:
      return Store;
  }
}

function detailLabel(type?: string) {
  switch (String(type || "").trim().toUpperCase()) {
    case "SERVICE":
      return "Profil Jasa";

    case "SUPPLIER":
      return "Lihat Supplier";

    case "RESTAURANT":
      return "Lihat Usaha";

    case "RETAIL":
      return "Lihat Toko";

    case "PRODUCT":
      return "Lihat Usaha";

    case "WHOLESALE":
      return "Lihat Supplier";

    default:
      return "Lihat Profil";
  }
}

function getInitials(name: string) {
  const words = name
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (words.length >= 2) {
    return `${words[0][0]}${words[1][0]}`.toUpperCase();
  }

  return name.slice(0, 2).toUpperCase();
}

export default function BusinessCard({
  business,
}: {
  business: Business;
}) {
  const verified =
    business.verification?.verified === true;

  const TypeIcon = businessTypeIcon(
    business.businessType
  );

  const typeLabel = businessTypeLabel(
    business.businessType
  );

  const initials = getInitials(
    business.name
  );

  /*
   * TENANT BRANDING FALLBACK
   *
   * Backend logo tetap menjadi prioritas.
   * Fallback Sauri hanya aktif untuk tenant
   * Fresh Market Unggas & Animal Petfood Indonesia.
   */
  const businessNameForBranding =
    String(business.name || "")
      .trim()
      .toLowerCase();

  const isSauriTenant =
    businessNameForBranding.includes(
      "fresh market unggas"
    ) ||
    businessNameForBranding.includes(
      "animal petfood"
    ) ||
    businessNameForBranding.includes(
      "sauri"
    );

  const cardLogo =
    business.logoUrl ||
    (isSauriTenant
      ? "/sauri/logo.png"
      : null);

  const cardVisual =
    isSauriTenant
      ? "/sauri/poultry-processing-facility.png"
      : null;

  return (
    <article
      className="
        group relative overflow-hidden
        rounded-[28px]
        border border-black/[0.08]
        bg-white
        shadow-[0_8px_30px_rgba(0,0,0,0.06)]
        transition-all duration-300
        hover:-translate-y-1
        hover:border-[#e5232e]/20
        hover:shadow-[0_20px_50px_rgba(229,35,46,0.14)]
      "
    >
      {/* TOP RED ACCENT */}
      <div className="h-1.5 w-full bg-[#e5232e]" />

      {/* SUBTLE RED GLOW */}
      <div
        className="
          pointer-events-none absolute
          -right-16 -top-16
          size-36 rounded-full
          bg-[#e5232e]/[0.06]
          blur-2xl
          transition-all duration-500
          group-hover:bg-[#e5232e]/[0.12]
        "
      />

      <div className="relative p-5">
        {/* ==================================================
            HEADER
            ================================================== */}
        <div className="flex items-start justify-between gap-4">
          <div className="flex min-w-0 items-center gap-3.5">
            {/* LOGO */}
            <div
              className="
                relative grid size-16 shrink-0
                overflow-hidden rounded-[20px]
                border border-[#e5232e]/10
                bg-gradient-to-br from-[#fff1f2] to-white
                shadow-sm
              "
            >
              {cardLogo ? (
                <img
                  src={cardLogo}
                  alt={`${business.name} logo`}
                  className="
                    h-full w-full object-contain
                    p-1
                    transition-transform duration-300
                    group-hover:scale-105
                  "
                />
              ) : (
                <div className="grid h-full w-full place-items-center">
                  <span className="text-lg font-black tracking-tight text-[#e5232e]">
                    {initials}
                  </span>
                </div>
              )}

              {/* LOGO CORNER MARK */}
              <div className="pointer-events-none absolute bottom-0 right-0 rounded-tl-lg bg-[#e5232e] px-1.5 py-1">
                <span className="block size-1.5 rounded-full bg-white" />
              </div>
            </div>

            {/* BUSINESS NAME */}
            <div className="min-w-0">
              <div className="mb-1 flex items-center gap-1.5">
                <TypeIcon
                  size={13}
                  className="shrink-0 text-[#e5232e]"
                />

                <span className="text-[9px] font-black uppercase tracking-[0.18em] text-[#e5232e]">
                  {typeLabel}
                </span>
              </div>

              <h3
                className="
                  line-clamp-2
                  font-black leading-tight
                  tracking-tight text-[#17191d]
                  transition-colors
                  group-hover:text-[#e5232e]
                "
              >
                {business.name}
              </h3>

              {business.category && (
                <p className="mt-1 line-clamp-1 text-xs text-[#7d8590]">
                  {business.category}
                </p>
              )}
            </div>
          </div>

          {/* PRIORITY */}
          {business.prioritySearch && (
            <span
              className="
                shrink-0 rounded-full
                border border-[#e5232e]/15
                bg-[#fff1f2]
                px-2.5 py-1.5
                text-[8px] font-black
                tracking-[0.12em]
                text-[#e5232e]
              "
            >
              PRIORITY
            </span>
          )}
        </div>

        {/* ==================================================
            VERIFICATION
            ================================================== */}
        <div className="mt-5 flex flex-wrap gap-2">
          {verified ? (
            <span
              className="
                flex items-center gap-1.5
                rounded-full
                border border-green-200
                bg-green-50
                px-2.5 py-1.5
                text-[9px] font-black
                tracking-wide text-green-700
              "
            >
              <ShieldCheck size={12} />
              NUSA-DHIPA VERIFIED
            </span>
          ) : (
            <span
              className="
                flex items-center gap-1.5
                rounded-full
                border border-gray-200
                bg-gray-50
                px-2.5 py-1.5
                text-[9px] font-black
                tracking-wide text-gray-600
              "
            >
              <ShieldCheck size={12} />
              BELUM TERVERIFIKASI
            </span>
          )}

          <span
            className={`
              flex items-center gap-1.5
              rounded-full border
              px-2.5 py-1.5
              text-[9px] font-black
              tracking-wide
              ${legalTone(business.legalStatus)}
            `}
          >
            <FileCheck2 size={12} />
            {legalLabel(business.legalStatus)}
          </span>
        </div>

        {/* ==================================================
            PRODUCT / BUSINESS VISUAL
            ================================================== */}

        {cardVisual && (
          <div
            className="
              mt-5
              overflow-hidden
              rounded-2xl
              border border-[#e5232e]/10
              bg-[#fff5f5]
            "
          >
            <div className="relative h-40 w-full">
              <img
                src={cardVisual}
                alt={`${business.name} product visual`}
                className="
                  h-full w-full object-cover
                  transition-transform duration-500
                  group-hover:scale-[1.03]
                "
              />

              <div
                className="
                  pointer-events-none
                  absolute inset-0
                  bg-gradient-to-t
                  from-black/35
                  via-transparent
                  to-transparent
                "
              />

              <div className="absolute bottom-3 left-3">
                <span
                  className="
                    rounded-full
                    bg-white/95
                    px-2.5 py-1
                    text-[8px]
                    font-black
                    uppercase
                    tracking-[0.14em]
                    text-[#e5232e]
                    shadow-sm
                  "
                >
                  PRODUK & USAHA
                </span>
              </div>
            </div>
          </div>
        )}

        {/* ==================================================
            LOCATION
            ================================================== */}
        <div className="mt-5 rounded-2xl bg-[#f8f8f8] p-3.5">
          <div className="flex items-start gap-2.5">
            <div
              className="
                grid size-7 shrink-0
                place-items-center
                rounded-lg
                bg-white
                text-[#e5232e]
                shadow-sm
              "
            >
              <MapPin size={14} />
            </div>

            <div className="min-w-0">
              <div className="text-[8px] font-black uppercase tracking-[0.16em] text-[#a0a5ac]">
                Lokasi Usaha
              </div>

              <p className="mt-0.5 text-xs leading-5 text-[#626a74]">
                {business.location}
                {business.distanceKm != null && (
                  <span className="font-bold text-[#e5232e]">
                    {" "}
                    • {business.distanceKm.toFixed(1)} km
                  </span>
                )}
              </p>
            </div>
          </div>
        </div>

        {/* ==================================================
            ACTIVITY
            ================================================== */}
        {business.activity && (
          <div className="mt-4">
            <p className="line-clamp-2 text-[11px] leading-5 text-[#737b86]">
              {business.activity}
            </p>
          </div>
        )}

        {/* ==================================================
            METRICS
            ================================================== */}
        {(business.freshnessMinutes !== undefined ||
          business.rating !== undefined) && (
          <div className="mt-4 flex items-center gap-4 border-t border-black/[0.06] pt-4">
            {business.freshnessMinutes !== undefined && (
              <div className="flex items-center gap-1.5">
                <Zap
                  size={13}
                  className="text-[#e5232e]"
                />

                <span className="text-[10px] font-semibold text-[#737b86]">
                  Update{" "}
                  <strong className="text-[#444b55]">
                    {business.freshnessMinutes}
                  </strong>{" "}
                  menit lalu
                </span>
              </div>
            )}

            {business.rating !== undefined && (
              <div className="ml-auto flex items-center gap-1.5">
                <Star
                  size={14}
                  className="fill-current text-amber-400"
                />

                <span className="text-xs font-black text-[#444b55]">
                  {business.rating.toFixed(1)}
                </span>
              </div>
            )}
          </div>
        )}

        {/* ==================================================
            VERIFICATION CTA
            ================================================== */}
        {verified &&
          business.verification?.public_url && (
            <a
              href={
                business.verification.public_url
              }
              target="_blank"
              rel="noreferrer"
              className="
                mt-5 flex w-full items-center
                justify-center gap-2
                rounded-xl
                border border-green-200
                bg-green-50
                py-2.5
                text-[10px] font-black
                tracking-wide text-green-700
                transition-all duration-200
                hover:bg-green-100
                hover:shadow-sm
              "
            >
              <CheckCircle2 size={14} />
              LIHAT VERIFIKASI
            </a>
          )}

        {/* ==================================================
            PRIMARY CTA
            ================================================== */}
        <Link
          href={`/marketplace/business/${business.id}`}
          className="
            mt-3 flex w-full items-center
            justify-center gap-2
            rounded-xl
            bg-[#17191d]
            py-3.5
            text-xs font-black
            tracking-wide text-white
            shadow-sm
            transition-all duration-200
            hover:bg-[#e5232e]
            hover:shadow-[0_10px_25px_rgba(229,35,46,0.22)]
          "
        >
          {detailLabel(business.businessType)}

          <ArrowRight
            size={15}
            className="
              transition-transform duration-200
              group-hover:translate-x-0.5
            "
          />
        </Link>

        {/* BRAND FOOTER */}
        <div className="mt-4 flex items-center justify-center gap-2">
          <div className="h-px flex-1 bg-black/[0.06]" />

          <span className="text-[8px] font-black tracking-[0.2em] text-black/20">
            NUSA-DHIPA
          </span>

          <div className="h-px flex-1 bg-black/[0.06]" />
        </div>
      </div>
    </article>
  );
}


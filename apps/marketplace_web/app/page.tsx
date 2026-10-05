import Header from "@/components/layout/Header";
import SearchHero from "@/components/marketplace/SearchHero";
import BusinessCard from "@/components/business/BusinessCard";
import {
  ArrowRight,
  CheckCircle2,
  Store,
  Users,
} from "lucide-react";
import { getMarketplaceBusinesses } from "@/lib/api";

export default async function MarketplacePage() {
  const businesses = await getMarketplaceBusinesses();

  return (
    <div className="min-h-screen bg-[#f7f8fa]">
      <Header />

      <main>
        <SearchHero />

        {/* ==================================================
            VALUE STRIP
            ================================================== */}
        <section className="border-b border-[#e7e9ed] bg-white">
          <div className="container grid divide-y divide-[#edf0f2] py-2 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
            <ValueItem
              icon={<Store size={18} />}
              title="UMKM"
              text="Temukan usaha dan layanan yang tersedia."
            />

            <ValueItem
              icon={<CheckCircle2 size={18} />}
              title="Informasi Terstruktur"
              text="Profil usaha ditampilkan berdasarkan data bisnis."
            />

            <ValueItem
              icon={<Users size={18} />}
              title="Ekosistem Usaha"
              text="Hubungkan produk, layanan, dan kebutuhan usaha."
            />
          </div>
        </section>

        {/* ==================================================
            BUSINESS DIRECTORY
            ================================================== */}
        <section
          id="umkm"
          className="bg-white py-14 sm:py-18"
        >
          <div className="container">
            <SectionHeading
              label="Marketplace"
              title="Pelaku Usaha"
              description="Temukan produk, layanan, dan berbagai jenis usaha yang tersedia di NUSA-DHIPA."
              action="Lihat Semua"
            />

            {businesses.length > 0 ? (
              <div className="mt-7 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
                {businesses.map((business) => (
                  <BusinessCard
                    key={business.id}
                    business={business}
                  />
                ))}
              </div>
            ) : (
              <EmptyState />
            )}
          </div>
        </section>

        {/* ==================================================
            ECOSYSTEM CTA
            ================================================== */}
        <section
          id="peluang"
          className="border-y border-[#e7e9ed] bg-[#f7f8fa] py-14 sm:py-18"
        >
          <div className="container">
            <div className="rounded-[28px] border border-[#e5e8ec] bg-white p-7 sm:p-10">
              <div className="max-w-2xl">
                <div className="nd-section-label">
                  Ekosistem NUSA-DHIPA
                </div>

                <h2 className="mt-2 text-2xl font-black tracking-tight text-[#17191d] sm:text-3xl">
                  Temukan produk, layanan, dan mitra usaha.
                </h2>

                <p className="mt-3 text-sm leading-7 text-[#747c87]">
                  Marketplace NUSA-DHIPA dirancang untuk berbagai jenis
                  UMKM. Produk dan layanan ditampilkan berdasarkan profil
                  usaha, katalog, KBLI, dan capability yang tersedia.
                </p>

                <a
                  href="/search"
                  className="mt-6 inline-flex min-h-[46px] items-center gap-2 rounded-xl bg-[#e5232e] px-6 py-3 text-sm font-extrabold text-white transition hover:bg-[#c91621]"
                >
                  Jelajahi Marketplace
                  <ArrowRight size={16} />
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* ==================================================
            FINAL CTA
            ================================================== */}
        <section className="bg-white py-16 sm:py-20">
          <div className="container">
            <div className="relative overflow-hidden rounded-[30px] bg-[#17191d] px-6 py-12 text-center text-white sm:px-12 sm:py-16">
              <div className="absolute -right-24 -top-28 size-72 rounded-full bg-[#e5232e]/30 blur-3xl" />

              <div className="absolute -bottom-28 -left-24 size-72 rounded-full bg-white/5 blur-3xl" />

              <div className="relative mx-auto max-w-3xl">
                <div className="text-[10px] font-extrabold uppercase tracking-[0.22em] text-white/45">
                  NUSA-DHIPA
                </div>

                <h2 className="mt-3 text-3xl font-black tracking-tight sm:text-5xl">
                  Cari barang.
                  <br className="sm:hidden" />
                  Cari layanan.
                  <br className="sm:hidden" />
                  Temukan pasar.
                </h2>

                <p className="mx-auto mt-5 max-w-xl text-sm leading-7 text-white/60 sm:text-base">
                  Satu marketplace untuk menemukan produk, layanan,
                  dan pelaku usaha dari berbagai kategori bisnis.
                </p>

                <div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
                  <a
                    href="/search"
                    className="inline-flex min-h-[48px] items-center justify-center gap-2 rounded-xl bg-[#e5232e] px-7 py-3 text-sm font-extrabold text-white transition hover:bg-[#c91621]"
                  >
                    Mulai Cari
                    <ArrowRight size={16} />
                  </a>

                  <a
                    href="#umkm"
                    className="inline-flex min-h-[48px] items-center justify-center gap-2 rounded-xl border border-white/20 px-7 py-3 text-sm font-extrabold text-white transition hover:bg-white/10"
                  >
                    <Store size={16} />
                    Lihat UMKM
                  </a>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* ====================================================
          FOOTER
          ==================================================== */}
      <footer className="border-t border-[#e7e9ed] bg-white">
        <div className="container grid gap-8 py-10 sm:grid-cols-2 lg:grid-cols-4">
          <div className="sm:col-span-2">
            <ImageLogo />

            <p className="mt-4 max-w-md text-sm leading-6 text-[#7b838e]">
              Ekosistem digital untuk membantu masyarakat menemukan
              produk, layanan, pelaku usaha, dan pasar dalam satu
              platform.
            </p>
          </div>

          <div>
            <div className="text-xs font-black uppercase tracking-[0.15em] text-[#30353c]">
              Marketplace
            </div>

            <div className="mt-4 space-y-3 text-sm text-[#737b86]">
              <a href="/search" className="nd-link block">
                Cari Marketplace
              </a>

              <a href="#umkm" className="nd-link block">
                Pelaku Usaha
              </a>

              <a href="#peluang" className="nd-link block">
                Ekosistem Usaha
              </a>
            </div>
          </div>

          <div>
            <div className="text-xs font-black uppercase tracking-[0.15em] text-[#30353c]">
              Untuk UMKM
            </div>

            <div className="mt-4 space-y-3 text-sm text-[#737b86]">
              <a href="#" className="nd-link block">
                Punya Usaha?
              </a>

              <a href="#" className="nd-link block">
                Kelola Usaha
              </a>

              <a href="#" className="nd-link block">
                Bantuan
              </a>
            </div>
          </div>
        </div>

        <div className="border-t border-[#eef0f2] py-4">
          <div className="container flex flex-col justify-between gap-2 text-[10px] text-[#a0a6af] sm:flex-row">
            <span>© NUSA-DHIPA</span>
            <span>Ekosistem Digital UMKM</span>
          </div>
        </div>
      </footer>
    </div>
  );
}

function ImageLogo() {
  return (
    <div className="w-fit">
      <img
        src="/logo.png"
        alt="NUSA-DHIPA"
        className="h-auto w-[175px] object-contain object-left"
      />
    </div>
  );
}

function ValueItem({
  icon,
  title,
  text,
}: {
  icon: React.ReactNode;
  title: string;
  text: string;
}) {
  return (
    <div className="flex items-center gap-3 px-2 py-4 sm:px-5">
      <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
        {icon}
      </div>

      <div>
        <div className="text-xs font-black text-[#30353c]">
          {title}
        </div>

        <div className="mt-0.5 text-[11px] text-[#8b929c]">
          {text}
        </div>
      </div>
    </div>
  );
}

function SectionHeading({
  label,
  title,
  description,
  action,
}: {
  label: string;
  title: string;
  description: string;
  action?: string;
}) {
  return (
    <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
      <div className="max-w-2xl">
        <div className="nd-section-label">
          {label}
        </div>

        <h2 className="mt-2 text-2xl font-black tracking-tight text-[#17191d] sm:text-3xl">
          {title}
        </h2>

        <p className="mt-2 text-sm leading-6 text-[#747c87]">
          {description}
        </p>
      </div>

      {action && (
        <a
          href="/search"
          className="flex min-h-[44px] items-center gap-2 self-start text-sm font-extrabold text-[#e5232e] sm:self-auto"
        >
          {action}
          <ArrowRight size={16} />
        </a>
      )}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="mt-7 rounded-2xl border border-dashed border-[#dfe3e8] bg-[#f8f9fb] px-6 py-12 text-center">
      <Store className="mx-auto text-[#a0a6af]" size={32} />

      <h3 className="mt-4 text-base font-black text-[#30353c]">
        Belum ada pelaku usaha
      </h3>

      <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#7b838e]">
        Belum ada data usaha yang tersedia di marketplace saat ini.
      </p>
    </div>
  );
}

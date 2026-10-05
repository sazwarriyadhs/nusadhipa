"use client";

import {
  ArrowRight,
  Boxes,
  Building2,
  CheckCircle2,
  ChevronRight,
  FileCheck2,
  Globe2,
  LineChart,
  Search,
  ShoppingBag,
  Store,
  TrendingUp
} from "lucide-react";

import Header from "@/components/Header";

const marketplaceUrl =
  process.env.NEXT_PUBLIC_MARKETPLACE_URL ?? "http://localhost:3004";

const businessUrl =
  process.env.NEXT_PUBLIC_BUSINESS_URL ?? "http://localhost:3002";

export default function HomePage() {
  return (
    <>
      <Header />

      <main>
        {/* ================================================= */}
        {/* HERO */}
        {/* ================================================= */}

        <section className="relative overflow-hidden bg-cover bg-center" style={{ backgroundImage: "url('/header.jpg')" }}
      >
        <div className="absolute inset-0 bg-black/55" />
          <div className="pointer-events-none absolute -right-40 -top-40 size-[520px] rounded-full bg-[#fff1f2] blur-3xl" />
          <div className="pointer-events-none absolute -bottom-40 -left-40 size-[420px] rounded-full bg-[#f8f9fb] blur-3xl" />

          <div className="container relative grid min-h-[calc(100vh-72px)] items-center gap-12 py-16 lg:grid-cols-[1.05fr_.95fr] lg:py-24">
            <div>
              <div className="nd-section-label mb-5">
                Ekosistem Digital UMKM
              </div>

              <h1 className="max-w-4xl font-black leading-[.95] tracking-[-.065em] text-5xl sm:text-6xl lg:text-7xl xl:text-8xl text-white">
                Bangun bisnis.
                <br />
                <span className="text-[#e5232e]">
                  Tumbuh lebih jauh.
                </span>
              </h1>

              <p className="mt-7 max-w-2xl text-base leading-7 text-white/90 sm:text-lg">
                NUSA-DHIPA menghubungkan legalitas, operasional bisnis,
                katalog, inventory, dan marketplace dalam satu ekosistem
                digital untuk UMKM Indonesia.
              </p>

              <div className="mt-9 flex flex-wrap gap-3">
                <a
                  href="/legalitas"
                  className="inline-flex h-12 items-center gap-3 rounded-xl bg-[#e5232e] px-5 text-sm font-extrabold text-white shadow-sm transition hover:bg-[#c91621]"
                >
                  Mulai Bangun Bisnis
                  <ArrowRight size={17} />
                </a>

                <a
                  href={marketplaceUrl}
                  className="inline-flex h-12 items-center gap-3 rounded-xl border border-[#e1e4e8] bg-white px-5 text-sm font-extrabold text-[#30353c] transition hover:border-[#e5232e] hover:text-[#e5232e]"
                >
                  Jelajahi Marketplace
                  <ShoppingBag size={17} />
                </a>
              </div>

              <div className="mt-10 flex flex-wrap gap-x-7 gap-y-3 text-xs font-bold text-[#7c848f]">
                <span className="flex items-center gap-2">
                  <CheckCircle2 size={15} className="text-[#e5232e]" />
                  Business-ready
                </span>

                <span className="flex items-center gap-2">
                  <CheckCircle2 size={15} className="text-[#e5232e]" />
                  Data terpusat
                </span>

                <span className="flex items-center gap-2">
                  <CheckCircle2 size={15} className="text-[#e5232e]" />
                  Marketplace connected
                </span>
              </div>
            </div>

            <div className="relative mx-auto w-full max-w-[540px]">
              <div className="absolute inset-8 rounded-[40px] bg-[#fff1f2] blur-3xl" />

              <div className="relative rounded-[28px] border border-[#e7e9ed] bg-white p-4 shadow-[0_25px_80px_rgba(16,24,40,.10)] sm:p-6">
                <div className="rounded-[22px] bg-[#f7f8fa] p-5 sm:p-7">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-[10px] font-extrabold uppercase tracking-[.18em] text-[#a0a6af]">
                        BUSINESS OS
                      </div>
                      <div className="mt-1 text-xl font-black text-[#202329]">
                        Bisnis Anda
                      </div>
                    </div>

                    <div className="grid size-11 place-items-center rounded-xl bg-white text-[#e5232e] shadow-sm">
                      <Building2 size={21} />
                    </div>
                  </div>

                  <div className="mt-7 grid grid-cols-2 gap-3">
                    <DashboardCard
                      icon={<Boxes size={19} />}
                      label="Inventory"
                      value="Aktif"
                    />

                    <DashboardCard
                      icon={<Store size={19} />}
                      label="Marketplace"
                      value="Connected"
                    />

                    <DashboardCard
                      icon={<FileCheck2 size={19} />}
                      label="Legalitas"
                      value="Ready"
                    />

                    <DashboardCard
                      icon={<TrendingUp size={19} />}
                      label="Growth"
                      value="+"
                    />
                  </div>

                  <div className="mt-3 rounded-2xl bg-white p-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-[#68707d]">
                        Business ecosystem
                      </span>

                      <span className="text-[10px] font-black text-[#e5232e]">
                        LIVE
                      </span>
                    </div>

                    <div className="mt-4 flex items-center gap-2">
                      <ProgressDot active />
                      <ProgressLine />
                      <ProgressDot active />
                      <ProgressLine />
                      <ProgressDot active />
                    </div>

                    <div className="mt-3 flex justify-between text-[9px] font-bold text-[#a0a6af]">
                      <span>LEGAL</span>
                      <span>MANAGE</span>
                      <span>SELL</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="absolute -bottom-5 -left-4 hidden rounded-2xl border border-[#e7e9ed] bg-white p-3 shadow-xl sm:flex sm:items-center sm:gap-3">
                <div className="grid size-10 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
                  <LineChart size={18} />
                </div>

                <div>
                  <div className="text-[9px] font-extrabold uppercase tracking-wider text-[#a0a6af]">
                    Connected
                  </div>
                  <div className="text-xs font-black text-[#202329]">
                    One Business Ecosystem
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* ECOSYSTEM */}
        {/* ================================================= */}

        <section id="ekosistem" className="bg-[#f7f8fa] py-24 sm:py-32">
          <div className="container">
            <div className="max-w-2xl">
              <div className="nd-section-label">
                Satu Ekosistem
              </div>

              <h2 className="mt-4 text-4xl font-black tracking-[-.045em] text-[#17191d] sm:text-6xl">
                Dari ide menjadi
                <span className="text-[#e5232e]"> bisnis nyata.</span>
              </h2>

              <p className="mt-5 max-w-xl text-sm leading-7 text-[#68707d] sm:text-base">
                NUSA-DHIPA menyatukan kebutuhan utama bisnis agar Anda
                tidak perlu membangun semuanya dari nol.
              </p>
            </div>

            <div className="mt-14 grid gap-5 md:grid-cols-3">
              <EcosystemCard
                number="01"
                icon={<FileCheck2 size={23} />}
                title="Legalitas"
                description="Bangun fondasi bisnis dengan proses legalitas yang lebih terstruktur."
              />

              <EcosystemCard
                number="02"
                icon={<Building2 size={23} />}
                title="Business OS"
                description="Kelola bisnis, katalog, inventory, dan operasional dari satu sistem."
                featured
              />

              <EcosystemCard
                number="03"
                icon={<ShoppingBag size={23} />}
                title="Marketplace"
                description="Hubungkan bisnis Anda dengan pelanggan dan peluang pasar."
              />
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* SOLUTIONS */}
        {/* ================================================= */}

        <section id="solusi" className="bg-white py-24 sm:py-32">
          <div className="container">
            <div className="grid gap-14 lg:grid-cols-[.85fr_1.15fr] lg:items-end">
              <div>
                <div className="nd-section-label">
                  Solusi Bisnis
                </div>

                <h2 className="mt-4 text-4xl font-black tracking-[-.045em] text-[#17191d] sm:text-6xl">
                  Sederhana untuk digunakan.
                  <br />
                  <span className="text-[#e5232e]">
                    Siap untuk berkembang.
                  </span>
                </h2>
              </div>

              <p className="max-w-xl text-sm leading-7 text-[#68707d] sm:text-base lg:ml-auto">
                Setiap bagian NUSA-DHIPA dirancang untuk menyelesaikan
                kebutuhan bisnis yang nyata — bukan sekadar menambah
                aplikasi baru.
              </p>
            </div>

            <div className="mt-14 grid gap-5 sm:grid-cols-2">
              <FeatureCard
                icon={<Building2 size={21} />}
                title="Business Management"
                description="Data bisnis terpusat untuk membantu operasional berjalan lebih rapi."
              />

              <FeatureCard
                icon={<Boxes size={21} />}
                title="Catalog & Inventory"
                description="Kelola produk dan stok dengan data yang konsisten."
              />

              <FeatureCard
                icon={<ShoppingBag size={21} />}
                title="Digital Commerce"
                description="Tampilkan produk dan terhubung dengan kanal marketplace."
              />

              <FeatureCard
                icon={<LineChart size={21} />}
                title="Business Intelligence"
                description="Gunakan data bisnis untuk memahami performa dan peluang."
              />
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* MARKETPLACE */}
        {/* ================================================= */}

        <section className="overflow-hidden bg-[#17191d] py-24 text-white sm:py-32">
          <div className="container grid gap-14 lg:grid-cols-[1fr_.9fr] lg:items-center">
            <div>
              <div className="text-[11px] font-extrabold uppercase tracking-[.18em] text-[#ff7b82]">
                NUSA-DHIPA Marketplace
              </div>

              <h2 className="mt-5 max-w-2xl text-4xl font-black tracking-[-.05em] sm:text-6xl">
                Bisnis lokal.
                <br />
                <span className="text-[#e5232e]">
                  Jangkauan lebih luas.
                </span>
              </h2>

              <p className="mt-6 max-w-xl text-sm leading-7 text-[#aeb4bd] sm:text-base">
                Temukan produk dari bisnis lokal, lihat katalog,
                dan hubungkan supply dengan demand dalam satu marketplace.
              </p>

              <a
                href={marketplaceUrl}
                className="mt-8 inline-flex h-12 items-center gap-3 rounded-xl bg-[#e5232e] px-5 text-sm font-extrabold text-white transition hover:bg-[#c91621]"
              >
                Jelajahi Marketplace
                <ArrowRight size={17} />
              </a>
            </div>

            <div className="relative">
              <div className="absolute -inset-10 rounded-full bg-[#e5232e]/10 blur-3xl" />

              <div className="relative rounded-[26px] border border-white/10 bg-white/[.05] p-4 backdrop-blur-xl">
                <div className="rounded-[20px] bg-white p-5 text-[#202329]">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-[9px] font-extrabold uppercase tracking-[.18em] text-[#a0a6af]">
                        MARKETPLACE
                      </div>
                      <div className="mt-1 text-lg font-black">
                        Temukan Bisnis
                      </div>
                    </div>

                    <div className="grid size-10 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
                      <Search size={18} />
                    </div>
                  </div>

                  <div className="mt-5 rounded-2xl border border-[#e7e9ed] p-4">
                    <div className="flex items-center gap-3">
                      <div className="grid size-11 place-items-center rounded-xl bg-[#fff1f2] text-sm font-black text-[#e5232e]">
                        UM
                      </div>

                      <div className="min-w-0">
                        <div className="truncate text-sm font-black">
                          Usaha Anda
                        </div>
                        <div className="mt-1 text-[10px] text-[#68707d]">
                          Produk & layanan dari berbagai bidang usaha
                        </div>
                      </div>

                      <div className="ml-auto rounded-full bg-[#eefaf0] px-2 py-1 text-[8px] font-black text-[#27833f]">
                        AKTIF
                      </div>
                    </div>
                  </div>
                  <div className="mt-3 grid grid-cols-3 gap-2">
                    <MiniProduct label="Produk" />
                    <MiniProduct label="Layanan" />
                    <MiniProduct label="Usaha" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* LEGAL */}
        {/* ================================================= */}

        <section className="bg-[#f7f8fa] py-24 sm:py-32">
          <div className="container">
            <div className="nd-card overflow-hidden">
              <div className="grid lg:grid-cols-[1fr_.75fr]">
                <div className="p-7 sm:p-12">
                  <div className="nd-section-label">
                    Business Foundation
                  </div>

                  <h2 className="mt-4 text-4xl font-black tracking-[-.045em] text-[#17191d] sm:text-5xl">
                    Mulai dari fondasi
                    <span className="text-[#e5232e]">
                      {" "}yang benar.
                    </span>
                  </h2>

                  <p className="mt-5 max-w-xl text-sm leading-7 text-[#68707d]">
                    Legalitas, data bisnis, dan struktur operasional
                    menjadi fondasi sebelum bisnis berkembang lebih jauh.
                  </p>

                  <div className="mt-8 space-y-4">
                    <CheckRow text="Struktur bisnis lebih terorganisir" />
                    <CheckRow text="Data usaha terpusat" />
                    <CheckRow text="Siap terhubung ke ekosistem digital" />
                  </div>

                  <a
                    href={businessUrl}
                    className="mt-9 inline-flex items-center gap-2 text-sm font-extrabold text-[#e5232e] hover:text-[#c91621]"
                  >
                    Mulai membangun bisnis
                    <ArrowRight size={16} />
                  </a>
                </div>

                <div className="relative flex min-h-[300px] items-center justify-center overflow-hidden bg-[#17191d] p-8">
                  <div className="absolute size-64 rounded-full bg-[#e5232e]/20 blur-3xl" />

                  <div className="relative grid size-48 place-items-center rounded-full border border-white/10 bg-white/[.04]">
                    <div className="grid size-28 place-items-center rounded-full border border-[#e5232e]/50 bg-[#e5232e]/10">
                      <Globe2 size={38} className="text-[#ff7b82]" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* CTA */}
        {/* ================================================= */}

        <section className="bg-white py-24 sm:py-32">
          <div className="container">
            <div className="relative overflow-hidden rounded-[28px] bg-[#e5232e] px-7 py-14 text-center text-white sm:px-12 sm:py-20">
              <div className="pointer-events-none absolute -right-24 -top-24 size-72 rounded-full bg-white/10 blur-3xl" />
              <div className="pointer-events-none absolute -bottom-24 -left-24 size-72 rounded-full bg-black/10 blur-3xl" />

              <div className="relative">
                <div className="text-[10px] font-extrabold uppercase tracking-[.22em] text-white/70">
                  Ready to grow
                </div>

                <h2 className="mx-auto mt-4 max-w-4xl text-4xl font-black tracking-[-.05em] sm:text-6xl">
                  Punya usaha?
                  <br />
                  Bangun ekosistemnya bersama NUSA-DHIPA.
                </h2>

                <p className="mx-auto mt-5 max-w-xl text-sm leading-7 text-white/80">
                  Kelola bisnis Anda, tampil di marketplace, dan
                  kembangkan peluang baru dari satu ekosistem.
                </p>

                <div className="mt-8 flex flex-wrap justify-center gap-3">
                  <a
                    href="/legalitas"
                    className="inline-flex h-12 items-center gap-3 rounded-xl bg-white px-5 text-sm font-extrabold text-[#c91621] transition hover:bg-[#fff1f2]"
                  >
                    Mulai Sekarang
                    <ArrowRight size={17} />
                  </a>

                  <a
                    href={marketplaceUrl}
                    className="inline-flex h-12 items-center gap-3 rounded-xl border border-white/30 px-5 text-sm font-extrabold text-white transition hover:bg-white/10"
                  >
                    Lihat Marketplace
                    <ShoppingBag size={17} />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* =================================================== */}
      {/* FOOTER */}
      {/* =================================================== */}

      <footer className="border-t border-[#e7e9ed] bg-white">
        <div className="container flex flex-col gap-6 py-10 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <div className="text-sm font-black tracking-[.12em] text-[#202329]">
              NUSA-DHIPA
            </div>

            <div className="mt-1 text-[10px] font-bold uppercase tracking-[.16em] text-[#a0a6af]">
              Ekosistem Digital UMKM
            </div>
          </div>

          <div className="flex flex-wrap gap-5 text-xs font-bold text-[#68707d]">
            <a
              href="#ekosistem"
              className="nd-link"
            >
              Ekosistem
            </a>

            <a
              href="#solusi"
              className="nd-link"
            >
              Solusi
            </a>

            <a
              href={marketplaceUrl}
              className="nd-link"
            >
              Marketplace
            </a>

            <a
              href={businessUrl}
              className="nd-link"
            >
              Punya Usaha?
            </a>
          </div>

          <div className="text-[10px] text-[#a0a6af]">
            © 2026 NUSA-DHIPA
          </div>
        </div>
      </footer>
    </>
  );
}

function DashboardCard({
  icon,
  label,
  value
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl border border-[#e7e9ed] bg-white p-4">
      <div className="text-[#e5232e]">
        {icon}
      </div>

      <div className="mt-4 text-[10px] font-bold text-[#a0a6af]">
        {label}
      </div>

      <div className="mt-1 text-sm font-black text-[#202329]">
        {value}
      </div>
    </div>
  );
}

function ProgressDot({
  active
}: {
  active?: boolean;
}) {
  return (
    <div
      className={[
        "size-2 rounded-full",
        active ? "bg-[#e5232e]" : "bg-[#dfe2e6]"
      ].join(" ")}
    />
  );
}

function ProgressLine() {
  return (
    <div className="h-px flex-1 bg-[#e5232e]" />
  );
}

function EcosystemCard({
  number,
  icon,
  title,
  description,
  featured = false
}: {
  number: string;
  icon: React.ReactNode;
  title: string;
  description: string;
  featured?: boolean;
}) {
  return (
    <article
      className={[
        "nd-card nd-card-hover relative overflow-hidden p-7 sm:p-8",
        featured ? "border-[#f1c1c4]" : ""
      ].join(" ")}
    >
      {featured && (
        <div className="absolute right-5 top-5 rounded-full bg-[#fff1f2] px-2.5 py-1 text-[8px] font-black uppercase tracking-wider text-[#e5232e]">
          Core
        </div>
      )}

      <div className="text-[10px] font-extrabold text-[#a0a6af]">
        {number}
      </div>

      <div className="mt-12 grid size-12 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
        {icon}
      </div>

      <h3 className="mt-6 text-xl font-black text-[#202329]">
        {title}
      </h3>

      <p className="mt-3 text-sm leading-6 text-[#68707d]">
        {description}
      </p>

      <div className="mt-7 flex items-center gap-1 text-xs font-extrabold text-[#e5232e]">
        Explore
        <ChevronRight size={15} />
      </div>
    </article>
  );
}

function FeatureCard({
  icon,
  title,
  description
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <article className="nd-card nd-card-hover flex gap-5 p-6 sm:p-7">
      <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
        {icon}
      </div>

      <div>
        <h3 className="font-black text-[#202329]">
          {title}
        </h3>

        <p className="mt-2 text-sm leading-6 text-[#68707d]">
          {description}
        </p>
      </div>
    </article>
  );
}

function CheckRow({
  text
}: {
  text: string;
}) {
  return (
    <div className="flex items-center gap-3 text-sm font-bold text-[#535b66]">
      <CheckCircle2
        size={18}
        className="shrink-0 text-[#e5232e]"
      />
      {text}
    </div>
  );
}

function MiniProduct({
  label
}: {
  label: string;
}) {
  return (
    <div className="rounded-xl bg-[#f7f8fa] p-3 text-center">
      <div className="mx-auto grid size-8 place-items-center rounded-lg bg-white text-[8px] font-black text-[#e5232e] shadow-sm">
        +
      </div>

      <div className="mt-2 text-[9px] font-bold text-[#68707d]">
        {label}
      </div>
    </div>
  );
}















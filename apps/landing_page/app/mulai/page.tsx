"use client";

import {
  ArrowRight,
  Building2,
  CheckCircle2,
  FileCheck2,
  Handshake,
  Search,
  ShoppingBag,
} from "lucide-react";

import Header from "@/components/Header";

const marketplaceUrl =
  process.env.NEXT_PUBLIC_MARKETPLACE_URL ?? "http://localhost:3004";

const startingPoints = [
  {
    number: "01",
    icon: Building2,
    title: "Baru Mulai Usaha",
    description:
      "Belum punya bisnis? Ceritakan usaha yang ingin Anda bangun. NUSA-DHIPA membantu menyusun profil usaha, aktivitas, dan langkah berikutnya.",
    href: "/business-os",
    action: "Mulai dari Awal",
  },
  {
    number: "02",
    icon: ShoppingBag,
    title: "Sudah Punya Usaha",
    description:
      "Sudah berjualan atau menyediakan jasa? Daftarkan usaha Anda, tampilkan produk atau layanan, dan mulai masuk marketplace.",
    href: "/mulai/marketplace",
    action: "Daftarkan Usaha",
  },
  {
    number: "03",
    icon: FileCheck2,
    title: "Sudah Punya Legalitas",
    description:
      "Sudah memiliki NIB, KBLI, AHU, atau badan usaha? Verifikasi data Anda lalu lanjutkan ke marketplace dan Business OS.",
    href: "/legalitas",
    action: "Verifikasi Usaha",
  },
  {
    number: "04",
    icon: Handshake,
    title: "Cari Partner",
    description:
      "Temukan mitra usaha, pemasok, pelanggan, dan peluang partnership melalui ekosistem NUSA-DHIPA.",
    href: marketplaceUrl + "?intent=PARTNERSHIP",
    action: "Cari Partner",
  },
];

function StartingPointCard({
  number,
  icon: Icon,
  title,
  description,
  href,
  action,
}: (typeof startingPoints)[number]) {
  return (
    <a
      href={href}
      className="nd-card nd-card-hover group relative flex h-full flex-col overflow-hidden p-7 sm:p-8"
    >
      <div className="flex items-start justify-between gap-5">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#fff1f2]">
          <Icon className="h-7 w-7 text-[#e5232e]" strokeWidth={1.8} />
        </div>

        <span className="text-xs font-black tracking-[0.15em] text-[#cfd3d9]">
          {number}
        </span>
      </div>

      <h3 className="mt-7 text-2xl font-black tracking-[-0.03em] text-[#202329]">
        {title}
      </h3>

      <p className="mt-3 flex-1 text-[15px] leading-7 text-[#68707d]">
        {description}
      </p>

      <div className="mt-7 flex items-center gap-2 text-sm font-extrabold text-[#e5232e]">
        <span>{action}</span>

        <ArrowRight
          className="h-4 w-4 transition-transform duration-200 group-hover:translate-x-1"
          strokeWidth={2.5}
        />
      </div>
    </a>
  );
}

function CheckRow({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex items-start gap-3">
      <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-[#e5232e]" />

      <span className="text-sm leading-6 text-[#68707d]">
        {children}
      </span>
    </div>
  );
}

function CapabilityCard({
  icon: Icon,
  title,
  description,
}: {
  icon: React.ElementType;
  title: string;
  description: string;
}) {
  return (
    <article className="nd-card nd-card-hover p-6 sm:p-7">
      <div className="flex items-start gap-4">
        <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
          <Icon size={20} />
        </div>

        <div>
          <h3 className="font-black text-[#202329]">
            {title}
          </h3>

          <p className="mt-2 text-sm leading-6 text-[#68707d]">
            {description}
          </p>
        </div>
      </div>
    </article>
  );
}

export default function MulaiPage() {
  return (
    <>
      <Header />

      <main>
        {/* ================================================= */}
        {/* HERO */}
        {/* ================================================= */}

        <section
          className="relative overflow-hidden bg-cover bg-center"
          style={{ backgroundImage: "url('/header.jpg')" }}
        >
          <div className="absolute inset-0 bg-black/55" />

          <div className="pointer-events-none absolute -right-40 -top-40 size-[520px] rounded-full bg-[#fff1f2] blur-3xl" />

          <div className="pointer-events-none absolute -bottom-40 -left-40 size-[420px] rounded-full bg-[#f8f9fb] blur-3xl" />

          <div className="container relative py-24 sm:py-28 lg:py-32">
            <div className="max-w-4xl">
              <div className="nd-section-label mb-5 !text-white/75">
                NUSA-DHIPA BUSINESS ECOSYSTEM
              </div>

              <h1 className="max-w-4xl font-black leading-[.95] tracking-[-.065em] text-white text-5xl sm:text-6xl lg:text-7xl xl:text-8xl">
                Mulai atau kembangkan
                <br />
                <span className="text-[#e5232e]">bisnis Anda.</span>
              </h1>

              <p className="mt-7 max-w-2xl text-base leading-7 text-white/90 sm:text-lg">
                Semua bisa bergabung di NUSA-DHIPA — baru mulai,
                sudah punya usaha, atau sudah memiliki legalitas.
                Mulai dari kebutuhan Anda dan kembangkan bisnis
                dalam satu ekosistem.
              </p>

              <div className="mt-9 flex flex-wrap gap-3">
                <a
                  href="#starting-point"
                  className="inline-flex items-center gap-2 rounded-xl bg-[#e5232e] px-6 py-3.5 text-sm font-extrabold text-white transition hover:bg-[#c91621]"
                >
                  Pilih Perjalanan
                  <ArrowRight className="h-4 w-4" />
                </a>

                <a
                  href={marketplaceUrl}
                  className="inline-flex items-center gap-2 rounded-xl border border-white/25 bg-white/10 px-6 py-3.5 text-sm font-extrabold text-white backdrop-blur-sm transition hover:bg-white/15"
                >
                  Jelajahi Marketplace
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* STARTING POINT */}
        {/* ================================================= */}

        <section
          id="starting-point"
          className="bg-[#f7f8fa] py-24 sm:py-32"
        >
          <div className="container">
            <div className="max-w-3xl">
              <div className="nd-section-label">
                BUSINESS STARTING POINT
              </div>

              <h2 className="mt-4 text-4xl font-black leading-[1.02] tracking-[-.05em] text-[#202329] sm:text-5xl lg:text-6xl">
                Semua bisa bergabung.
                <br />
                <span className="text-[#e5232e]">
                  Mulai dari mana?
                </span>
              </h2>

              <p className="mt-6 max-w-2xl text-base leading-7 text-[#68707d] sm:text-lg">
                Pilih kondisi yang paling sesuai dengan bisnis Anda.
                Legalitas bukan penghalang untuk mulai membangun
                profil dan menawarkan produk atau layanan.
              </p>
            </div>

            <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {startingPoints.map((item) => (
                <StartingPointCard
                  key={item.number}
                  {...item}
                />
              ))}
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* MARKETPLACE FIRST */}
        {/* ================================================= */}

        <section className="bg-white py-24 sm:py-32">
          <div className="container">
            <div className="grid items-center gap-12 lg:grid-cols-[.9fr_1.1fr]">
              <div>
                <div className="nd-section-label">
                  MARKETPLACE FIRST
                </div>

                <h2 className="mt-4 text-4xl font-black leading-[1.02] tracking-[-.05em] text-[#202329] sm:text-5xl lg:text-6xl">
                  Belum punya
                  <br />
                  <span className="text-[#e5232e]">
                    legalitas?
                  </span>
                </h2>

                <p className="mt-6 max-w-xl text-base leading-7 text-[#68707d] sm:text-lg">
                  Tidak masalah. Anda tetap dapat bergabung,
                  membuat profil bisnis, dan menawarkan produk
                  atau layanan di marketplace. Legalitas dapat
                  diproses dengan pendampingan NUSA-DHIPA.
                </p>

                <div className="mt-8 space-y-4">
                  <CheckRow>
                    Semua bisa mendaftar dan bergabung
                  </CheckRow>

                  <CheckRow>
                    Produk dan layanan dapat ditawarkan di marketplace
                  </CheckRow>

                  <CheckRow>
                    Legalitas bukan syarat untuk mulai listing
                  </CheckRow>

                  <CheckRow>
                    NUSA-DHIPA membantu proses legalitas bila diperlukan
                  </CheckRow>
                </div>
              </div>

              <div className="nd-card overflow-hidden">
                <div className="bg-[#17191d] p-7 sm:p-9">
                  <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-white/50">
                    MARKETPLACE BASIC
                  </div>

                  <div className="mt-3 flex flex-wrap items-end gap-2">
                    <span className="text-4xl font-black tracking-[-.04em] text-white sm:text-5xl">
                      Rp50.000
                    </span>
                  </div>

                  <p className="mt-4 max-w-xl text-sm leading-6 text-white/65">
                    Mulai masuk marketplace tanpa harus menunggu
                    seluruh proses legalitas selesai.
                  </p>
                </div>

                <div className="space-y-4 p-7 sm:p-9">
                  <CheckRow>
                    Profil bisnis di marketplace
                  </CheckRow>

                  <CheckRow>
                    Listing produk atau layanan
                  </CheckRow>

                  <CheckRow>
                    Mobile app trial selama 30 hari
                  </CheckRow>

                  <CheckRow>
                    Dapat mulai sambil proses legalitas berjalan
                  </CheckRow>

                  <div className="flex flex-wrap gap-3 pt-4">
                    <a
                      href="/mulai/marketplace"
                      className="inline-flex items-center gap-2 rounded-xl bg-[#e5232e] px-5 py-3 text-sm font-extrabold text-white transition hover:bg-[#c91621]"
                    >
                      Mulai Marketplace Basic
                      <ArrowRight className="h-4 w-4" />
                    </a>

                    <a
                      href="/legalitas"
                      className="inline-flex items-center rounded-xl border border-[#e7e9ed] px-5 py-3 text-sm font-extrabold text-[#202329] transition hover:border-[#d7dbe1] hover:bg-[#f7f8fa]"
                    >
                      Pendampingan Legalitas
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* BUSINESS CAPABILITY */}
        {/* ================================================= */}

        <section className="bg-[#f7f8fa] py-24 sm:py-32">
          <div className="container">
            <div className="max-w-3xl">
              <div className="nd-section-label">
                BUSINESS CAPABILITY
              </div>

              <h2 className="mt-4 text-4xl font-black leading-[1.02] tracking-[-.05em] text-[#202329] sm:text-5xl lg:text-6xl">
                Apa yang Anda
                <br />
                <span className="text-[#e5232e]">
                  tawarkan?
                </span>
              </h2>

              <p className="mt-6 max-w-2xl text-base leading-7 text-[#68707d] sm:text-lg">
                Pilih cara bisnis Anda beroperasi. Aktivitas usaha
                dan KBLI akan dibantu pada tahap berikutnya.
              </p>
            </div>

            <div className="mt-12 grid gap-5 md:grid-cols-3">
              <CapabilityCard
                icon={ShoppingBag}
                title="Jual Produk"
                description="Tawarkan barang dan produk melalui katalog dan marketplace."
              />

              <CapabilityCard
                icon={Handshake}
                title="Menyediakan Jasa"
                description="Tawarkan layanan, keahlian, dan jasa kepada pelanggan."
              />

              <CapabilityCard
                icon={Building2}
                title="Produk + Jasa"
                description="Kelola bisnis yang menjual produk sekaligus menyediakan layanan."
              />
            </div>

            <div className="mt-8 nd-card p-6 sm:p-8">
              <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <div className="flex items-center gap-2 text-sm font-black text-[#202329]">
                    <Search size={17} className="text-[#e5232e]" />
                    Aktivitas usaha
                  </div>

                  <p className="mt-2 max-w-2xl text-sm leading-6 text-[#68707d]">
                    Cari aktivitas usaha seperti jualan telur,
                    bengkel motor, konsultan IT, catering,
                    peternakan, hotel, jasa desain, dan lainnya.
                    NUSA-DHIPA menggunakan KBLI 2025 sebagai
                    referensi klasifikasi usaha.
                  </p>
                </div>

                <a
                  href="/legalitas"
                  className="inline-flex shrink-0 items-center gap-2 rounded-xl border border-[#e7e9ed] px-5 py-3 text-sm font-extrabold text-[#202329] transition hover:border-[#d7dbe1] hover:bg-[#f7f8fa]"
                >
                  Cari Aktivitas Usaha
                  <ArrowRight className="h-4 w-4 text-[#e5232e]" />
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* LEGALITY VERIFICATION */}
        {/* ================================================= */}

        <section className="bg-white py-24 sm:py-32">
          <div className="container">
            <div className="nd-card overflow-hidden">
              <div className="grid lg:grid-cols-[1fr_.75fr]">
                <div className="p-7 sm:p-12">
                  <div className="nd-section-label">
                    LEGALITY VERIFICATION
                  </div>

                  <h2 className="mt-4 text-4xl font-black tracking-[-.045em] text-[#17191d] sm:text-5xl">
                    Sudah punya
                    <span className="text-[#e5232e]">
                      {" "}legalitas?
                    </span>
                  </h2>

                  <p className="mt-5 max-w-xl text-sm leading-7 text-[#68707d] sm:text-base">
                    Masukkan data legalitas yang sudah Anda miliki.
                    NUSA-DHIPA dapat membantu memeriksa dan
                    menghubungkan data usaha dengan ekosistem bisnis.
                  </p>

                  <div className="mt-8 space-y-4">
                    <CheckRow>
                      NIB — status dan data usaha
                    </CheckRow>

                    <CheckRow>
                      KBLI — aktivitas usaha
                    </CheckRow>

                    <CheckRow>
                      AHU — status badan usaha
                    </CheckRow>
                  </div>

                  <a
                    href="/legalitas"
                    className="mt-9 inline-flex items-center gap-2 text-sm font-extrabold text-[#e5232e] hover:text-[#c91621]"
                  >
                    Verifikasi Data Usaha
                    <ArrowRight size={16} />
                  </a>
                </div>

                <div className="relative flex min-h-[300px] items-center justify-center overflow-hidden bg-[#17191d] p-8">
                  <div className="absolute size-64 rounded-full bg-[#e5232e]/20 blur-3xl" />

                  <div className="relative w-full max-w-xs rounded-2xl border border-white/10 bg-white/[.04] p-5">
                    <div className="text-[9px] font-extrabold uppercase tracking-[.18em] text-white/45">
                      LEGALITAS USAHA
                    </div>

                    <div className="mt-5 space-y-3">
                      <div className="flex items-center justify-between rounded-xl bg-white/[.05] px-4 py-3">
                        <span className="text-xs font-bold text-white/80">
                          NIB
                        </span>

                        <span className="text-[10px] font-black text-[#ff7b82]">
                          VERIFIKASI
                        </span>
                      </div>

                      <div className="flex items-center justify-between rounded-xl bg-white/[.05] px-4 py-3">
                        <span className="text-xs font-bold text-white/80">
                          KBLI
                        </span>

                        <span className="text-[10px] font-black text-[#ff7b82]">
                          VERIFIKASI
                        </span>
                      </div>

                      <div className="flex items-center justify-between rounded-xl bg-white/[.05] px-4 py-3">
                        <span className="text-xs font-bold text-white/80">
                          AHU
                        </span>

                        <span className="text-[10px] font-black text-[#ff7b82]">
                          VERIFIKASI
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================================================= */}
        {/* FINAL CTA */}
        {/* ================================================= */}

        <section className="bg-[#e5232e]">
          <div className="container py-20 sm:py-24">
            <div className="flex flex-col gap-8 lg:flex-row lg:items-center lg:justify-between">
              <div className="max-w-3xl">
                <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-white/65">
                  NUSA-DHIPA
                </div>

                <h2 className="mt-4 text-4xl font-black leading-[1.02] tracking-[-.05em] text-white sm:text-5xl lg:text-6xl">
                  Punya usaha?
                  <br />
                  Mulai dari langkah pertama.
                </h2>

                <p className="mt-5 max-w-2xl text-base leading-7 text-white/85 sm:text-lg">
                  Semua bisa bergabung. Mulai dari membangun usaha,
                  menawarkan produk atau layanan, masuk marketplace,
                  sampai mendapatkan pendampingan dan verifikasi
                  legalitas.
                </p>
              </div>

              <a
                href="#starting-point"
                className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-white px-6 py-3.5 text-sm font-extrabold text-[#e5232e] transition hover:bg-[#fff1f2]"
              >
                Pilih Langkah Pertama
                <ArrowRight className="h-4 w-4" />
              </a>
            </div>
          </div>
        </section>
      </main>
    </>
  );
}

import Link from "next/link";
import {
  CheckCircle2,
  FileCheck2,
  Smartphone,
  Store,
} from "lucide-react";

export default function MarketplaceStartPage() {
  return (
    <main className="min-h-screen bg-[#f7f8fa]">
      <section className="nd-red-gradient">
        <div className="container py-20 sm:py-24">
          <div className="max-w-3xl text-white">
            <div className="text-xs font-extrabold uppercase tracking-[.2em] text-white/70">
              MARKETPLACE ONBOARDING
            </div>

            <h1 className="mt-4 text-4xl font-black tracking-tight sm:text-6xl">
              Mulai jualan di NUSA-DHIPA.
            </h1>

            <p className="mt-6 max-w-2xl text-lg leading-8 text-white/85">
              Bangun kehadiran digital bisnis Anda dan tampilkan produk atau
              layanan kepada pelanggan di ekosistem NUSA-DHIPA.
            </p>
          </div>
        </div>
      </section>

      <section className="container py-14 sm:py-20">
        <div className="mx-auto max-w-5xl">
          <div className="grid gap-6 lg:grid-cols-2">
            <div className="rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-red-50">
                <Store className="h-7 w-7 text-red-600" />
              </div>

              <h2 className="mt-6 text-2xl font-black">
                Marketplace Basic
              </h2>

              <div className="mt-3 text-4xl font-black">
                Rp50.000
              </div>

              <p className="mt-3 leading-7 text-slate-600">
                Paket awal untuk bisnis yang ingin mulai masuk ke marketplace
                NUSA-DHIPA.
              </p>

              <div className="mt-7 space-y-4">
                {[
                  "Profil bisnis di marketplace",
                  "Listing produk atau layanan",
                  "Mobile app trial 30 hari",
                  "Dapat mulai sambil proses legalitas berjalan",
                ].map((item) => (
                  <div
                    key={item}
                    className="flex gap-3 text-sm font-medium text-slate-700"
                  >
                    <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-green-600" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>

              <Link
                href="/mulai/marketplace/onboarding"
                className="mt-8 block rounded-xl bg-red-600 px-6 py-3 text-center text-sm font-extrabold text-white transition hover:bg-red-700"
              >
                Mulai Marketplace Basic
              </Link>
            </div>

            <div className="space-y-5">
              <div className="rounded-3xl border border-slate-200 bg-white p-7">
                <FileCheck2 className="h-7 w-7 text-slate-700" />

                <h3 className="mt-4 text-xl font-black">
                  Belum punya NIB?
                </h3>

                <p className="mt-2 leading-7 text-slate-600">
                  Tidak perlu menunggu legalitas selesai untuk memulai
                  perjalanan digital bisnis Anda.
                </p>

                <Link
                  href="/legalitas"
                  className="mt-5 inline-flex text-sm font-bold text-red-600"
                >
                  Siapkan legalitas →
                </Link>
              </div>

              <div className="rounded-3xl border border-slate-200 bg-white p-7">
                <Smartphone className="h-7 w-7 text-slate-700" />

                <h3 className="mt-4 text-xl font-black">
                  Mobile App Trial 30 Hari
                </h3>

                <p className="mt-2 leading-7 text-slate-600">
                  Bisnis dapat mencoba pengalaman mobile app selama proses
                  onboarding dan legalitas berlangsung.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}

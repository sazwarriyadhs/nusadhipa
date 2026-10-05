"use client";

import {
  ArrowLeft,
  ArrowRight,
  Check,
  CheckCircle2,
  FileCheck2,
  Mail,
  MapPin,
  Phone,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { useEffect, useState } from "react";
import Link from "next/link";

const LEGAL_DP_PERCENT = 60;
const LEGAL_REMAINING_PERCENT = 40;

const MOBILE_BASIC_PRICE = 50000;

function calculateLegalPayment(total: number) {
  const dp = Math.round(total * LEGAL_DP_PERCENT / 100);
  const remaining = total - dp;

  return {
    total,
    dpPercent: LEGAL_DP_PERCENT,
    dp,
    remainingPercent: LEGAL_REMAINING_PERCENT,
    remaining,
  };
}
type LegalPackage =
  | "basic"
  | "pt_perorangan"
  | "cv"
  | "pt"
  | "corporate";

type PackageInfo = {
  id: LegalPackage;
  title: string;
  price: string;
  description: string;
  features: string[];
};

const packages: PackageInfo[] = [
  {
    id: "basic",
    title: "Basic",
    price: "Rp1.000.000",
    description: "Untuk UMKM yang ingin memulai legalitas usaha.",
    features: [
      "Konsultasi legalitas usaha",
      "NIB via OSS",
      "Pemeriksaan & pemilihan KBLI",
      "Business profile",
      "Pendampingan sampai dokumen terbit",
    ],
  },
  {
    id: "pt_perorangan",
    title: "PT Perorangan",
    price: "Rp1.500.000",
    description: "Untuk pemilik usaha perorangan yang ingin membangun badan usaha.",
    features: [
      "Konsultasi",
      "Pendaftaran PT Perorangan",
      "KBLI & NIB",
      "Dokumen pendirian",
      "Pendampingan OSS",
    ],
  },
  {
    id: "cv",
    title: "CV",
    price: "Rp2.500.000",
    description: "Untuk usaha dengan struktur kemitraan aktif dan pasif.",
    features: [
      "Konsultasi CV",
      "Pemilihan nama",
      "Data pendirian",
      "Akta pendirian",
      "SK Kemenkum",
      "NIB & KBLI",
    ],
  },
  {
    id: "pt",
    title: "PT",
    price: "Mulai Rp4.500.000",
    description: "Untuk bisnis yang membutuhkan struktur perusahaan formal.",
    features: [
      "Konsultasi PT",
      "Pemilihan nama",
      "Akta pendirian",
      "SK Kemenkum",
      "NIB & KBLI",
      "Pendampingan OSS",
      "NPWP Badan*",
    ],
  },
  {
    id: "corporate",
    title: "Corporate",
    price: "Custom",
    description: "Untuk kebutuhan legalitas dan pengembangan bisnis yang lebih kompleks.",
    features: [
      "Pendirian PT",
      "NIB & OSS",
      "KBLI",
      "NPWP Badan",
      "Perizinan usaha",
      "Penyesuaian data",
      "Konsultasi pengembangan legal",
    ],
  },
];

function readParam(name: string): string {
  if (typeof window === "undefined") return "";
  return new URLSearchParams(window.location.search).get(name) ?? "";
}

function formatNibStatus(value: string) {
  if (value === "yes") return "Sudah ada";
  if (value === "no") return "Belum ada";
  return "Belum tahu / perlu diperiksa";
}

export default function LegalOnboardingPage() {
  const [businessName, setBusinessName] = useState("");
  const [location, setLocation] = useState("");
  const [activity, setActivity] = useState("");
  const [nibStatus, setNibStatus] = useState("unknown");
  const [kbliCode, setKbliCode] = useState("");
  const [kbliName, setKbliName] = useState("");

  const [legalPackage, setLegalPackage] =
    useState<LegalPackage>("basic");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");

  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    setBusinessName(readParam("business_name"));
    setLocation(readParam("location"));
    setActivity(readParam("activity"));
    setNibStatus(readParam("nib_status"));
    setKbliCode(readParam("kbli_code"));
    setKbliName(readParam("kbli_name"));
  }, []);

  const selectedPackage =
    packages.find((item) => item.id === legalPackage) ??
    packages[0];

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    /*
     * Landing page belum memiliki tenant/auth context.
     * Jangan POST ke Legal Service di sini karena endpoint
     * setup-requests membutuhkan authenticated tenant context.
     *
     * Untuk sementara kita tampilkan confirmation state.
     * Integrasi submit akan dilakukan setelah tenant/auth flow
     * Business OS tersedia.
     */
    setSubmitted(true);
  }

  if (submitted) {
    return (
      <main className="min-h-screen bg-[#f7f8fa]">
        <section className="nd-red-gradient relative overflow-hidden">
          <div className="absolute inset-0 bg-black/10" />

          <div className="container relative py-20 sm:py-24">
            <div className="mx-auto max-w-3xl text-center text-white">
              <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-white/15 backdrop-blur">
                <CheckCircle2 size={34} />
              </div>

              <div className="mt-6 text-xs font-black uppercase tracking-[.18em] text-white/75">
                Legal Onboarding
              </div>

              <h1 className="mt-3 text-3xl font-black tracking-[-.04em] sm:text-5xl">
                Data bisnis Anda sudah siap.
              </h1>

              <p className="mx-auto mt-5 max-w-2xl text-sm leading-7 text-white/85 sm:text-base">
                Permintaan Anda sudah disiapkan. Tahap berikutnya adalah
                menghubungkan data ini ke proses legalitas yang terautentikasi.
              </p>

              <div className="mx-auto mt-8 max-w-xl rounded-2xl border border-white/15 bg-white/10 p-5 text-left backdrop-blur">
                <div className="text-xs font-black uppercase tracking-[.14em] text-white/60">
                  Ringkasan
                </div>

                <div className="mt-4 space-y-3 text-sm">
                  <div className="flex justify-between gap-4">
                    <span className="text-white/65">Bisnis</span>
                    <span className="font-bold text-right">
                      {businessName || "-"}
                    </span>
                  </div>

                  <div className="flex justify-between gap-4">
                    <span className="text-white/65">KBLI</span>
                    <span className="font-bold text-right">
                      {kbliCode || "-"}
                    </span>
                  </div>

                  <div className="flex justify-between gap-4">
                    <span className="text-white/65">Layanan</span>
                    <span className="font-bold text-right">
                      {selectedPackage.title}
                    </span>
                  </div>
                </div>
              </div>

              <Link
                href="/legalitas"
                className="mt-8 inline-flex items-center gap-2 rounded-xl bg-white px-5 py-3.5 text-sm font-black text-[#e5232e] transition hover:-translate-y-0.5"
              >
                Kembali ke Business Discovery
                <ArrowRight size={17} />
              </Link>
            </div>
          </div>
        </section>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-[#f7f8fa]">
      <section className="nd-red-gradient relative overflow-hidden">
        <div className="absolute inset-0 bg-black/10" />

        <div className="container relative py-14 sm:py-18">
          <Link
            href="/legalitas"
            className="inline-flex items-center gap-2 text-sm font-bold text-white/80 transition hover:text-white"
          >
            <ArrowLeft size={17} />
            Kembali ke Business Discovery
          </Link>

          <div className="mt-10 max-w-3xl">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-black uppercase tracking-[.12em] text-white backdrop-blur">
              <Sparkles size={14} />
              STEP 02 · Legal Onboarding
            </div>

            <h1 className="mt-5 text-3xl font-black tracking-[-.045em] text-white sm:text-5xl">
              Siapkan legalitas bisnis Anda.
            </h1>

            <p className="mt-5 max-w-2xl text-sm leading-7 text-white/80 sm:text-base">
              Kami sudah membawa hasil Business Discovery dan kandidat KBLI
              Anda ke tahap berikutnya. Review data, pilih kebutuhan legalitas,
              lalu lengkapi kontak Anda.
            </p>
          </div>
        </div>
      </section>

      <section className="container pt-10 pb-16 sm:pt-12 sm:pb-20">
        <div className="grid gap-6 lg:grid-cols-[1.08fr_.92fr]">
          <div className="space-y-6">
            <div className="nd-card p-6 sm:p-8">
              <div className="nd-section-label">
                BUSINESS DISCOVERY
              </div>

              <h2 className="mt-2 text-2xl font-black tracking-tight">
                Review data bisnis
              </h2>

              <p className="mt-2 text-sm leading-6 text-[#68707d]">
                Pastikan data dasar berikut sudah sesuai sebelum masuk ke
                proses legalitas.
              </p>

              <div className="mt-6 grid gap-3 sm:grid-cols-2">
                <InfoCard
                  icon={<Sparkles size={17} />}
                  label="Nama usaha"
                  value={businessName || "Belum diisi"}
                />

                <InfoCard
                  icon={<MapPin size={17} />}
                  label="Lokasi usaha"
                  value={location || "Belum diisi"}
                />

                <InfoCard
                  icon={<FileCheck2 size={17} />}
                  label="KBLI candidate"
                  value={
                    kbliCode
                      ? `${kbliCode} · ${kbliName}`
                      : "Belum dipilih"
                  }
                />

                <InfoCard
                  icon={<ShieldCheck size={17} />}
                  label="Status NIB"
                  value={formatNibStatus(nibStatus)}
                />
              </div>

              <div className="mt-5 rounded-xl border border-[#e7e9ed] bg-[#f7f8fa] p-4">
                <div className="text-xs font-black uppercase tracking-[.12em] text-[#8a919c]">
                  Aktivitas bisnis
                </div>

                <p className="mt-2 text-sm leading-6 text-[#202329]">
                  {activity || "Belum diisi"}
                </p>
              </div>
            </div>

            <div className="nd-card p-6 sm:p-8">
              <div className="nd-section-label">
                LEGAL SERVICE
              </div>

              <h2 className="mt-2 text-2xl font-black tracking-tight">
                Pilih kebutuhan legalitas
              </h2>

              <p className="mt-2 text-sm leading-6 text-[#68707d]">
                Jika belum yakin harus memilih bentuk usaha yang mana,
                konsultasikan terlebih dahulu. Pilihan di bawah adalah
                informasi awal, bukan keputusan hukum final.
              </p>

              <div className="mt-6 space-y-3">
                {packages.map((item) => {
                  const active = legalPackage === item.id;

                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => setLegalPackage(item.id)}
                      className={`w-full rounded-2xl border p-4 text-left transition-all duration-200 ${
                        active
                          ? "border-[#e5232e] bg-[#fff1f2] shadow-[0_8px_24px_rgba(229,35,46,.08)]"
                          : "border-[#e7e9ed] bg-white hover:-translate-y-0.5 hover:border-[#cfd4db] hover:shadow-sm"
                      }`}
                    >
                      <div className="flex items-start gap-4">
                        <div
                          className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full border ${
                            active
                              ? "border-[#e5232e] bg-[#e5232e] text-white"
                              : "border-[#cfd4db] bg-white text-transparent"
                          }`}
                        >
                          <Check size={14} strokeWidth={3} />
                        </div>

                        <div className="min-w-0 flex-1">
                          <div className="flex flex-col justify-between gap-1 sm:flex-row sm:items-center">
                            <div className="text-base font-black text-[#202329]">
                              {item.title}
                            </div>

                            <div
                              className={`text-sm font-black ${
                                active
                                  ? "text-[#e5232e]"
                                  : "text-[#202329]"
                              }`}
                            >
                              {item.price}
                            </div>
                          </div>

                          <p className="mt-1 text-sm leading-6 text-[#68707d]">
                            {item.description}
                          </p>

                          <div className="mt-3 flex flex-wrap gap-2">
                            {item.features.slice(0, 4).map((feature) => (
                              <span
                                key={feature}
                                className="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#68707d] ring-1 ring-[#e7e9ed]"
                              >
                                {feature}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>

              <p className="mt-4 text-xs leading-5 text-[#8a919c]">
                * Harga dapat dipengaruhi domisili, jumlah KBLI, jenis usaha,
                jumlah pemilik/pengurus, notaris, dan kebutuhan perizinan
                tambahan.
              </p>
            </div>
          </div>

          <aside className="space-y-6">
            <div className="nd-card p-6 sm:p-7">
              <div className="nd-section-label">
                CONTACT
              </div>

              <h2 className="mt-2 text-xl font-black">
                Data kontak Anda
              </h2>

              <p className="mt-2 text-sm leading-6 text-[#68707d]">
                Gunakan kontak aktif agar tim legalitas dapat menghubungi Anda
                untuk tahap berikutnya.
              </p>

              <form
                onSubmit={handleSubmit}
                className="mt-6 space-y-4"
              >
                <label className="block">
                  <span className="mb-2 block text-sm font-bold">
                    Nama lengkap
                  </span>

                  <input
                    required
                    value={name}
                    onChange={(event) =>
                      setName(event.target.value)
                    }
                    className="nd-input w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="Nama Anda"
                  />
                </label>

                <label className="block">
                  <span className="mb-2 flex items-center gap-2 text-sm font-bold">
                    <Mail size={15} />
                    Email
                  </span>

                  <input
                    required
                    type="email"
                    value={email}
                    onChange={(event) =>
                      setEmail(event.target.value)
                    }
                    className="nd-input w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="email@contoh.com"
                  />
                </label>

                <label className="block">
                  <span className="mb-2 flex items-center gap-2 text-sm font-bold">
                    <Phone size={15} />
                    WhatsApp
                  </span>

                  <input
                    required
                    type="tel"
                    value={phone}
                    onChange={(event) =>
                      setPhone(event.target.value)
                    }
                    className="nd-input w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="+62 812-xxxx-xxxx"
                  />
                </label>

                <button
                  type="submit"
                  className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl bg-[#e5232e] px-5 py-3.5 text-sm font-black text-white transition hover:-translate-y-0.5 hover:bg-[#c91621]"
                >
                  Ajukan Legalitas
                  <ArrowRight size={17} />
                </button>
              </form>
            </div>

            <div className="rounded-2xl border border-[#e7e9ed] bg-white p-6 shadow-[0_8px_30px_rgba(20,24,32,.05)]">
              <div className="text-xs font-black uppercase tracking-[.14em] text-[#e5232e]">
                SELECTED SERVICE
              </div>

              <div className="mt-3 flex items-start justify-between gap-4">
                <div>
                  <div className="text-lg font-black text-[#202329]">
                    {selectedPackage.title}
                  </div>

                  <div className="mt-1 text-sm text-[#68707d]">
                    {selectedPackage.description}
                  </div>
                </div>

                <div className="shrink-0 text-right text-sm font-black text-[#e5232e]">
                  {selectedPackage.price}
                </div>
              </div>

              <div className="mt-5 border-t border-[#e7e9ed] pt-5">
                <div className="flex items-center justify-between gap-4">
                  <span className="text-sm font-bold text-[#68707d]">
                    Business
                  </span>

                  <span className="max-w-[60%] truncate text-right text-sm font-black text-[#202329]">
                    {businessName || "-"}
                  </span>
                </div>

                <div className="mt-3 flex items-center justify-between gap-4">
                  <span className="text-sm font-bold text-[#68707d]">
                    KBLI
                  </span>

                  <span className="text-right text-sm font-black text-[#202329]">
                    {kbliCode || "-"}
                  </span>
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-[#f0d4d7] bg-[#fff8f8] p-5">
              <div className="flex items-start gap-3">
                <div className="mt-0.5 text-[#e5232e]">
                  <ShieldCheck size={18} />
                </div>

                <div>
                  <div className="text-sm font-black text-[#202329]">
                    Legalitas jelas, usaha lebih siap berkembang.
                  </div>

                  <p className="mt-1.5 text-xs leading-5 text-[#68707d]">
                    Kandidat KBLI dari tahap discovery tetap perlu dikonfirmasi
                    sebelum proses legalitas resmi dimulai.
                  </p>
                </div>
              </div>
            </div>
          </aside>
        </div>
      </section>
    </main>
  );
}

function InfoCard({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-xl border border-[#e7e9ed] bg-white p-4">
      <div className="flex items-center gap-2 text-xs font-black uppercase tracking-[.1em] text-[#8a919c]">
        <span className="text-[#e5232e]">
          {icon}
        </span>
        {label}
      </div>

      <div className="mt-2 break-words text-sm font-bold leading-6 text-[#202329]">
        {value}
      </div>
    </div>
  );
}




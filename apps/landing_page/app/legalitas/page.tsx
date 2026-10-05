"use client";

import {
  CheckCircle2,
  ChevronRight,
  FileCheck2,
  MapPin,
  Search,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { useEffect, useState } from "react";
import Link from "next/link";

type KbliItem = {
  code: string;
  name: string;
  description: string;
  level: number;
  score: number;
  match_type: string;
  intent: string;
  matched_terms: string[];
};

type KbliResponse = {
  success: boolean;
  data?: {
    items: KbliItem[];
    total: number;
    query: string;
    limit: number;
    intent: string | null;
  };
  message?: string;
};

type NibStatus =
  | "unknown"
  | "yes"
  | "no";

export default function LegalitasPage() {
  const [businessName, setBusinessName] =
    useState("");

  const [location, setLocation] =
    useState("");

  const [activity, setActivity] =
    useState("");

  const [nibStatus, setNibStatus] =
    useState<NibStatus>("unknown");

  const [items, setItems] =
    useState<KbliItem[]>([]);

  const [intent, setIntent] =
    useState<string | null>(null);

  const [loading, setLoading] =
    useState(false);

  const [searched, setSearched] =
    useState(false);

  const [error, setError] =
    useState("");

  const [selectedKbli, setSelectedKbli] =
    useState<KbliItem | null>(null);

  useEffect(() => {
    if (activity.trim().length < 3) {
      setItems([]);
      setIntent(null);
      setSearched(false);
      return;
    }

    const timer = setTimeout(async () => {
      setLoading(true);
      setError("");

      try {
        const response = await fetch(
          `/api/legalitas/kbli?q=${encodeURIComponent(
            activity.trim()
          )}&limit=8`,
          {
            cache: "no-store",
          }
        );

        const data =
          (await response.json()) as KbliResponse;

        if (!response.ok || !data.success) {
          throw new Error(
            data.message ||
              "KBLI discovery gagal."
          );
        }

        setItems(
          data.data?.items || []
        );

        setIntent(
          data.data?.intent || null
        );

        setSearched(true);
      } catch (err) {
        setItems([]);
        setIntent(null);
        setSearched(true);

        setError(
          err instanceof Error
            ? err.message
            : "KBLI discovery gagal."
        );
      } finally {
        setLoading(false);
      }
    }, 450);

    return () =>
      clearTimeout(timer);
  }, [activity]);

  const nibLabel =
    nibStatus === "yes"
      ? "NIB terindikasi sudah ada"
      : nibStatus === "no"
        ? "NIB belum ada / belum diketahui"
        : "Belum diperiksa";

  return (
    <main className="min-h-screen bg-[#f7f8fa] text-[#202329]">
      <section className="border-b border-[#e7e9ed] bg-white">
        <div className="container py-5">
          <HeaderFallback />
        </div>
      </section>

      <section className="relative overflow-hidden bg-[#17191d]">
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{
            backgroundImage: "url('/pendaftaran.jpg')",
          }}
        />

        <div className="absolute inset-0 bg-[#17191d]/65" />

        <div className="absolute inset-0 bg-gradient-to-r from-[#17191d]/90 via-[#17191d]/65 to-[#e5232e]/35" />

        <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-[#e5232e]/20 blur-3xl" />

        <div className="absolute -bottom-32 -left-20 h-80 w-80 rounded-full bg-black/30 blur-3xl" />

        <div className="container relative py-16 sm:py-20 lg:py-24">
          <div className="max-w-4xl">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-xs font-black uppercase tracking-[.2em] text-white/80 backdrop-blur-sm">
              <Sparkles size={14} />
              Business Discovery
            </div>

            <h1 className="mt-6 max-w-4xl text-4xl font-black leading-[.98] tracking-[-.045em] text-white sm:text-5xl lg:text-6xl">
              Kenali bisnis Anda.
              <br />
              <span className="text-[#ff858b]">
                Siapkan legalitasnya.
              </span>
            </h1>

            <p className="mt-6 max-w-2xl text-base leading-7 text-white/85 sm:text-lg">
              Ceritakan bisnis Anda dengan bahasa sederhana.
              NUSA-DHIPA membantu menemukan aktivitas usaha,
              kandidat KBLI 2025, dan kesiapan legalitas
              sebelum Anda melanjutkan proses berikutnya.
            </p>

            <div className="mt-7 flex flex-wrap gap-3">
              <div className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold text-white/85 backdrop-blur-sm">
                KBLI 2025
              </div>

              <div className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold text-white/85 backdrop-blur-sm">
                Legal Readiness
              </div>

              <div className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold text-white/85 backdrop-blur-sm">
                Business Discovery
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="container pt-10 pb-16 sm:pt-12">
        <div className="grid gap-6 lg:grid-cols-[1.15fr_.85fr]">
          <div className="nd-card p-6 sm:p-8">
            <div className="nd-section-label">
              STEP 01
            </div>

            <h2 className="mt-2 text-2xl font-black tracking-tight">
              Ceritakan bisnis Anda
            </h2>

            <p className="mt-2 text-sm leading-6 text-[#68707d]">
              Tidak perlu tahu kode KBLI terlebih dahulu.
              Jelaskan aktivitas usaha Anda seperti biasa.
            </p>

            <div className="mt-7 space-y-5">
              <label className="block">
                <span className="mb-2 block text-sm font-bold">
                  Nama usaha
                </span>

                <input
                  value={businessName}
                  onChange={(event) =>
                    setBusinessName(
                      event.target.value
                    )
                  }
                  placeholder="Contoh: Nama Usaha Anda"
                  className="w-full rounded-xl border border-[#dfe3e8] bg-white px-4 py-3.5 text-sm outline-none transition focus:border-[#e5232e] focus:ring-4 focus:ring-[#e5232e]/10"
                />
              </label>

              <label className="block">
                <span className="mb-2 flex items-center gap-2 text-sm font-bold">
                  <MapPin size={15} />
                  Lokasi usaha
                </span>

                <input
                  value={location}
                  onChange={(event) =>
                    setLocation(
                      event.target.value
                    )
                  }
                  placeholder="Contoh: Kota / Kabupaten, Provinsi"
                  className="w-full rounded-xl border border-[#dfe3e8] bg-white px-4 py-3.5 text-sm outline-none transition focus:border-[#e5232e] focus:ring-4 focus:ring-[#e5232e]/10"
                />
              </label>

              <label className="block">
                <span className="mb-2 block text-sm font-bold">
                  Apa aktivitas utama bisnis Anda?
                </span>

                <textarea
                  value={activity}
                  onChange={(event) =>
                    setActivity(
                      event.target.value
                    )
                  }
                  rows={4}
                  placeholder="Contoh: pangkas rambut pria, potong rambut, styling rambut dan cukur jenggot"
                  className="w-full resize-none rounded-xl border border-[#dfe3e8] bg-white px-4 py-3.5 text-sm leading-6 outline-none transition focus:border-[#e5232e] focus:ring-4 focus:ring-[#e5232e]/10"
                />

                <div className="mt-2 flex items-center justify-between text-xs text-[#8a919c]">
                  <span>
                    Jelaskan dengan bahasa sehari-hari.
                  </span>

                  {loading && (
                    <span className="font-bold text-[#e5232e]">
                      Mencari KBLI...
                    </span>
                  )}
                </div>
              </label>

              <div>
                <span className="mb-3 block text-sm font-bold">
                  Bagaimana status NIB Anda?
                </span>

                <div className="grid gap-3 sm:grid-cols-3">
                  <NibButton
                    active={
                      nibStatus === "yes"
                    }
                    onClick={() =>
                      setNibStatus("yes")
                    }
                    title="Sudah ada"
                    description="Saya punya NIB"
                  />

                  <NibButton
                    active={
                      nibStatus === "no"
                    }
                    onClick={() =>
                      setNibStatus("no")
                    }
                    title="Belum ada"
                    description="Belum punya NIB"
                  />

                  <NibButton
                    active={
                      nibStatus === "unknown"
                    }
                    onClick={() =>
                      setNibStatus(
                        "unknown"
                      )
                    }
                    title="Belum tahu"
                    description="Perlu diperiksa"
                  />
                </div>
              </div>
            </div>
          </div>

          <aside className="space-y-6">
            <div className="nd-card p-6 sm:p-7">
              <div className="flex items-center gap-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#fff1f2] text-[#e5232e]">
                  <Search size={20} />
                </div>

                <div>
                  <div className="text-xs font-black uppercase tracking-[.14em] text-[#e5232e]">
                    KBLI Discovery
                  </div>

                  <h3 className="mt-1 text-lg font-black">
                    Kandidat aktivitas
                  </h3>
                </div>
              </div>

              {error && (
                <div className="mt-5 rounded-xl border border-red-200 bg-red-50 p-4 text-sm leading-6 text-red-700">
                  {error}
                </div>
              )}

              {!error &&
                !searched &&
                !loading && (
                  <div className="mt-6 rounded-2xl border border-dashed border-[#dfe3e8] p-6 text-center">
                    <Search
                      className="mx-auto text-[#a2a8b2]"
                      size={24}
                    />

                    <p className="mt-3 text-sm font-bold text-[#68707d]">
                      Mulai dengan menjelaskan
                      aktivitas bisnis Anda.
                    </p>
                  </div>
                )}

              {!error &&
                searched &&
                !loading &&
                items.length === 0 && (
                  <div className="mt-6 rounded-2xl border border-dashed border-[#dfe3e8] p-6 text-center">
                    <p className="text-sm font-bold text-[#68707d]">
                      Belum menemukan kandidat KBLI
                      yang cukup relevan.
                    </p>

                    <p className="mt-2 text-xs leading-5 text-[#8a919c]">
                      Coba jelaskan aktivitas dengan
                      kata yang lebih spesifik.
                    </p>
                  </div>
                )}

              {intent &&
                items.length > 0 && (
                  <div className="mt-5 rounded-xl bg-[#f7f8fa] px-4 py-3 text-xs">
                    <span className="font-bold">
                      Intent terdeteksi:
                    </span>{" "}
                    {intent.replace(
                      /_/g,
                      " "
                    )}
                  </div>
                )}

              <div className="mt-5 space-y-3">
                {items.map(
                  (item, index) => {
                    const selected =
                      selectedKbli?.code ===
                      item.code;

                    return (
                      <button
                        key={`${item.code}-${index}`}
                        type="button"
                        onClick={() =>
                          setSelectedKbli(
                            item
                          )
                        }
                        className={`w-full rounded-2xl border p-4 text-left transition ${
                          selected
                            ? "border-[#e5232e] bg-[#fff7f7] shadow-[0_8px_25px_rgba(229,35,46,.10)]"
                            : "border-[#e7e9ed] bg-white hover:border-[#cfd4db] hover:shadow-sm"
                        }`}
                      >
                        <div className="flex items-start justify-between gap-4">
                          <div>
                            <div className="flex items-center gap-2">
                              {index === 0 && (
                                <span className="rounded-full bg-[#e5232e] px-2 py-1 text-[9px] font-black uppercase tracking-wider text-white">
                                  Recommended
                                </span>
                              )}

                              <span className="font-mono text-xs font-black text-[#e5232e]">
                                {item.code}
                              </span>
                            </div>

                            <h4 className="mt-2 text-sm font-black leading-5">
                              {item.name}
                            </h4>
                          </div>

                          {selected && (
                            <CheckCircle2
                              className="shrink-0 text-[#e5232e]"
                              size={20}
                            />
                          )}
                        </div>

                        <p className="mt-2 line-clamp-3 text-xs leading-5 text-[#68707d]">
                          {item.description}
                        </p>

                        <div className="mt-3 flex flex-wrap gap-2">
                          <span className="rounded-full bg-[#f7f8fa] px-2.5 py-1 text-[10px] font-bold text-[#68707d]">
                            Level {item.level}
                          </span>

                          <span className="rounded-full bg-[#f7f8fa] px-2.5 py-1 text-[10px] font-bold text-[#68707d]">
                            {item.match_type.replace(
                              /_/g,
                              " "
                            )}
                          </span>
                        </div>
                      </button>
                    );
                  }
                )}
              </div>
            </div>

            <div className="nd-card p-6 sm:p-7">
              <div className="nd-section-label">
                LEGAL READINESS
              </div>

              <h3 className="mt-2 text-xl font-black">
                Status awal bisnis
              </h3>

              <div className="mt-5 space-y-3">
                <ReadinessRow
                  icon={
                    <CheckCircle2 size={17} />
                  }
                  label="Business identity"
                  value={
                    businessName
                      ? "Terisi"
                      : "Belum diisi"
                  }
                  active={
                    !!businessName
                  }
                />

                <ReadinessRow
                  icon={
                    <MapPin size={17} />
                  }
                  label="Business location"
                  value={
                    location
                      ? "Terisi"
                      : "Belum diisi"
                  }
                  active={
                    !!location
                  }
                />

                <ReadinessRow
                  icon={
                    <FileCheck2 size={17} />
                  }
                  label="KBLI candidate"
                  value={
                    selectedKbli
                      ? selectedKbli.code
                      : "Belum dipilih"
                  }
                  active={
                    !!selectedKbli
                  }
                />

                <ReadinessRow
                  icon={
                    <ShieldCheck size={17} />
                  }
                  label="NIB status"
                  value={nibLabel}
                  active={
                    nibStatus !==
                    "unknown"
                  }
                />
              </div>

              <button
                type="button"
                disabled={!selectedKbli}
                onClick={() => {
                  if (!selectedKbli) return;

                  const params = new URLSearchParams({
                    business_name: businessName,
                    location,
                    activity,
                    nib_status: nibStatus,
                    kbli_code: selectedKbli.code,
                    kbli_name: selectedKbli.name,
                  });

                  window.location.href =
                    `/legalitas/onboarding?${params.toString()}`;
                }}
                className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-[#e5232e] px-5 py-3.5 text-sm font-black text-white transition hover:bg-[#c91621] disabled:cursor-not-allowed disabled:bg-[#d9dce1]"
              >
                Lanjutkan Legal Onboarding
                <ChevronRight size={17} />
              </button>

              <p className="mt-3 text-center text-[11px] leading-5 text-[#8a919c]">
                Kandidat KBLI perlu dikonfirmasi
                oleh pemilik usaha sebelum proses
                legalitas dilanjutkan.
              </p>
            </div>
          </aside>
        </div>
      </section>
    
<section className="mx-auto mt-16 max-w-6xl px-6 pb-20">
  <div className="overflow-hidden rounded-[28px] border border-[#e7e9ed] bg-white shadow-[0_20px_60px_rgba(20,30,50,0.08)]">
    <div className="bg-[#101828] px-6 py-8 text-white md:px-10">
      <div className="max-w-3xl">
        <div className="mb-3 text-xs font-black uppercase tracking-[0.22em] text-[#e5232e]">
          NUSA-DHIPA LEGALITAS
        </div>

        <h2 className="text-2xl font-black md:text-4xl">
          Tetap bisa jualan sambil legalitas diproses
        </h2>

        <p className="mt-3 text-sm leading-6 text-white/70 md:text-base">
          Usaha Anda tetap dapat menggunakan Marketplace selama proses
          pendirian/legalitas berlangsung. NUSA-DHIPA menangani proses
          legalitas sesuai layanan yang Anda pilih.
        </p>
      </div>
    </div>

    <div className="grid gap-4 p-6 md:grid-cols-3 md:p-8">
      <div className="rounded-2xl border border-[#e7e9ed] p-5">
        <div className="text-xs font-black uppercase tracking-wider text-[#667085]">
          Belum legal
        </div>
        <div className="mt-2 text-lg font-black text-[#101828]">
          Marketplace tetap aktif
        </div>
        <p className="mt-2 text-sm leading-6 text-[#667085]">
          Mulai jual produk atau layanan sambil proses legalitas berjalan.
        </p>
      </div>

      <div className="rounded-2xl border border-[#e7e9ed] p-5">
        <div className="text-xs font-black uppercase tracking-wider text-[#667085]">
          Mobile Basic
        </div>
        <div className="mt-2 text-lg font-black text-[#101828]">
          Rp50.000
        </div>
        <p className="mt-2 text-sm leading-6 text-[#667085]">
          Paket Mobile Basic ditawarkan sesuai kondisi dan kebutuhan bisnis.
        </p>
      </div>

      <div className="rounded-2xl border border-[#e7e9ed] p-5">
        <div className="text-xs font-black uppercase tracking-wider text-[#667085]">
          Pembayaran legalitas
        </div>
        <div className="mt-2 text-lg font-black text-[#101828]">
          DP 60% + 40%
        </div>
        <p className="mt-2 text-sm leading-6 text-[#667085]">
          Invoice pendirian menggunakan skema DP 60% dan pelunasan 40%.
        </p>
      </div>
    </div>
  </div>
</section>
</main>
  );
}

function NibButton({
  active,
  onClick,
  title,
  description,
}: {
  active: boolean;
  onClick: () => void;
  title: string;
  description: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={`group min-h-[88px] rounded-xl border p-4 text-left transition-all duration-200 ${
        active
          ? "border-[#e5232e] bg-[#fff1f2] shadow-[0_6px_18px_rgba(229,35,46,.10)]"
          : "border-[#dfe3e8] bg-white hover:-translate-y-0.5 hover:border-[#cfd4db] hover:shadow-sm"
      }`}
    >
      <div className="flex items-start gap-3">
        <div
          className={`mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border text-[10px] font-black transition ${
            active
              ? "border-[#e5232e] bg-[#e5232e] text-white"
              : "border-[#cfd4db] bg-white text-transparent"
          }`}
        >
          ✓
        </div>

        <div className="min-w-0">
          <div
            className={`text-sm font-black leading-5 ${
              active
                ? "text-[#e5232e]"
                : "text-[#202329]"
            }`}
          >
            {title}
          </div>

          <div className="mt-1 text-xs leading-5 text-[#68707d]">
            {description}
          </div>
        </div>
      </div>
    </button>
  );
}

function ReadinessRow({
  icon,
  label,
  value,
  active,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  active: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-xl border border-[#e7e9ed] bg-white p-3.5">
      <div className="flex min-w-0 items-center gap-3">
        <div
          className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${
            active
              ? "bg-[#fff1f2] text-[#e5232e]"
              : "bg-[#f7f8fa] text-[#9aa1ab]"
          }`}
        >
          {icon}
        </div>

        <span className="truncate text-sm font-bold">
          {label}
        </span>
      </div>

      <span
        className={`shrink-0 text-xs font-bold ${
          active
            ? "text-[#e5232e]"
            : "text-[#8a919c]"
        }`}
      >
        {value}
      </span>
    </div>
  );
}

function HeaderFallback() {
  return (
    <header className="flex items-center justify-between">
      <Link
        href="/"
        className="flex items-center gap-3"
      >
        <img
          src="/logo.png"
          alt="NUSA-DHIPA"
          className="h-10 w-auto"
        />

        <div className="hidden sm:block">
          <div className="text-sm font-black tracking-tight">
            NUSA-DHIPA
          </div>

          <div className="text-[10px] font-bold uppercase tracking-[.16em] text-[#8a919c]">
            Business OS
          </div>
        </div>
      </Link>

      <Link
        href="/"
        className="rounded-xl border border-[#dfe3e8] bg-white px-4 py-2.5 text-xs font-black text-[#202329] transition hover:border-[#e5232e] hover:text-[#e5232e]"
      >
        Kembali
      </Link>
    </header>
  );
}







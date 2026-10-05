"use client";

import {
  ArrowLeft,
  ArrowRight,
  Search,
} from "lucide-react";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import Link from "next/link";

import BusinessCard from "@/components/business/BusinessCard";
import { searchMarketplaceBusinesses } from "@/lib/api";
import { Business } from "@/types/marketplace";

export default function SearchResults() {
  const params = useSearchParams();
  const q = params.get("q") || "";
  const normalized = q.trim();

  const [matchedBusinesses, setMatchedBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function runSearch() {
      setLoading(true);

      try {
        const results =
          await searchMarketplaceBusinesses(normalized);

        if (!cancelled) {
          setMatchedBusinesses(results);
        }
      } catch (error) {
        console.error(
          "Marketplace search failed:",
          error
        );

        if (!cancelled) {
          setMatchedBusinesses([]);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    runSearch();

    return () => {
      cancelled = true;
    };
  }, [normalized]);

  const hasResults = matchedBusinesses.length > 0;

  return (
    <main className="bg-[#f8f9fb]">
      <div className="container py-10 sm:py-14">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-xs font-bold text-[#727a85] transition hover:text-[#e5232e]"
        >
          <ArrowLeft size={14} />
          Kembali ke Marketplace
        </Link>

        <div className="mt-7">
          <div className="nd-section-label">
            Pencarian Marketplace
          </div>

          <h1 className="mt-2 text-3xl font-black tracking-tight text-[#17191d] sm:text-4xl">
            Hasil pencarian
          </h1>

          <p className="mt-2 text-sm text-[#747c87]">
            {q
              ? `Menampilkan hasil untuk "${q}"`
              : "Jelajahi seluruh usaha yang tersedia di marketplace."}
          </p>
        </div>

        <div className="mt-8">
          {loading && (
            <section>
              <ResultHeading
                title="Mencari usaha"
                count={0}
              />

              <div className="mt-4 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
                {Array.from({ length: 6 }).map((_, index) => (
                  <div
                    key={index}
                    className="nd-card h-64 animate-pulse bg-white"
                  />
                ))}
              </div>
            </section>
          )}

          {!loading && hasResults && (
            <section>
              <ResultHeading
                title="Usaha ditemukan"
                count={matchedBusinesses.length}
              />

              <div className="mt-4 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
                {matchedBusinesses.map((business) => (
                  <BusinessCard
                    key={business.id}
                    business={business}
                  />
                ))}
              </div>
            </section>
          )}

          {!loading && !hasResults && (
            <div className="nd-card p-10 text-center sm:p-16">
              <div className="mx-auto grid size-14 place-items-center rounded-2xl bg-red-50 text-[#e5232e]">
                <Search size={23} />
              </div>

              <h2 className="mt-5 text-xl font-black text-[#202329]">
                Belum menemukan usaha.
              </h2>

              <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#7b838e]">
                Coba gunakan nama usaha, jenis produk,
                layanan, kategori, atau bidang usaha yang ingin
                Anda cari.
              </p>

              <Link
                href="/"
                className="mt-6 inline-flex items-center gap-2 rounded-xl bg-[#e5232e] px-6 py-3 text-sm font-extrabold text-white transition hover:opacity-90"
              >
                Kembali ke Marketplace
                <ArrowRight size={15} />
              </Link>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}

function ResultHeading({
  title,
  count,
}: {
  title: string;
  count: number;
}) {
  return (
    <div className="flex items-center gap-3">
      <h2 className="text-xl font-black text-[#202329]">
        {title}
      </h2>

      {count > 0 && (
        <span className="rounded-full bg-white px-2.5 py-1 text-[10px] font-bold text-[#8a919c] shadow-sm">
          {count}
        </span>
      )}
    </div>
  );
}

"use client";

import Image from "next/image";
import {
  ArrowRight,
  BriefcaseBusiness,
  Search,
  ShoppingBasket,
  Users,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

export default function SearchHero() {
  const router = useRouter();
  const [query, setQuery] = useState("");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const q = query.trim();

    router.push(
      q ? `/search?q=${encodeURIComponent(q)}` : "/search"
    );
  }

  return (
    <section className="relative isolate overflow-hidden">
      <div className="absolute inset-0 -z-10">
        <Image
          src="/header.png"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover object-center"
        />

        <div className="absolute inset-0 bg-black/50" />
        <div className="absolute inset-0 bg-gradient-to-b from-black/70 via-black/30 to-black/75" />
        <div className="absolute inset-0 bg-gradient-to-r from-black/45 via-transparent to-black/30" />
      </div>

      <div className="container">
        <div className="flex min-h-[calc(100svh-72px)] flex-col items-center justify-center py-16 text-center sm:min-h-[700px] lg:min-h-[730px]">
          <div className="inline-flex items-center gap-2 rounded-full border border-white/25 bg-black/25 px-4 py-2 text-[10px] font-extrabold uppercase tracking-[0.2em] text-white backdrop-blur-md sm:text-[11px]">
            <span className="size-1.5 rounded-full bg-[#ff4b55] shadow-[0_0_12px_rgba(255,75,85,.8)]" />
            Marketplace UMKM Indonesia
          </div>

          <h1 className="mt-6 max-w-5xl text-4xl font-black leading-[1.02] tracking-[-0.045em] text-white drop-shadow-[0_5px_20px_rgba(0,0,0,.35)] sm:text-5xl md:text-6xl lg:text-7xl">
            Cari produk, layanan,
            <br />
            atau{" "}
            <span className="text-[#ff4651]">
              peluang usaha.
            </span>
          </h1>

          <p className="mt-6 max-w-2xl text-sm leading-7 text-white/85 drop-shadow-md sm:text-base lg:text-lg">
            Temukan usaha, produk, layanan, dan peluang bisnis
            dari UMKM di berbagai daerah Indonesia.
          </p>

          <form
            onSubmit={submit}
            className="mt-9 flex w-full max-w-4xl flex-col gap-2 rounded-2xl border border-white/25 bg-white/95 p-2 shadow-[0_25px_80px_rgba(0,0,0,.32)] backdrop-blur-md sm:flex-row"
          >
            <div className="flex min-w-0 flex-1 items-center gap-3 px-3">
              <Search
                size={21}
                className="shrink-0 text-[#858d98]"
              />

              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Cari usaha, produk, layanan, atau kebutuhan..."
                className="nd-input min-h-[48px] min-w-0 flex-1 bg-transparent text-[16px] text-[#202329] placeholder:text-[#949ba5] sm:text-sm"
                aria-label="Cari marketplace"
              />
            </div>

            <button
              type="submit"
              className="nd-red-gradient flex min-h-[48px] items-center justify-center gap-2 rounded-xl px-7 text-sm font-extrabold text-white transition hover:brightness-95 active:scale-[.99]"
            >
              Cari
              <ArrowRight size={16} />
            </button>
          </form>

          <div className="mt-5 flex max-w-4xl flex-wrap justify-center gap-2">
            <span className="px-1 py-2 text-xs font-semibold text-white/60">
              Jelajahi:
            </span>

            {[
              "Produk",
              "Layanan",
              "Usaha",
              "Kuliner",
              "Kebutuhan Bisnis",
            ].map((tag) => (
              <button
                key={tag}
                type="button"
                onClick={() =>
                  router.push(
                    `/search?q=${encodeURIComponent(tag)}`
                  )
                }
                className="min-h-[36px] rounded-full border border-white/20 bg-black/20 px-3.5 py-2 text-xs font-semibold text-white/90 backdrop-blur-sm transition hover:border-white/40 hover:bg-white hover:text-[#e5232e]"
              >
                {tag}
              </button>
            ))}
          </div>

          <div className="mt-10 grid w-full max-w-4xl gap-3 sm:grid-cols-3">
            <QuickIntent
              icon={<ShoppingBasket size={19} />}
              title="Cari Produk"
              description="Temukan barang & kebutuhan"
              query="Produk"
              onSearch={(value) =>
                router.push(`/search?q=${encodeURIComponent(value)}`)
              }
            />

            <QuickIntent
              icon={<Users size={19} />}
              title="Cari UMKM"
              description="Temukan pelaku usaha"
              query=""
              onSearch={() => router.push("/search")}
            />

            <QuickIntent
              icon={<BriefcaseBusiness size={19} />}
              title="Cari Layanan"
              description="Temukan jasa & layanan"
              query="Layanan"
              onSearch={(value) =>
                router.push(`/search?q=${encodeURIComponent(value)}`)
              }
            />
          </div>

          <div className="mt-10 hidden items-center gap-3 text-[10px] font-bold uppercase tracking-[0.2em] text-white/50 sm:flex">
            <span className="h-px w-8 bg-white/25" />
            Indonesia • Nasional
            <span className="h-px w-8 bg-white/25" />
          </div>
        </div>
      </div>
    </section>
  );
}

function QuickIntent({
  icon,
  title,
  description,
  onSearch,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  query: string;
  onSearch: (value: string) => void;
}) {
  return (
    <button
      type="button"
      onClick={() => onSearch(title)}
      className="group flex min-h-[72px] items-center gap-3 rounded-2xl border border-white/20 bg-black/25 px-5 py-4 text-left shadow-lg backdrop-blur-md transition hover:-translate-y-1 hover:border-white/35 hover:bg-black/35"
    >
      <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-white text-[#e5232e] shadow-sm transition group-hover:scale-105">
        {icon}
      </span>

      <span>
        <span className="block text-sm font-extrabold text-white">
          {title}
        </span>

        <span className="mt-0.5 block text-xs text-white/60">
          {description}
        </span>
      </span>
    </button>
  );
}

"use client";

import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  Menu,
  Store,
  X
} from "lucide-react";
import { useEffect, useState } from "react";

const marketplaceUrl =
  process.env.NEXT_PUBLIC_MARKETPLACE_URL ?? "http://localhost:3004";

const businessUrl = "/mulai";

export default function Header() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10);

    window.addEventListener("scroll", onScroll);

    return () => {
      window.removeEventListener("scroll", onScroll);
    };
  }, []);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";

    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  function closeMenu() {
    setOpen(false);
  }

  return (
    <>
      <header
        className={[
          "sticky top-0 z-[60] border-b border-[#e7e9ed] bg-white/95 backdrop-blur-xl transition-shadow",
          scrolled ? "shadow-sm" : ""
        ].join(" ")}
      >
        <div className="container flex h-[72px] items-center justify-between gap-4">
          <Link
            href="/"
            aria-label="NUSA-DHIPA"
            onClick={closeMenu}
            className="shrink-0"
          >
            <Image
              src="/logo.png"
              alt="NUSA-DHIPA"
              width={190}
              height={64}
              priority
              className="h-auto max-h-[52px] w-[145px] object-contain object-left sm:w-[175px]"
            />
          </Link>

          <nav className="hidden items-center gap-7 lg:flex">
            <Link
              href="#ekosistem"
              className="nd-link text-sm font-bold text-[#535b66]"
            >
              Ekosistem
            </Link>

            <Link
              href="#solusi"
              className="nd-link text-sm font-bold text-[#535b66]"
            >
              Solusi
            </Link>

            <Link
              href={marketplaceUrl}
              className="nd-link text-sm font-bold text-[#535b66]"
            >
              Marketplace
            </Link>
          </nav>

          <div className="flex items-center gap-2">
            <Link
              href={marketplaceUrl}
              className="hidden h-10 items-center gap-2 rounded-xl border border-[#e1e4e8] px-4 text-sm font-bold text-[#3d434b] transition hover:border-[#e5232e] hover:text-[#e5232e] sm:flex"
            >
              Marketplace
            </Link>

            <Link
              href={businessUrl}
              className="hidden h-10 items-center gap-2 rounded-xl bg-[#e5232e] px-4 text-sm font-extrabold text-white shadow-sm transition hover:bg-[#c91621] sm:flex"
            >
              <Store size={16} />
              Punya Usaha?
            </Link>

            <button
              type="button"
              onClick={() => setOpen(!open)}
              aria-expanded={open}
              aria-label={open ? "Tutup menu" : "Buka menu"}
              className="grid size-10 place-items-center rounded-xl border border-[#e1e4e8] text-[#30353c] lg:hidden"
            >
              {open ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </header>

      {open && (
        <div className="fixed inset-0 z-50 bg-black/30 lg:hidden">
          <button
            type="button"
            aria-label="Tutup menu"
            onClick={closeMenu}
            className="absolute inset-0 cursor-default"
          />

          <aside className="absolute right-0 top-0 flex h-full w-[min(88vw,380px)] flex-col bg-white shadow-2xl">
            <div className="flex h-[72px] items-center justify-between border-b border-[#e7e9ed] px-5">
              <Image
                src="/logo.png"
                alt="NUSA-DHIPA"
                width={170}
                height={58}
                className="h-auto w-[145px]"
              />

              <button
                type="button"
                onClick={closeMenu}
                aria-label="Tutup menu"
                className="grid size-10 place-items-center rounded-xl border border-[#e1e4e8]"
              >
                <X size={19} />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-5 py-6">
              <div className="mb-4 text-[10px] font-extrabold uppercase tracking-[0.2em] text-[#a0a6af]">
                NUSA-DHIPA
              </div>

              <MobileLink href="#ekosistem" onClick={closeMenu}>
                Ekosistem
              </MobileLink>

              <MobileLink href="#solusi" onClick={closeMenu}>
                Solusi
              </MobileLink>

              <MobileLink href={marketplaceUrl} onClick={closeMenu}>
                Marketplace
              </MobileLink>

              <div className="my-7 h-px bg-[#edf0f2]" />

              <Link
                href={businessUrl}
                onClick={closeMenu}
                className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#e5232e] py-3.5 text-sm font-extrabold text-white"
              >
                <Store size={17} />
                Punya Usaha?
              </Link>

              <Link
                href={marketplaceUrl}
                onClick={closeMenu}
                className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl border border-[#e1e4e8] py-3.5 text-sm font-extrabold text-[#30353c]"
              >
                Jelajahi Marketplace
                <ArrowRight size={17} />
              </Link>

              <div className="mt-6 rounded-2xl bg-[#f8f9fb] p-4">
                <div className="text-xs font-black text-[#202329]">
                  Bangun bisnis Anda di NUSA-DHIPA
                </div>

                <p className="mt-1 text-xs leading-5 text-[#7c848f]">
                  Kelola usaha, tampil di marketplace, dan temukan
                  peluang pasar dalam satu ekosistem.
                </p>
              </div>
            </div>

            <div className="border-t border-[#e7e9ed] px-5 py-4 text-[10px] text-[#a0a6af]">
              Ekosistem Digital UMKM Indonesia
            </div>
          </aside>
        </div>
      )}
    </>
  );
}

function MobileLink({
  href,
  onClick,
  children
}: {
  href: string;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className="flex min-h-[52px] items-center justify-between border-b border-[#eef0f2] text-sm font-bold text-[#30353c]"
    >
      {children}
      <ArrowRight size={17} className="text-[#a0a6af]" />
    </Link>
  );
}



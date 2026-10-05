"use client";

import Link from "next/link";
import {
  CheckCircle2,
  ShieldCheck,
} from "lucide-react";

export default function VerifyPage() {
  return (
    <main className="min-h-screen bg-slate-50">
      <div className="mx-auto max-w-2xl px-5 py-16">

        <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-xl">

          <div className="bg-slate-950 p-8 text-white">
            <div className="flex items-center gap-3">

              <ShieldCheck className="h-8 w-8" />

              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-white/60">
                  NUSA-DHIPA
                </p>

                <h1 className="text-2xl font-bold">
                  Business Verification
                </h1>
              </div>

            </div>
          </div>

          <div className="p-8">

            <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6">

              <div className="flex items-center gap-3">

                <CheckCircle2 className="h-8 w-8 text-emerald-600" />

                <div>
                  <p className="text-xs font-bold uppercase tracking-wider text-emerald-700">
                    Verified Business
                  </p>

                  <h2 className="text-xl font-bold text-emerald-950">
                    NUSA-DHIPA VERIFIED
                  </h2>
                </div>

              </div>

            </div>

            <div className="mt-8 rounded-2xl bg-slate-50 p-6">

              <p className="text-sm text-slate-500">
                Verification Code
              </p>

              <p className="mt-2 font-mono font-bold text-slate-900">
                Database verification pending
              </p>

              <p className="mt-2 text-sm text-slate-500">
                Halaman ini akan menampilkan data bisnis
                setelah verification service terhubung.
              </p>

            </div>

            <Link
              href="/"
              className="mt-8 inline-flex rounded-xl bg-slate-950 px-5 py-3 font-semibold text-white"
            >
              Kembali ke NUSA-DHIPA
            </Link>

          </div>
        </div>
      </div>
    </main>
  );
}
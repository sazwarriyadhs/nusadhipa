"use client";

import { FormEvent, useState } from "react";

export default function KontakPage() {
  const [sent, setSent] = useState(false);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSent(true);
  }

  return (
    <main className="min-h-screen bg-[#f7f8fa]">
      <section className="container py-16 sm:py-24">
        <div className="grid gap-10 lg:grid-cols-[.8fr_1.2fr]">
          <div>
            <div className="nd-section-label">
              HUBUNGI KAMI
            </div>

            <h1 className="mt-4 text-4xl font-black sm:text-5xl">
              Mari bicara tentang bisnis Anda.
            </h1>

            <p className="mt-5 leading-8 text-[#68707d]">
              Ceritakan kebutuhan Anda. Mulai dari legalitas,
              digitalisasi operasional, marketplace sampai
              integrasi teknologi.
            </p>
          </div>

          <div className="nd-card p-7 sm:p-9">
            {sent ? (
              <div className="py-12 text-center">
                <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-[#fff1f2] text-2xl font-black text-[#e5232e]">
                  ✓
                </div>

                <h2 className="mt-5 text-2xl font-black">
                  Terima kasih.
                </h2>

                <p className="mt-3 text-[#68707d]">
                  Permintaan Anda sudah dicatat di sisi
                  frontend. Endpoint lead backend dapat
                  dihubungkan pada tahap berikutnya.
                </p>
              </div>
            ) : (
              <form
                onSubmit={submit}
                className="space-y-5"
              >
                <div>
                  <label className="text-sm font-extrabold">
                    Nama
                  </label>

                  <input
                    required
                    name="name"
                    className="nd-input mt-2 w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="Nama Anda"
                  />
                </div>

                <div>
                  <label className="text-sm font-extrabold">
                    Email
                  </label>

                  <input
                    required
                    type="email"
                    name="email"
                    className="nd-input mt-2 w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="email@contoh.com"
                  />
                </div>

                <div>
                  <label className="text-sm font-extrabold">
                    Kebutuhan
                  </label>

                  <textarea
                    required
                    name="message"
                    rows={5}
                    className="nd-input mt-2 w-full rounded-xl border border-[#e7e9ed] bg-white px-4 py-3"
                    placeholder="Ceritakan kebutuhan bisnis Anda..."
                  />
                </div>

                <button
                  type="submit"
                  className="w-full rounded-xl bg-[#e5232e] px-6 py-3.5 font-extrabold text-white transition hover:bg-[#c91621]"
                >
                  Kirim Permintaan
                </button>
              </form>
            )}
          </div>
        </div>
      </section>
    </main>
  );
}

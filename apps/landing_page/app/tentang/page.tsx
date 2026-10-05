import Link from "next/link";

export default function TentangPage() {
  return (
    <main className="min-h-screen bg-[#f7f8fa]">
      <section className="container py-20 sm:py-28">
        <div className="max-w-4xl">
          <div className="nd-section-label">
            TENTANG NUSA-DHIPA
          </div>

          <h1 className="mt-4 text-4xl font-black tracking-tight text-[#202329] sm:text-6xl">
            Ekosistem digital untuk bisnis Indonesia.
          </h1>

          <p className="mt-7 max-w-3xl text-lg leading-8 text-[#68707d]">
            NUSA-DHIPA dirancang untuk menghubungkan kebutuhan
            bisnis dari fondasi legalitas sampai operasional
            digital dan marketplace.
          </p>
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {[
            ["01", "Foundation", "Legalitas dan struktur dasar bisnis."],
            ["02", "Operation", "Tools untuk menjalankan bisnis sehari-hari."],
            ["03", "Growth", "Marketplace, data dan AI untuk ekspansi."],
          ].map(([number, title, text]) => (
            <article
              key={number}
              className="nd-card nd-card-hover p-7"
            >
              <div className="text-sm font-black text-[#e5232e]">
                {number}
              </div>

              <h2 className="mt-5 text-2xl font-black">
                {title}
              </h2>

              <p className="mt-3 leading-7 text-[#68707d]">
                {text}
              </p>
            </article>
          ))}
        </div>

        <div className="mt-12">
          <Link
            href="/kontak"
            className="font-extrabold text-[#e5232e]"
          >
            Hubungi NUSA-DHIPA →
          </Link>
        </div>
      </section>
    </main>
  );
}

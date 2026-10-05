import Link from "next/link";
import BackendStatus from "../../components/BackendStatus";

const modules = [
  ["Business", "Profil, identitas, dan struktur bisnis."],
  ["Catalog", "Produk, layanan, harga, dan katalog."],
  ["Legal", "Data dan proses pendukung legalitas usaha."],
  ["Marketplace", "Distribusi bisnis dan produk ke pelanggan."],
  ["Analytics", "Data operasional untuk membantu pengambilan keputusan."],
  ["AI", "Otomasi dan intelligence untuk pertumbuhan bisnis."],
];

export default function BusinessOSPage() {
  return (
    <main className="min-h-screen bg-[#f7f8fa]">
      <section className="bg-[#17191d] text-white">
        <div className="container py-20 sm:py-28">
          <div className="max-w-4xl">
            <div className="text-xs font-extrabold uppercase tracking-[.2em] text-[#ff7b83]">
              NUSA-DHIPA BUSINESS OS
            </div>

            <h1 className="mt-4 text-4xl font-black tracking-tight sm:text-6xl">
              Satu operating system untuk bisnis.
            </h1>

            <p className="mt-6 max-w-3xl text-lg leading-8 text-white/65">
              Kelola fondasi bisnis, katalog, legalitas,
              marketplace, data dan AI dari satu ekosistem.
            </p>

            <div className="mt-8">
              <BackendStatus />
            </div>
          </div>
        </div>
      </section>

      <section className="container py-14">
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {modules.map(([title, text], index) => (
            <article
              key={title}
              className="nd-card nd-card-hover p-7"
            >
              <div className="text-xs font-black tracking-[.16em] text-[#e5232e]">
                MODULE {String(index + 1).padStart(2, "0")}
              </div>

              <h2 className="mt-4 text-2xl font-black">
                {title}
              </h2>

              <p className="mt-3 leading-7 text-[#68707d]">
                {text}
              </p>
            </article>
          ))}
        </div>

        <div className="mt-12 text-center">
          <Link
            href="/kontak"
            className="inline-flex rounded-xl bg-[#e5232e] px-7 py-3.5 font-extrabold text-white"
          >
            Bangun Bisnis Anda
          </Link>
        </div>
      </section>
    </main>
  );
}


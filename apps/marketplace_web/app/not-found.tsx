import Link from "next/link";

export default function NotFound() {
  return (
    <main className="min-h-screen bg-[#f8f9fb]">
      <div className="container flex min-h-screen items-center justify-center py-16">
        <div className="nd-card w-full max-w-lg p-10 text-center sm:p-14">
          <div className="mx-auto grid size-16 place-items-center rounded-2xl bg-red-50 text-2xl font-black text-[#e5232e]">
            404
          </div>

          <h1 className="mt-6 text-2xl font-black tracking-tight text-[#17191d] sm:text-3xl">
            Halaman tidak ditemukan
          </h1>

          <p className="mx-auto mt-3 max-w-md text-sm leading-6 text-[#747c87]">
            Halaman yang Anda cari tidak tersedia atau sudah dipindahkan.
          </p>

          <Link
            href="/"
            className="mt-7 inline-flex rounded-xl bg-[#e5232e] px-6 py-3 text-sm font-extrabold text-white transition hover:opacity-90"
          >
            Kembali ke Marketplace
          </Link>
        </div>
      </div>
    </main>
  );
}

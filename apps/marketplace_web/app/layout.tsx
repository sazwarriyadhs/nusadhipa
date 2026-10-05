import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NUSA-DHIPA Marketplace | UMKM Indonesia",
  description:
    "Marketplace UMKM Indonesia untuk menemukan produk, layanan, usaha, dan peluang bisnis dari berbagai daerah.",
  icons: {
    icon: "/logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}

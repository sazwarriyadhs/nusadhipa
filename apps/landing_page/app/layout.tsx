import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NUSA-DHIPA — Ekosistem Digital UMKM",
  description:
    "NUSA-DHIPA membantu bisnis membangun, mengelola, dan mengembangkan usaha melalui satu ekosistem digital.",
  keywords: [
    "NUSA-DHIPA",
    "UMKM",
    "Business OS",
    "Marketplace",
    "Legalitas",
    "Indonesia"
  ],
  openGraph: {
    title: "NUSA-DHIPA — Ekosistem Digital UMKM",
    description:
      "Bangun bisnis. Kelola lebih mudah. Tumbuh lebih jauh.",
    type: "website"
  }
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}

"use client";

import "./globals.css";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Activity,
  BarChart3,
  Building2,
  ClipboardList,
  FileCheck2,
  LayoutDashboard,
  LogOut,
  Menu,
  Package,
  Settings,
  ShieldCheck,
  ShoppingCart,
  Users,
  WalletCards,
  X,
} from "lucide-react";
import { useState } from "react";

type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ size?: number; strokeWidth?: number }>;
};

const mainItems: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/users", label: "Users", icon: Users },
  { href: "/tenants", label: "Tenants / UMKM", icon: Building2 },
  { href: "/marketplace", label: "Marketplace", icon: Package },
  { href: "/orders", label: "Orders", icon: ShoppingCart },
  { href: "/legal", label: "Legal", icon: FileCheck2 },
  { href: "/pricing", label: "Pricing", icon: WalletCards },
  { href: "/subscriptions", label: "Subscriptions", icon: ClipboardList },
  { href: "/reports", label: "Reports", icon: BarChart3 },
];

const systemItems: NavItem[] = [
  { href: "/system", label: "System Health", icon: Activity },
  { href: "/audit", label: "Audit Logs", icon: ShieldCheck },
  { href: "/settings", label: "Settings", icon: Settings },
];

function NavItemView({
  item,
  onNavigate,
}: {
  item: NavItem;
  onNavigate: () => void;
}) {
  const pathname = usePathname();
  const Icon = item.icon;

  const active =
    pathname === item.href ||
    (item.href !== "/dashboard" && pathname.startsWith(`${item.href}/`));

  return (
    <Link
      href={item.href}
      onClick={onNavigate}
      className={`nav-item${active ? " active" : ""}`}
    >
      <span className="nav-icon">
        <Icon size={18} strokeWidth={1.9} />
      </span>
      <span className="nav-label">{item.label}</span>
    </Link>
  );
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const [mobileOpen, setMobileOpen] = useState(false);

  const closeMobile = () => setMobileOpen(false);

  return (
    <html lang="en">
      <body>
        <div className="admin-shell">

          {mobileOpen && (
            <button
              type="button"
              className="mobile-backdrop"
              aria-label="Close navigation"
              onClick={closeMobile}
            />
          )}

          <aside className={`sidebar${mobileOpen ? " mobile-open" : ""}`}>

            <div className="sidebar-brand">
              <Link
                href="/dashboard"
                className="brand-link"
                onClick={closeMobile}
              >
                <Image
                  src="/logo.png"
                  alt="NUSA-DHIPA"
                  width={190}
                  height={72}
                  priority
                  className="brand-logo"
                />
              </Link>

              <button
                type="button"
                className="mobile-close"
                aria-label="Close menu"
                onClick={closeMobile}
              >
                <X size={20} />
              </button>

              <div className="brand-tagline">
                Merajut Kearifan Lokal Nusantara
              </div>
            </div>

            <div className="sidebar-scroll">

              <section className="nav-section">
                <div className="nav-section-title">
                  CONTROL PANEL
                </div>

                <nav className="sidebar-nav" aria-label="Control Panel">
                  {mainItems.map((item) => (
                    <NavItemView
                      key={item.href}
                      item={item}
                      onNavigate={closeMobile}
                    />
                  ))}
                </nav>
              </section>

              <section className="nav-section">
                <div className="nav-section-title">
                  SYSTEM
                </div>

                <nav className="sidebar-nav" aria-label="System">
                  {systemItems.map((item) => (
                    <NavItemView
                      key={item.href}
                      item={item}
                      onNavigate={closeMobile}
                    />
                  ))}
                </nav>
              </section>

            </div>

            <div className="sidebar-footer">
              <div className="admin-profile">
                <div className="admin-avatar">
                  A
                </div>

                <div className="admin-profile-copy">
                  <strong>Administrator</strong>
                  <span>System Admin</span>
                </div>
              </div>

              <button
                type="button"
                className="signout-button"
              >
                <LogOut size={16} strokeWidth={1.9} />
                <span>Sign out</span>
              </button>
            </div>

          </aside>

          <div className="admin-main">

            <header className="topbar">

              <div className="topbar-left">
                <button
                  type="button"
                  className="menu-button"
                  aria-label="Open navigation"
                  onClick={() => setMobileOpen(true)}
                >
                  <Menu size={21} strokeWidth={2} />
                </button>

                <div className="topbar-heading">
                  <span className="topbar-title">
                    NUSA-DHIPA
                  </span>

                  <span className="topbar-subtitle">
                    Admin Control Panel
                  </span>
                </div>
              </div>

              <div className="topbar-right">

                <div className="gateway-status">
                  <span className="status-dot healthy" />
                  <span>Gateway</span>
                  <strong>:8300</strong>
                </div>

                <div className="topbar-divider" />

                <div className="topbar-admin">
                  <div className="topbar-avatar">
                    A
                  </div>

                  <div className="topbar-admin-copy">
                    <strong>Administrator</strong>
                    <span>System Admin</span>
                  </div>
                </div>

              </div>

            </header>

            <main className="content">
              {children}
            </main>

          </div>

        </div>
      </body>
    </html>
  );
}



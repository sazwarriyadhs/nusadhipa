"use client";

import Link from "next/link";
import {
  Activity,
  ArrowUpRight,
  BarChart3,
  Building2,
  CheckCircle2,
  CircleDollarSign,
  ClipboardList,
  Package,
  ShoppingCart,
  Users,
} from "lucide-react";

const stats = [
  {
    label: "Total UMKM",
    value: "1,248",
    change: "+12.4%",
    icon: Building2,
  },
  {
    label: "Mobile Users",
    value: "8,642",
    change: "+8.7%",
    icon: Users,
  },
  {
    label: "Orders",
    value: "3,426",
    change: "+15.2%",
    icon: ShoppingCart,
  },
  {
    label: "Revenue",
    value: "Rp 184.6M",
    change: "+10.8%",
    icon: CircleDollarSign,
  },
];

const registrations = [
  {
    business: "Raja Telur",
    owner: "Muhammad Rizky",
    category: "Retail",
    status: "Verified",
  },
  {
    business: "RM Abah Kenari",
    owner: "Abdul Rochmat",
    category: "Restaurant",
    status: "Active",
  },
  {
    business: "Bogor Fresh Mart",
    owner: "Siti Aminah",
    category: "Retail",
    status: "Pending",
  },
  {
    business: "Kopi Cimahpar",
    owner: "Dimas Pratama",
    category: "Food & Beverage",
    status: "Verified",
  },
];

const services = [
  { name: "API Gateway", port: ":8300", status: "Healthy" },
  { name: "Auth", port: ":8301", status: "Healthy" },
  { name: "Tenant", port: ":8302", status: "Healthy" },
  { name: "Business", port: ":8303", status: "Healthy" },
  { name: "Catalog", port: ":8304", status: "Healthy" },
  { name: "Order", port: ":8305", status: "Pending" },
  { name: "Legal", port: ":8327", status: "Healthy" },
];

const shortcuts = [
  {
    href: "/users",
    title: "Manage Users",
    description: "Mobile users, owners, staff and administrators",
    icon: Users,
  },
  {
    href: "/tenants",
    title: "Manage UMKM",
    description: "Businesses, branches and verification",
    icon: Building2,
  },
  {
    href: "/orders",
    title: "Manage Orders",
    description: "Monitor marketplace transactions",
    icon: ShoppingCart,
  },
  {
    href: "/marketplace",
    title: "Marketplace",
    description: "Products, services and moderation",
    icon: Package,
  },
];

function StatusBadge({ status }: { status: string }) {
  const normalized = status.toLowerCase();

  return (
    <span className={`status-badge ${normalized}`}>
      <span className="status-badge-dot" />
      {status}
    </span>
  );
}

export default function DashboardPage() {
  return (
    <div className="dashboard-page">

      <section className="dashboard-header">
        <div className="dashboard-header-copy">
          <div className="eyebrow">
            OVERVIEW
          </div>

          <h1>
            Dashboard
          </h1>

          <p>
            Monitor the NUSA-DHIPA Business OS platform
            from one control panel.
          </p>
        </div>

        <div className="platform-label">
          <span>Platform</span>
          <strong>Bogor Ecosystem</strong>
        </div>
      </section>

      <section className="stat-grid" aria-label="Platform statistics">
        {stats.map((stat) => {
          const Icon = stat.icon;

          return (
            <article className="stat-card" key={stat.label}>

              <div className="stat-card-top">
                <div className="stat-card-icon">
                  <Icon size={19} strokeWidth={1.9} />
                </div>

                <span className="stat-card-change">
                  {stat.change}
                </span>
              </div>

              <div className="stat-card-label">
                {stat.label}
              </div>

              <div className="stat-card-value">
                {stat.value}
              </div>

            </article>
          );
        })}
      </section>

      <section className="dashboard-grid">

        <article className="panel-card registrations-panel">

          <div className="panel-header">
            <div>
              <div className="panel-kicker">
                BUSINESS
              </div>

              <h2>
                Recent Registrations
              </h2>
            </div>

            <Link href="/tenants" className="panel-link">
              View all
              <ArrowUpRight size={14} />
            </Link>
          </div>

          <div className="table-wrap">
            <table className="dashboard-table">
              <thead>
                <tr>
                  <th>Business</th>
                  <th>Owner</th>
                  <th>Category</th>
                  <th>Status</th>
                </tr>
              </thead>

              <tbody>
                {registrations.map((row) => (
                  <tr key={row.business}>
                    <td>
                      <strong>{row.business}</strong>
                    </td>
                    <td>{row.owner}</td>
                    <td>{row.category}</td>
                    <td>
                      <StatusBadge status={row.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

        </article>

        <article className="panel-card">

          <div className="panel-header">
            <div>
              <div className="panel-kicker">
                INFRASTRUCTURE
              </div>

              <h2>
                Platform Status
              </h2>
            </div>

            <Link href="/system" className="panel-link">
              Details
              <ArrowUpRight size={14} />
            </Link>
          </div>

          <div className="health-list">
            {services.map((service) => (
              <div className="health-row" key={service.name}>

                <div className="health-service-copy">
                  <strong>{service.name}</strong>
                  <span>{service.port}</span>
                </div>

                <StatusBadge status={service.status} />

              </div>
            ))}
          </div>

        </article>

      </section>

      <section className="quick-section">

        <div className="section-heading">
          <div>
            <div className="panel-kicker">
              SHORTCUTS
            </div>

            <h2>
              Quick Access
            </h2>
          </div>
        </div>

        <div className="quick-actions">
          {shortcuts.map((shortcut) => {
            const Icon = shortcut.icon;

            return (
              <Link
                href={shortcut.href}
                className="quick-action"
                key={shortcut.href}
              >
                <div className="quick-action-icon">
                  <Icon size={19} strokeWidth={1.9} />
                </div>

                <div className="quick-action-copy">
                  <strong>{shortcut.title}</strong>
                  <span>{shortcut.description}</span>
                </div>

                <ArrowUpRight
                  className="quick-action-arrow"
                  size={16}
                  strokeWidth={1.9}
                />
              </Link>
            );
          })}
        </div>

      </section>

    </div>
  );
}

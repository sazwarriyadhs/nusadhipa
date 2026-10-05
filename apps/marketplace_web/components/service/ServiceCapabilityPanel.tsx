"use client";

import { useState } from "react";

interface Capability {
  capability: string;
  label: string;
  description?: string | null;
  sort_order: number;
}

interface Props {
  businessId: string;
  businessName: string;
  capabilities: Capability[];
  whatsapp?: string;
  phone?: string;
  email?: string;
}

const API_BASE =
  process.env.NEXT_PUBLIC_MARKETPLACE_API_URL ||
  "http://localhost:8300";

export default function ServiceCapabilityPanel({
  businessId,
  businessName,
  capabilities,
  whatsapp,
  phone,
  email,
}: Props) {
  const [active, setActive] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");

  const [form, setForm] = useState({
    customer_name: "",
    customer_whatsapp: "",
    customer_email: "",
    brief: "",
    budget: "",
    deadline: "",
    notes: "",
  });

  const submit = async () => {
    setError("");

    if (
      !form.customer_name.trim() ||
      !form.customer_whatsapp.trim() ||
      !form.brief.trim()
    ) {
      setError("Nama, WhatsApp, dan kebutuhan wajib diisi.");
      return;
    }

    setLoading(true);

    try {
      const response = await fetch(
        `${API_BASE}/api/v1/marketplace/businesses/${businessId}/service-quotes`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(form),
        }
      );

      const json = await response.json();

      if (!response.ok) {
        throw new Error(
          json?.message ||
            json?.error?.message ||
            json?.error ||
            "Permintaan gagal dikirim."
        );
      }

      setSent(true);
      setForm({
        customer_name: "",
        customer_whatsapp: "",
        customer_email: "",
        brief: "",
        budget: "",
        deadline: "",
        notes: "",
      });
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Permintaan gagal dikirim."
      );
    } finally {
      setLoading(false);
    }
  };

  const contact = () => {
    if (whatsapp) {
      const number = whatsapp.replace(/[^\d]/g, "");
      window.open(`https://wa.me/${number}`, "_blank");
    } else if (phone) {
      window.location.href = `tel:${phone}`;
    } else if (email) {
      window.location.href = `mailto:${email}`;
    } else {
      setActive("contact");
    }
  };

  return (
    <section className="mt-10">
      <div className="rounded-3xl border border-black/10 bg-white p-6 shadow-sm md:p-8">
        <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
          LAYANAN USAHA
        </div>

        <h2 className="mt-2 text-2xl font-black">
          Layanan {businessName}
        </h2>

        <p className="mt-2 text-sm leading-6 text-black/55">
          Pilihan layanan disesuaikan dengan bidang usaha,
          KBLI, dan kemampuan usaha.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-3">
          {capabilities.map((item) => (
            <button
              key={item.capability}
              type="button"
              onClick={() => {
                if (item.capability === "contact") {
                  contact();
                } else {
                  setActive(item.capability);
                  setSent(false);
                  setError("");
                }
              }}
              className={`rounded-2xl border p-5 text-left transition ${
                active === item.capability
                  ? "border-[#e5232e] bg-[#fff7f7]"
                  : "border-black/10 bg-[#fafafa] hover:border-black/20"
              }`}
            >
              <div className="font-black">{item.label}</div>

              {item.description && (
                <div className="mt-2 text-sm leading-5 text-black/50">
                  {item.description}
                </div>
              )}
            </button>
          ))}
        </div>

        {sent && (
          <div className="mt-6 rounded-2xl bg-green-50 p-5">
            <div className="font-black text-green-800">
              Permintaan berhasil dikirim.
            </div>

            <div className="mt-1 text-sm text-green-700">
              {businessName} akan menindaklanjuti kebutuhan Anda.
            </div>
          </div>
        )}

        {active === "contact" && (
          <div className="mt-6 rounded-2xl bg-[#f7f7f7] p-5">
            <div className="font-black">Hubungi Usaha</div>

            <p className="mt-1 text-sm text-black/55">
              Silakan gunakan informasi kontak yang tersedia
              pada profil usaha.
            </p>
          </div>
        )}

        {(active === "quotation" || active === "consultation") && (
          <div className="mt-6 rounded-2xl border border-black/10 bg-[#fafafa] p-5 md:p-6">
            <div className="font-black">
              {active === "quotation"
                ? "Minta Penawaran"
                : "Konsultasi"}
            </div>

            <div className="mt-5 grid gap-4 md:grid-cols-2">
              <input
                value={form.customer_name}
                onChange={(e) =>
                  setForm({
                    ...form,
                    customer_name: e.target.value,
                  })
                }
                placeholder="Nama"
                className="rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <input
                value={form.customer_whatsapp}
                onChange={(e) =>
                  setForm({
                    ...form,
                    customer_whatsapp: e.target.value,
                  })
                }
                placeholder="WhatsApp"
                className="rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <input
                value={form.customer_email}
                onChange={(e) =>
                  setForm({
                    ...form,
                    customer_email: e.target.value,
                  })
                }
                placeholder="Email (opsional)"
                className="rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <input
                value={form.budget}
                onChange={(e) =>
                  setForm({
                    ...form,
                    budget: e.target.value,
                  })
                }
                placeholder="Budget (opsional)"
                className="rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <input
                value={form.deadline}
                onChange={(e) =>
                  setForm({
                    ...form,
                    deadline: e.target.value,
                  })
                }
                placeholder="Target waktu (opsional)"
                className="rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <textarea
                value={form.brief}
                onChange={(e) =>
                  setForm({
                    ...form,
                    brief: e.target.value,
                  })
                }
                placeholder="Jelaskan kebutuhan Anda..."
                rows={5}
                className="md:col-span-2 rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />

              <textarea
                value={form.notes}
                onChange={(e) =>
                  setForm({
                    ...form,
                    notes: e.target.value,
                  })
                }
                placeholder="Catatan tambahan (opsional)"
                rows={3}
                className="md:col-span-2 rounded-xl border border-black/10 bg-white px-4 py-3 text-sm"
              />
            </div>

            {error && (
              <div className="mt-4 rounded-xl bg-red-50 p-4 text-sm font-semibold text-red-700">
                {error}
              </div>
            )}

            <button
              type="button"
              onClick={submit}
              disabled={loading}
              className="mt-5 rounded-xl bg-[#e5232e] px-6 py-3 text-sm font-black text-white disabled:opacity-50"
            >
              {loading
                ? "Mengirim..."
                : active === "quotation"
                  ? "Kirim Permintaan Penawaran"
                  : "Kirim Permintaan Konsultasi"}
            </button>
          </div>
        )}
      </div>
    </section>
  );
}

"use client";

import { useMemo, useState } from "react";

interface Product {
  id: string;
  name: string;
  unit?: string;
  selling_price?: number;
  price?: number;
  available_quantity?: number;
}

interface Props {
  businessId: string;
  businessName: string;
  products: Product[];
}

function formatPrice(value: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(value);
}

export default function OrderForm({
  businessId,
  businessName,
  products,
}: Props) {
  const [productId, setProductId] = useState(products[0]?.id ?? "");
  const [quantity, setQuantity] = useState(1);
  const [name, setName] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [address, setAddress] = useState("");
  const [note, setNote] = useState("");
  const [payment, setPayment] = useState<"COD" | "TRANSFER">("COD");
  const [submitted, setSubmitted] = useState(false);

  const selectedProduct = products.find(
    (product) => product.id === productId
  );

  const price =
    selectedProduct?.selling_price ??
    selectedProduct?.price ??
    0;

  const maxStock = selectedProduct?.available_quantity ?? 999999;

  const subtotal = price * quantity;

  const deliveryFee = subtotal >= 100000 ? 0 : 10000;

  const total = subtotal + deliveryFee;

  const canOrder = useMemo(() => {
    return (
      !!selectedProduct &&
      quantity >= 1 &&
      quantity <= maxStock &&
      name.trim().length >= 2 &&
      whatsapp.trim().length >= 8 &&
      address.trim().length >= 5
    );
  }, [
    selectedProduct,
    quantity,
    maxStock,
    name,
    whatsapp,
    address,
  ]);

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!canOrder || !selectedProduct) return;

    const orderPayload = {
      business_id: businessId,
      business_name: businessName,
      customer_name: name.trim(),
      whatsapp: whatsapp.trim(),
      delivery_address: address.trim(),
      note: note.trim(),
      payment_method: payment,
      items: [
        {
          product_id: selectedProduct.id,
          product_name: selectedProduct.name,
          quantity,
          unit: selectedProduct.unit ?? "unit",
          unit_price: price,
          subtotal,
        },
      ],
      subtotal,
      delivery_fee: deliveryFee,
      total,
    };

    console.log("NUSA-DHIPA ORDER", orderPayload);

    setSubmitted(true);
  }

  if (submitted) {
    return (
      <section className="mt-10 rounded-3xl border border-emerald-200 bg-emerald-50 p-6 md:p-8">
        <div className="text-xs font-black uppercase tracking-[0.2em] text-emerald-700">
          ORDER BERHASIL
        </div>

        <h2 className="mt-2 text-2xl font-black text-emerald-950">
          Pesanan berhasil dicatat
        </h2>

        <p className="mt-2 text-sm text-emerald-800">
          Terima kasih, {name}. Detail pesanan kamu:
        </p>

        <div className="mt-6 rounded-2xl bg-white p-5">
          <div className="flex justify-between gap-4 text-sm">
            <span>{selectedProduct?.name}</span>
            <span className="font-bold">
              {quantity} × {formatPrice(price)}
            </span>
          </div>

          <div className="mt-3 text-xs text-black/50">
            Pembayaran: {payment}
          </div>

          <div className="mt-4 border-t pt-4">
            <div className="flex justify-between text-sm">
              <span>Subtotal</span>
              <span>{formatPrice(subtotal)}</span>
            </div>

            <div className="mt-2 flex justify-between text-sm">
              <span>Ongkir</span>
              <span>
                {deliveryFee === 0
                  ? "GRATIS"
                  : formatPrice(deliveryFee)}
              </span>
            </div>

            <div className="mt-3 flex justify-between text-lg font-black">
              <span>Total</span>
              <span className="text-[#e5232e]">
                {formatPrice(total)}
              </span>
            </div>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setSubmitted(false)}
          className="mt-5 rounded-xl bg-[#17191d] px-5 py-3 text-sm font-black text-white hover:bg-[#e5232e]"
        >
          Buat Pesanan Lagi
        </button>
      </section>
    );
  }

  if (products.length === 0) {
    return null;
  }

  return (
    <section
      id="order"
      className="mt-10 rounded-3xl border border-black/10 bg-white p-6 shadow-sm md:p-8"
    >
      <div>
        <div className="text-xs font-black uppercase tracking-[0.2em] text-[#e5232e]">
          ORDER SEKARANG
        </div>

        <h2 className="mt-1 text-2xl font-black">
          Pesan dari {businessName}
        </h2>

        <p className="mt-2 text-sm text-black/50">
          Pilih produk, jumlah, dan isi data pengiriman.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="mt-7 space-y-5">
        <div>
          <label className="mb-2 block text-sm font-black">
            Produk
          </label>

          <select
            value={productId}
            onChange={(event) => {
              setProductId(event.target.value);
              setQuantity(1);
            }}
            className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm font-semibold outline-none focus:border-[#e5232e]"
          >
            {products.map((product) => {
              const productPrice =
                product.selling_price ??
                product.price ??
                0;

              return (
                <option key={product.id} value={product.id}>
                  {product.name} — {formatPrice(productPrice)} /{" "}
                  {product.unit ?? "unit"}
                </option>
              );
            })}
          </select>
        </div>

        <div>
          <label className="mb-2 block text-sm font-black">
            Jumlah
          </label>

          <input
            type="number"
            min={1}
            max={maxStock}
            value={quantity}
            onChange={(event) => {
              const value = Number(event.target.value);

              setQuantity(
                Math.min(
                  maxStock,
                  Math.max(1, value || 1)
                )
              );
            }}
            className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm font-semibold outline-none focus:border-[#e5232e]"
          />

          <div className="mt-1 text-xs text-black/40">
            Stok tersedia: {maxStock}
          </div>
        </div>

        <div className="grid gap-5 md:grid-cols-2">
          <div>
            <label className="mb-2 block text-sm font-black">
              Nama Pemesan
            </label>

            <input
              type="text"
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Nama lengkap"
              className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm outline-none focus:border-[#e5232e]"
              required
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-black">
              WhatsApp
            </label>

            <input
              type="tel"
              value={whatsapp}
              onChange={(event) =>
                setWhatsapp(event.target.value)
              }
              placeholder="+62 812..."
              className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm outline-none focus:border-[#e5232e]"
              required
            />
          </div>
        </div>

        <div>
          <label className="mb-2 block text-sm font-black">
            Alamat Pengiriman
          </label>

          <textarea
            value={address}
            onChange={(event) => setAddress(event.target.value)}
            placeholder="Alamat lengkap pengiriman"
            rows={3}
            className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm outline-none focus:border-[#e5232e]"
            required
          />
        </div>

        <div>
          <label className="mb-2 block text-sm font-black">
            Catatan
          </label>

          <textarea
            value={note}
            onChange={(event) => setNote(event.target.value)}
            placeholder="Contoh: kirim sore hari"
            rows={2}
            className="w-full rounded-xl border border-black/10 bg-[#f7f7f7] px-4 py-3 text-sm outline-none focus:border-[#e5232e]"
          />
        </div>

        <div>
          <label className="mb-3 block text-sm font-black">
            Metode Pembayaran
          </label>

          <div className="grid gap-3 sm:grid-cols-2">
            <button
              type="button"
              onClick={() => setPayment("COD")}
              className={`rounded-xl border px-4 py-3 text-sm font-black ${
                payment === "COD"
                  ? "border-[#e5232e] bg-[#fff1f2] text-[#e5232e]"
                  : "border-black/10 bg-[#f7f7f7] text-black/50"
              }`}
            >
              COD
            </button>

            <button
              type="button"
              onClick={() => setPayment("TRANSFER")}
              className={`rounded-xl border px-4 py-3 text-sm font-black ${
                payment === "TRANSFER"
                  ? "border-[#e5232e] bg-[#fff1f2] text-[#e5232e]"
                  : "border-black/10 bg-[#f7f7f7] text-black/50"
              }`}
            >
              Transfer
            </button>
          </div>
        </div>

        <div className="rounded-2xl bg-[#f7f7f7] p-5">
          <div className="flex justify-between text-sm text-black/55">
            <span>Harga</span>
            <span>{formatPrice(price)}</span>
          </div>

          <div className="mt-2 flex justify-between text-sm text-black/55">
            <span>Jumlah</span>
            <span>{quantity}</span>
          </div>

          <div className="mt-2 flex justify-between text-sm text-black/55">
            <span>Subtotal</span>
            <span>{formatPrice(subtotal)}</span>
          </div>

          <div className="mt-2 flex justify-between text-sm text-black/55">
            <span>Ongkir</span>
            <span>
              {deliveryFee === 0
                ? "GRATIS"
                : formatPrice(deliveryFee)}
            </span>
          </div>

          <div className="mt-4 flex justify-between border-t border-black/10 pt-4 text-xl font-black">
            <span>Total</span>
            <span className="text-[#e5232e]">
              {formatPrice(total)}
            </span>
          </div>
        </div>

        <button
          type="submit"
          disabled={!canOrder}
          className="w-full rounded-xl bg-[#e5232e] py-4 text-sm font-black text-white shadow-lg transition hover:bg-[#c91d27] disabled:cursor-not-allowed disabled:opacity-40"
        >
          PESAN SEKARANG →
        </button>
      </form>
    </section>
  );
}

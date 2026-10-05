import { useMemo, useState, type ReactNode } from "react";
import {
  ArrowLeft,
  Banknote,
  BarChart3,
  Calculator,
  CheckCircle2,
  ChevronRight,
  Clock3,
  CreditCard,
  FileText,
  LayoutDashboard,
  Minus,
  Plus,
  Printer,
  Receipt,
  RefreshCw,
  Search,
  ShoppingCart,
  Store,
  Table2,
  Trash2,
  UtensilsCrossed,
  WalletCards,
  X,
} from "lucide-react";

type Page =
  | "Transaksi"
  | "Meja"
  | "Hold Order"
  | "Pembayaran"
  | "Struk"
  | "Closing Shift";

type Category = "Semua" | "Makanan" | "Minuman";

type MenuItem = {
  id: number;
  name: string;
  category: Exclude<Category, "Semua">;
  price: number;
  image?: string;
};

type CartItem = MenuItem & {
  qty: number;
};

type HeldOrder = {
  id: string;
  table: string;
  items: CartItem[];
  total: number;
  createdAt: string;
};

const MENU: MenuItem[] = [
  { id: 1,  name: "Ikan Bakar Etong", category: "Makanan", price: 39000 },
  { id: 2,  name: "Sambal Goreng Hati Ampela", category: "Makanan", price: 15000 },
  { id: 3,  name: "Bakakak Ayam Kampung", category: "Makanan", price: 75000 },
  { id: 4,  name: "Sambal Hijau", category: "Makanan", price: 8000 },
  { id: 5,  name: "Ayam Bakar", category: "Makanan", price: 25000 },
  { id: 6,  name: "Sambal Kacang", category: "Makanan", price: 8000 },
  { id: 7,  name: "Ikan Nila", category: "Makanan", price: 35000 },
  { id: 8,  name: "Sambal Bawang", category: "Makanan", price: 8000 },
  { id: 9,  name: "Entog", category: "Makanan", price: 35000 },
  { id: 10, name: "Lalapan Sayuran", category: "Makanan", price: 10000 },
  { id: 11, name: "Nasi Liwet", category: "Makanan", price: 12000 },
  { id: 12, name: "Sayur Asem", category: "Makanan", price: 10000 },
  { id: 13, name: "Gado Gado", category: "Makanan", price: 15000 },
  { id: 14, name: "Sate Sapi", category: "Makanan", price: 30000 },
  { id: 15, name: "Sate Kambing Muda", category: "Makanan", price: 35000 },
  { id: 16, name: "Tahu Goreng", category: "Makanan", price: 8000 },
  { id: 17, name: "Gulai Kepala Kambing", category: "Makanan", price: 40000 },
  { id: 18, name: "Tumis Kangkung", category: "Makanan", price: 12000 },
  { id: 19, name: "Ikan Bumbu Kuning", category: "Makanan", price: 35000 },
  { id: 20, name: "Ayam Serundeng", category: "Makanan", price: 25000 },
  { id: 21, name: "Nasi Bakar", category: "Makanan", price: 18000 },
  { id: 22, name: "Air Mineral", category: "Minuman", price: 6000 },
  { id: 23, name: "Sate Ayam", category: "Makanan", price: 20000 },
  { id: 24, name: "Ikan Kembung Bumbu Rujak", category: "Makanan", price: 30000 },
  { id: 25, name: "Sayur Kuah Kuning", category: "Makanan", price: 12000 },
  { id: 26, name: "Tempe", category: "Makanan", price: 8000 },
  { id: 27, name: "Tumis Buncis Jagung Muda", category: "Makanan", price: 15000 },
  { id: 28, name: "Sambal Tomat", category: "Makanan", price: 8000 },
];

const TABLES = Array.from({ length: 12 }, (_, index) => ({
  id: index + 1,
  name: `Meja ${index + 1}`,
  status: index < 3 ? "occupied" : index === 3 ? "reserved" : "available",
}));

const initialCart: CartItem[] = [
  { ...MENU[0], qty: 2 },
  { ...MENU[1], qty: 1 },
  { ...MENU[6], qty: 2 },
];

const initialHeldOrders: HeldOrder[] = [
  {
    id: "HOLD-001",
    table: "Meja 5",
    items: [{ ...MENU[3], qty: 2 }, { ...MENU[7], qty: 2 }],
    total: 70000,
    createdAt: "20:15",
  },
  {
    id: "HOLD-002",
    table: "Meja 8",
    items: [{ ...MENU[5], qty: 1 }, { ...MENU[6], qty: 2 }],
    total: 61000,
    createdAt: "20:27",
  },
];

const rupiah = (value: number) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(value);

function IconButton({
  children,
  onClick,
  title,
}: {
  children: ReactNode;
  onClick?: () => void;
  title?: string;
}) {
  return (
    <button className="icon-button" onClick={onClick} title={title}>
      {children}
    </button>
  );
}

function EmptyState({
  icon,
  title,
  description,
}: {
  icon: ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

function PageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow: string;
  title: string;
  description: string;
  actions?: ReactNode;
}) {
  return (
    <div className="page-header">
      <div>
        <div className="eyebrow">{eyebrow}</div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {actions && <div className="header-actions">{actions}</div>}
    </div>
  );
}







const MENU_IMAGES: Record<string, string> = {
  "Ikan Bakar Etong": "/menu/01_Ikan_Bakar_Etong.jpg",
  "Sambal Goreng Hati Ampela": "/menu/01_Sambal_Goreng_Hati_Ampela.jpg",
  "Bakakak Ayam Kampung": "/menu/02_Bakakak_Ayam_Kampung.jpg",
  "Sambal Hijau": "/menu/02_Sambal_Hijau.jpg",
  "Ayam Bakar": "/menu/03_Ayam_Bakar.jpg",
  "Sambal Kacang": "/menu/03_Sambal_Kacang.jpg",
  "Ikan Nila": "/menu/04_Ikan_Nila.jpg",
  "Sambal Bawang": "/menu/04_Sambal_Bawang.jpg",
  "Entog": "/menu/05_Entog.jpg",
  "Lalapan Sayuran": "/menu/05_Lalapan_Sayuran.jpg",
  "Nasi Liwet": "/menu/06_Nasi_Liwet.jpg",
  "Sayur Asem": "/menu/06_Sayur_Asem.jpg",
  "Gado Gado": "/menu/07_Gado_Gado.jpg",
  "Sate Sapi": "/menu/07_Sate_Sapi.jpg",
  "Sate Kambing Muda": "/menu/08_Sate_Kambing_Muda.jpg",
  "Tahu Goreng": "/menu/08_Tahu_Goreng.jpg",
  "Gulai Kepala Kambing": "/menu/09_Gulai_Kepala_Kambing.jpg",
  "Tumis Kangkung": "/menu/09_Tumis_Kangkung.jpg",
  "Ikan Bumbu Kuning": "/menu/10_Ikan_Bumbu_Kuning.jpg",
  "Ayam Serundeng": "/menu/11_Ayam_Serundeng.jpg",
  "Nasi Bakar": "/menu/12_Nasi_Bakar.jpg",
  "Air Mineral": "/menu/13_Air_Mineral.jpg",
  "Sate Ayam": "/menu/14_Sate_Ayam.jpg",
  "Ikan Kembung Bumbu Rujak": "/menu/15_Ikan_Kembung_Bumbu_Rujak.jpg",
  "Sayur Kuah Kuning": "/menu/16_Sayur_Kuah_Kuning.jpg",
  "Tempe": "/menu/16_Tempe.jpg",
  "Tumis Buncis Jagung Muda": "/menu/17_Tumis_Buncis_Jagung_Muda.jpg",
  "Sambal Tomat": "/menu/18_Sambal_Tomat.jpg",
};

function TransactionPage({
  selectedTable,
  setSelectedTable,
  cart,
  setCart,
  heldOrders,
  setHeldOrders,
  onNavigate,
}: {
  selectedTable: string;
  setSelectedTable: (value: string) => void;
  cart: CartItem[];
  setCart: (items: CartItem[]) => void;
  heldOrders: HeldOrder[];
  setHeldOrders: (orders: HeldOrder[]) => void;
  onNavigate: (page: Page) => void;
}) {
  const [category, setCategory] = useState<Category>("Semua");
  const [search, setSearch] = useState("");

  const filteredMenu = useMemo(() => {
    return MENU.filter((item) => {
      const matchCategory =
        category === "Semua" || item.category === category;
      const matchSearch = item.name
        .toLowerCase()
        .includes(search.toLowerCase());

      return matchCategory && matchSearch;
    });
  }, [category, search]);

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const totalQty = cart.reduce((sum, item) => sum + item.qty, 0);

  function addItem(item: MenuItem) {
    const exists = cart.find((cartItem) => cartItem.id === item.id);

    if (exists) {
      setCart(
        cart.map((cartItem) =>
          cartItem.id === item.id
            ? { ...cartItem, qty: cartItem.qty + 1 }
            : cartItem,
        ),
      );
      return;
    }

    setCart([...cart, { ...item, qty: 1 }]);
  }

  function decreaseItem(id: number) {
    setCart(
      cart
        .map((item) =>
          item.id === id ? { ...item, qty: item.qty - 1 } : item,
        )
        .filter((item) => item.qty > 0),
    );
  }

  function removeItem(id: number) {
    setCart(cart.filter((item) => item.id !== id));
  }

  function holdOrder() {
    if (!cart.length) {
      alert("Cart masih kosong.");
      return;
    }

    const nextId = `HOLD-${String(heldOrders.length + 1).padStart(3, "0")}`;

    setHeldOrders([
      ...heldOrders,
      {
        id: nextId,
        table: selectedTable,
        items: cart,
        total: subtotal,
        createdAt: new Date().toLocaleTimeString("id-ID", {
          hour: "2-digit",
          minute: "2-digit",
        }),
      },
    ]);

    setCart([]);
    alert(`${nextId} berhasil disimpan.`);
  }

  return (
    <div className="transaction-page">
      <PageHeader
        eyebrow="POINT OF SALE"
        title="Transaksi"
        description="Kelola pesanan meja, menu, dan pembayaran pelanggan."
        actions={
          <>
            <button
              className="btn btn-soft"
              onClick={() => onNavigate("Hold Order")}
            >
              <Clock3 size={17} />
              Hold Order
              {heldOrders.length > 0 && (
                <span className="badge">{heldOrders.length}</span>
              )}
            </button>
            <button
              className="btn btn-red"
              onClick={() => onNavigate("Pembayaran")}
              disabled={!cart.length}
            >
              <WalletCards size={17} />
              Bayar {cart.length ? rupiah(subtotal) : ""}
            </button>
          </>
        }
      />

      <div className="pos-grid">
        <section className="workspace">
          <div className="card table-card">
            <div className="card-heading">
              <div>
                <span className="section-label">AREA MEJA</span>
                <h2>Pilih Meja</h2>
              </div>

              <button
                className="link-button"
                onClick={() => onNavigate("Meja")}
              >
                Kelola Meja <ChevronRight size={15} />
              </button>
            </div>

            <div className="table-grid compact">
              {TABLES.map((table) => (
                <button
                  key={table.id}
                  className={`table-btn ${
                    selectedTable === table.name ? "active" : ""
                  }`}
                  onClick={() => setSelectedTable(table.name)}
                >
                  <Table2 size={17} />
                  <strong>{table.id}</strong>
                  <span>
                    {table.status === "available"
                      ? "Kosong"
                      : table.status === "occupied"
                        ? "Terisi"
                        : "Reservasi"}
                  </span>
                </button>
              ))}
            </div>
          </div>

          <div className="card menu-card">
            <div className="menu-toolbar">
              <div>
                <span className="section-label">KATALOG MENU</span>
                <h2>Pilih Menu</h2>
              </div>

              <label className="search">
                <Search size={17} />
                <input
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="Cari menu..."
                />
                {search && (
                  <IconButton
                    title="Hapus pencarian"
                    onClick={() => setSearch("")}
                  >
                    <X size={15} />
                  </IconButton>
                )}
              </label>
            </div>

            <div className="categories">
              {(["Semua", "Makanan", "Minuman"] as Category[]).map(
                (item) => (
                  <button
                    key={item}
                    className={`category ${category === item ? "active" : ""}`}
                    onClick={() => setCategory(item)}
                  >
                    {item}
                  </button>
                ),
              )}
            </div>

            <div className="menu-grid">
              {filteredMenu.map((item) => (
                <button
                  key={item.id}
                  className="menu-item"
                  onClick={() => addItem(item)}
                >
                  <div className="menu-image">
                    {item.image || MENU_IMAGES[item.name] ? (
                      <img
                        src={item.image || MENU_IMAGES[item.name]}
                        alt={item.name}
                        loading="lazy"
                      />
                    ) : (
                      <div className="menu-image-placeholder">
                        {item.category === "Makanan" ? (
                          <UtensilsCrossed size={24} />
                        ) : (
                          <Store size={24} />
                        )}
                      </div>
                    )}
                  </div>

                  <div className="menu-category">{item.category}</div>
                  <div className="menu-name">{item.name}</div>

                  <div className="menu-bottom">
                    <strong>{rupiah(item.price)}</strong>
                    <span className="add-btn">
                      <Plus size={17} />
                    </span>
                  </div>
                </button>
              ))}

              {!filteredMenu.length && (
                <div className="menu-empty">
                  Menu tidak ditemukan.
                </div>
              )}
            </div>
          </div>
        </section>

        <aside className="order-panel card">
          <div className="order-header">
            <div>
              <span className="section-label">CURRENT ORDER</span>
              <h2>Pesanan</h2>
            </div>

            <span className="order-number">
              {selectedTable}
            </span>
          </div>

          <div className="order-meta">
            <div>
              <span>Kasir</span>
              <strong>Deka</strong>
            </div>
            <div>
              <span>Item</span>
              <strong>{totalQty}</strong>
            </div>
          </div>

          <div className="order-list">
            {!cart.length ? (
              <EmptyState
                icon={<ShoppingCart size={25} />}
                title="Belum ada pesanan"
                description="Pilih menu untuk menambahkan item ke transaksi."
              />
            ) : (
              cart.map((item) => (
                <div className="order-item" key={item.id}>
                  <div className="order-item-top">
                    <div>
                      <strong>{item.name}</strong>
                      <span>{rupiah(item.price)}</span>
                    </div>

                    <IconButton
                      title="Hapus item"
                      onClick={() => removeItem(item.id)}
                    >
                      <Trash2 size={15} />
                    </IconButton>
                  </div>

                  <div className="order-item-bottom">
                    <div className="quantity">
                      <button onClick={() => decreaseItem(item.id)}>
                        <Minus size={14} />
                      </button>
                      <strong>{item.qty}</strong>
                      <button onClick={() => addItem(item)}>
                        <Plus size={14} />
                      </button>
                    </div>

                    <strong>
                      {rupiah(item.price * item.qty)}
                    </strong>
                  </div>
                </div>
              ))
            )}
          </div>

          <div className="order-summary">
            <div className="summary-row">
              <span>Subtotal</span>
              <strong>{rupiah(subtotal)}</strong>
            </div>

            <div className="summary-row">
              <span>Diskon</span>
              <strong>Rp0</strong>
            </div>

            <div className="summary-row">
              <span>Pajak / Service</span>
              <strong>Rp0</strong>
            </div>

            <div className="summary-row total">
              <span>Total</span>
              <strong>{rupiah(subtotal)}</strong>
            </div>
          </div>

          <div className="order-actions">
            <button
              className="btn btn-soft"
              onClick={() => setCart([])}
              disabled={!cart.length}
            >
              <Trash2 size={17} />
              Clear
            </button>

            <button
              className="btn btn-soft"
              onClick={holdOrder}
              disabled={!cart.length}
            >
              <Clock3 size={17} />
              Hold
            </button>

            <button
              className="btn btn-red pay"
              onClick={() => onNavigate("Pembayaran")}
              disabled={!cart.length}
            >
              <WalletCards size={18} />
              Bayar
            </button>
          </div>
        </aside>
      </div>
    </div>
  );
}

function MejaPage({
  selectedTable,
  setSelectedTable,
}: {
  selectedTable: string;
  setSelectedTable: (value: string) => void;
}) {
  return (
    <>
      <PageHeader
        eyebrow="TABLE MANAGEMENT"
        title="Meja"
        description="Pantau status meja RM Abah Kenari."
      />

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon red">
            <Table2 size={20} />
          </div>
          <div>
            <span>Total Meja</span>
            <strong>12</strong>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon green">
            <CheckCircle2 size={20} />
          </div>
          <div>
            <span>Meja Kosong</span>
            <strong>8</strong>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon orange">
            <UtensilsCrossed size={20} />
          </div>
          <div>
            <span>Sedang Terisi</span>
            <strong>3</strong>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon blue">
            <Clock3 size={20} />
          </div>
          <div>
            <span>Reservasi</span>
            <strong>1</strong>
          </div>
        </div>
      </div>

      <div className="card page-card">
        <div className="card-heading">
          <div>
            <span className="section-label">TABLE MAP</span>
            <h2>Status Meja</h2>
          </div>
        </div>

        <div className="table-grid large">
          {TABLES.map((table) => {
            const selected = selectedTable === table.name;

            return (
              <button
                key={table.id}
                className={`table-tile ${table.status} ${
                  selected ? "selected" : ""
                }`}
                onClick={() => setSelectedTable(table.name)}
              >
                <Table2 size={25} />
                <strong>{table.name}</strong>
                <span>
                  {table.status === "available"
                    ? "Kosong"
                    : table.status === "occupied"
                      ? "Sedang digunakan"
                      : "Reservasi"}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </>
  );
}

function HoldOrdersPage({
  heldOrders,
  setHeldOrders,
  setCart,
  setSelectedTable,
  onNavigate,
}: {
  heldOrders: HeldOrder[];
  setHeldOrders: (orders: HeldOrder[]) => void;
  setCart: (items: CartItem[]) => void;
  setSelectedTable: (table: string) => void;
  onNavigate: (page: Page) => void;
}) {
  function resume(order: HeldOrder) {
    setCart(order.items);
    setSelectedTable(order.table);
    setHeldOrders(heldOrders.filter((item) => item.id !== order.id));
    onNavigate("Transaksi");
  }

  return (
    <>
      <PageHeader
        eyebrow="ORDER MANAGEMENT"
        title="Hold Order"
        description="Pesanan yang ditunda dan siap dilanjutkan."
      />

      {!heldOrders.length ? (
        <div className="card page-card">
          <EmptyState
            icon={<Clock3 size={28} />}
            title="Tidak ada hold order"
            description="Semua pesanan yang sedang aktif sudah diproses."
          />
        </div>
      ) : (
        <div className="hold-grid">
          {heldOrders.map((order) => (
            <div className="card hold-card" key={order.id}>
              <div className="hold-top">
                <div>
                  <span className="section-label">{order.id}</span>
                  <h3>{order.table}</h3>
                </div>
                <span className="time-pill">
                  <Clock3 size={14} />
                  {order.createdAt}
                </span>
              </div>

              <div className="hold-items">
                {order.items.map((item) => (
                  <div key={item.id}>
                    <span>
                      {item.name} × {item.qty}
                    </span>
                    <strong>{rupiah(item.price * item.qty)}</strong>
                  </div>
                ))}
              </div>

              <div className="hold-total">
                <span>Total</span>
                <strong>{rupiah(order.total)}</strong>
              </div>

              <div className="hold-actions">
                <button
                  className="btn btn-soft"
                  onClick={() =>
                    setHeldOrders(
                      heldOrders.filter((item) => item.id !== order.id),
                    )
                  }
                >
                  <Trash2 size={16} />
                  Hapus
                </button>

                <button
                  className="btn btn-red"
                  onClick={() => resume(order)}
                >
                  <RefreshCw size={16} />
                  Lanjutkan
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}

function PaymentPage({
  cart,
  selectedTable,
  onSuccess,
  onNavigate,
}: {
  cart: CartItem[];
  selectedTable: string;
  onSuccess: (method: string) => void;
  onNavigate: (page: Page) => void;
}) {
  const [method, setMethod] = useState("Cash");
  const [cash, setCash] = useState("");
  const subtotal = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const cashValue = Number(cash || 0);
  const change = Math.max(cashValue - subtotal, 0);

  const methods = [
    {
      name: "Cash",
      icon: <Banknote size={22} />,
      description: "Pembayaran tunai",
    },
    {
      name: "QRIS",
      icon: <CreditCard size={22} />,
      description: "Scan QRIS",
    },
    {
      name: "Transfer",
      icon: <WalletCards size={22} />,
      description: "Transfer bank",
    },
  ];

  if (!cart.length) {
    return (
      <>
        <PageHeader
          eyebrow="PAYMENT"
          title="Pembayaran"
          description="Tidak ada transaksi aktif."
        />
        <div className="card page-card">
          <EmptyState
            icon={<WalletCards size={28} />}
            title="Cart kosong"
            description="Tambahkan menu terlebih dahulu sebelum melakukan pembayaran."
          />
          <div className="center-action">
            <button
              className="btn btn-red"
              onClick={() => onNavigate("Transaksi")}
            >
              <ArrowLeft size={17} />
              Kembali ke Transaksi
            </button>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader
        eyebrow="PAYMENT"
        title="Pembayaran"
        description={`Selesaikan pembayaran untuk ${selectedTable}.`}
        actions={
          <button
            className="btn btn-soft"
            onClick={() => onNavigate("Transaksi")}
          >
            <ArrowLeft size={17} />
            Kembali
          </button>
        }
      />

      <div className="payment-layout">
        <div className="card payment-card">
          <span className="section-label">METODE PEMBAYARAN</span>
          <h2>Pilih metode</h2>

          <div className="payment-methods">
            {methods.map((item) => (
              <button
                key={item.name}
                className={`payment-method ${
                  method === item.name ? "active" : ""
                }`}
                onClick={() => setMethod(item.name)}
              >
                <div className="payment-method-icon">
                  {item.icon}
                </div>
                <div>
                  <strong>{item.name}</strong>
                  <span>{item.description}</span>
                </div>
                {method === item.name && (
                  <CheckCircle2 size={20} className="payment-check" />
                )}
              </button>
            ))}
          </div>

          {method === "Cash" && (
            <div className="cash-section">
              <label>Uang diterima</label>
              <div className="money-input">
                <span>Rp</span>
                <input
                  value={cash}
                  onChange={(event) =>
                    setCash(event.target.value.replace(/\D/g, ""))
                  }
                  placeholder="0"
                  inputMode="numeric"
                />
              </div>

              <div className="quick-cash">
                {[50000, 100000, 150000, 200000].map((value) => (
                  <button
                    key={value}
                    onClick={() => setCash(String(value))}
                  >
                    {rupiah(value)}
                  </button>
                ))}
              </div>

              <div className="change-box">
                <span>Kembalian</span>
                <strong>{rupiah(change)}</strong>
              </div>
            </div>
          )}

          {method === "QRIS" && (
            <div className="payment-placeholder">
              <div className="qr-placeholder">
                <CreditCard size={35} />
              </div>
              <h3>QRIS siap digunakan</h3>
              <p>
                QR dinamis akan diintegrasikan dengan payment provider.
              </p>
            </div>
          )}

          {method === "Transfer" && (
            <div className="payment-placeholder">
              <div className="qr-placeholder">
                <WalletCards size={35} />
              </div>
              <h3>Transfer Bank</h3>
              <p>
                Rekening tujuan akan mengikuti konfigurasi bisnis.
              </p>
            </div>
          )}
        </div>

        <div className="card payment-summary-card">
          <span className="section-label">RINGKASAN</span>
          <h2>{selectedTable}</h2>

          <div className="payment-items">
            {cart.map((item) => (
              <div key={item.id}>
                <span>
                  {item.name} × {item.qty}
                </span>
                <strong>{rupiah(item.price * item.qty)}</strong>
              </div>
            ))}
          </div>

          <div className="payment-total">
            <span>Total pembayaran</span>
            <strong>{rupiah(subtotal)}</strong>
          </div>

          <button
            className="btn btn-red payment-submit"
            disabled={method === "Cash" && cashValue < subtotal}
            onClick={() => onSuccess(method)}
          >
            <CheckCircle2 size={18} />
            Konfirmasi Pembayaran
          </button>
        </div>
      </div>
    </>
  );
}

function ReceiptPage({
  lastReceipt,
}: {
  lastReceipt: {
    number: string;
    table: string;
    method: string;
    total: number;
  } | null;
}) {
  const printReceipt = () => window.print();

  return (
    <>
      <PageHeader
        eyebrow="RECEIPT"
        title="Struk"
        description="Cetak dan lihat kembali transaksi terakhir."
        actions={
          <button className="btn btn-red" onClick={printReceipt}>
            <Printer size={17} />
            Print Struk
          </button>
        }
      />

      <div className="receipt-layout">
        <div className="receipt-preview">
          <div className="receipt-paper">
            <div className="receipt-brand">
              <img
                src="/nusa-dhipa-logo.png"
                alt="NUSA-DHIPA BUSINESS OS"
              />
              <strong>RM ABAH KENARI</strong>
              <span>Rumah Makan</span>
            </div>

            <div className="receipt-divider" />

            {lastReceipt ? (
              <>
                <div className="receipt-meta">
                  <span>No. {lastReceipt.number}</span>
                  <span>{lastReceipt.table}</span>
                  <span>Kasir: Deka</span>
                </div>

                <div className="receipt-divider" />

                <div className="receipt-line">
                  <span>Transaksi</span>
                  <strong>{rupiah(lastReceipt.total)}</strong>
                </div>

                <div className="receipt-line">
                  <span>Pembayaran</span>
                  <strong>{lastReceipt.method}</strong>
                </div>

                <div className="receipt-divider" />

                <div className="receipt-total">
                  <span>TOTAL</span>
                  <strong>{rupiah(lastReceipt.total)}</strong>
                </div>
              </>
            ) : (
              <div className="receipt-empty">
                Belum ada transaksi selesai.
              </div>
            )}

            <div className="receipt-footer">
              Terima kasih telah berkunjung
            </div>
          </div>
        </div>

        <div className="card receipt-actions-card">
          <span className="section-label">TRANSACTION HISTORY</span>
          <h2>Reprint</h2>

          {lastReceipt ? (
            <>
              <div className="history-item">
                <div className="history-icon">
                  <Receipt size={18} />
                </div>
                <div>
                  <strong>{lastReceipt.number}</strong>
                  <span>
                    {lastReceipt.table} · {lastReceipt.method}
                  </span>
                </div>
                <strong>{rupiah(lastReceipt.total)}</strong>
              </div>

              <button
                className="btn btn-soft full-width"
                onClick={printReceipt}
              >
                <Printer size={17} />
                Cetak Ulang
              </button>
            </>
          ) : (
            <EmptyState
              icon={<Receipt size={26} />}
              title="Belum ada struk"
              description="Struk transaksi yang berhasil akan muncul di sini."
            />
          )}
        </div>
      </div>
    </>
  );
}

function ClosingShiftPage({
  onCloseShift,
}: {
  onCloseShift: () => void;
}) {
  const [cashActual, setCashActual] = useState("");

  const summary = [
    ["Saldo awal", "Rp500.000"],
    ["Penjualan Cash", "Rp1.250.000"],
    ["Penjualan QRIS", "Rp850.000"],
    ["Penjualan Transfer", "Rp400.000"],
    ["Total Penjualan", "Rp2.500.000"],
  ];

  return (
    <>
      <PageHeader
        eyebrow="SHIFT MANAGEMENT"
        title="Closing Shift"
        description="Periksa ringkasan kasir sebelum menutup shift."
      />

      <div className="closing-layout">
        <div className="card closing-card">
          <div className="shift-summary-head">
            <div className="stat-icon red">
              <Calculator size={21} />
            </div>
            <div>
              <span>SHIFT AKTIF</span>
              <strong>08:00 - 21:00</strong>
            </div>
          </div>

          <div className="closing-lines">
            {summary.map(([label, value]) => (
              <div
                className={`closing-line ${
                  label === "Total Penjualan" ? "strong" : ""
                }`}
                key={label}
              >
                <span>{label}</span>
                <strong>{value}</strong>
              </div>
            ))}
          </div>
        </div>

        <div className="card closing-card">
          <span className="section-label">CASH COUNT</span>
          <h2>Hitung Kas Fisik</h2>
          <p className="card-description">
            Masukkan jumlah kas aktual di laci kasir.
          </p>

          <label>Kas aktual</label>
          <div className="money-input">
            <span>Rp</span>
            <input
              value={cashActual}
              onChange={(event) =>
                setCashActual(event.target.value.replace(/\D/g, ""))
              }
              placeholder="0"
              inputMode="numeric"
            />
          </div>

          <div className="difference-box">
            <span>Expected Cash</span>
            <strong>Rp1.750.000</strong>
          </div>

          <button className="btn btn-red full-width" onClick={onCloseShift}>
            <CheckCircle2 size={18} />
            Tutup Shift
          </button>
        </div>
      </div>
    </>
  );
}

function App() {
  const [page, setPage] = useState<Page>("Transaksi");
  const [selectedTable, setSelectedTable] = useState("Meja 4");
  const [cart, setCart] = useState<CartItem[]>(initialCart);
  const [heldOrders, setHeldOrders] =
    useState<HeldOrder[]>(initialHeldOrders);

  const [lastReceipt, setLastReceipt] = useState<{
    number: string;
    table: string;
    method: string;
    total: number;
  } | null>(null);

  const [shiftOpen, setShiftOpen] = useState(true);

  function navigate(nextPage: Page) {
    setPage(nextPage);
  }

  function completePayment(method: string) {
    const total = cart.reduce(
      (sum, item) => sum + item.price * item.qty,
      0,
    );

    setLastReceipt({
      number: `INV-${Date.now().toString().slice(-6)}`,
      table: selectedTable,
      method,
      total,
    });

    setCart([]);
    setPage("Struk");
  }

  function closeShift() {
    setShiftOpen(false);
    alert("Shift kasir berhasil ditutup.");
  }

  const navigation = [
    {
      label: "OPERASIONAL",
      items: [
        {
          page: "Transaksi" as Page,
          icon: <ShoppingCart size={18} />,
        },
        {
          page: "Meja" as Page,
          icon: <Table2 size={18} />,
        },
        {
          page: "Hold Order" as Page,
          icon: <Clock3 size={18} />,
          count: heldOrders.length,
        },
      ],
    },
    {
      label: "PEMBAYARAN",
      items: [
        {
          page: "Pembayaran" as Page,
          icon: <WalletCards size={18} />,
        },
        {
          page: "Struk" as Page,
          icon: <Receipt size={18} />,
        },
      ],
    },
    {
      label: "SHIFT",
      items: [
        {
          page: "Closing Shift" as Page,
          icon: <BarChart3 size={18} />,
        },
      ],
    },
  ];

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <img
            src="/branding/logo_rm_kenari.jpg"
            alt="RM Abah Kenari"
            className="brand-logo brand-logo-kenari"
          />

          <div className="brand-divider" />

          <div className="business-name">
            <strong>RM ABAH KENARI</strong>
            <span>Cashier Desktop</span>
          </div>
        </div>

        <div className="topbar-right">
          <div className="shift-top">
            <Clock3 size={16} />
            <div>
              <span>SHIFT</span>
              <strong>{shiftOpen ? "08:00 - 21:00" : "CLOSED"}</strong>
            </div>
          </div>

          <div className="online">
            <span className="online-dot" />
            Online
          </div>

          <div className="cashier-profile">
            <div className="cashier-avatar">D</div>
            <div className="cashier-info">
              <strong>Deka</strong>
              <span>CASHIER</span>
            </div>
          </div>
        </div>
      </header>

      <div className="app-body">
        <aside className="sidebar">
          <div className="sidebar-business">
            <div className="sidebar-business-icon">
              <Store size={19} />
            </div>
            <div>
              <strong>RM Abah Kenari</strong>
              <span>Bogor</span>
            </div>
          </div>

          {navigation.map((group) => (
            <div className="sidebar-section" key={group.label}>
              <div className="sidebar-label">{group.label}</div>

              {group.items.map((item) => (
                <button
                  key={item.page}
                  className={`nav-item ${
                    page === item.page ? "active" : ""
                  }`}
                  onClick={() => navigate(item.page)}
                >
                  <span className="nav-icon">{item.icon}</span>
                  <span>{item.page}</span>
                  {item.count ? (
                    <span className="nav-count">{item.count}</span>
                  ) : null}
                </button>
              ))}
            </div>
          ))}

          <div className="sidebar-bottom">
            <div className={`shift-card ${shiftOpen ? "" : "closed"}`}>
              <div className="shift-card-head">
                <span className="shift-status">
                  <span />
                  {shiftOpen ? "SHIFT AKTIF" : "SHIFT CLOSED"}
                </span>
                <Clock3 size={16} />
              </div>

              <strong>{shiftOpen ? "08:00 - 21:00" : "--:--"}</strong>

              <button onClick={() => navigate("Closing Shift")}>
                {shiftOpen ? "Closing Shift" : "Buka Shift"}
                <ChevronRight size={15} />
              </button>
            </div>
          </div>
        </aside>

        <main className="main">
          {page === "Transaksi" && (
            <TransactionPage
              selectedTable={selectedTable}
              setSelectedTable={setSelectedTable}
              cart={cart}
              setCart={setCart}
              heldOrders={heldOrders}
              setHeldOrders={setHeldOrders}
              onNavigate={navigate}
            />
          )}

          {page === "Meja" && (
            <MejaPage
              selectedTable={selectedTable}
              setSelectedTable={setSelectedTable}
            />
          )}

          {page === "Hold Order" && (
            <HoldOrdersPage
              heldOrders={heldOrders}
              setHeldOrders={setHeldOrders}
              setCart={setCart}
              setSelectedTable={setSelectedTable}
              onNavigate={navigate}
            />
          )}

          {page === "Pembayaran" && (
            <PaymentPage
              cart={cart}
              selectedTable={selectedTable}
              onSuccess={completePayment}
              onNavigate={navigate}
            />
          )}

          {page === "Struk" && (
            <ReceiptPage lastReceipt={lastReceipt} />
          )}

          {page === "Closing Shift" && (
            <ClosingShiftPage onCloseShift={closeShift} />
          )}
        </main>
      </div>
    </div>
  );
}

export default App;








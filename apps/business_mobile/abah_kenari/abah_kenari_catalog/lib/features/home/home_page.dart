import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/brand_header.dart';

enum TableStatus {
  available,
  occupied,
  paymentPending,
}

enum OrderStage {
  table,
  customer,
  menu,
  cart,
  kitchen,
  active,
  payment,
  success,
}

class RestaurantTable {
  final String number;
  final int capacity;
  TableStatus status;
  String? customer;

  RestaurantTable({
    required this.number,
    required this.capacity,
    required this.status,
    this.customer,
  });
}

class MenuItemData {
  final String name;
  final String category;
  final int price;
  final String description;
  int quantity;

  MenuItemData({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.quantity = 0,
  });
}

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({super.key});

  @override
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}

class _CatalogHomePageState extends State<CatalogHomePage> {
  OrderStage _stage = OrderStage.table;

  RestaurantTable? _selectedTable;
  String _customerName = '';
  String _category = 'Semua';
  String _search = '';
  String _paymentMethod = '';

  final TextEditingController _customerController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final List<RestaurantTable> _tables = [
    RestaurantTable(
      number: 'M01',
      capacity: 4,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M02',
      capacity: 4,
      status: TableStatus.occupied,
      customer: 'Budi Santoso',
    ),
    RestaurantTable(
      number: 'M03',
      capacity: 2,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M04',
      capacity: 4,
      status: TableStatus.paymentPending,
      customer: 'Ani',
    ),
    RestaurantTable(
      number: 'M05',
      capacity: 4,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M06',
      capacity: 4,
      status: TableStatus.occupied,
      customer: 'Rudi',
    ),
    RestaurantTable(
      number: 'M07',
      capacity: 2,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M08',
      capacity: 4,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M09',
      capacity: 6,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M10',
      capacity: 4,
      status: TableStatus.occupied,
      customer: 'Dedi',
    ),
    RestaurantTable(
      number: 'M11',
      capacity: 2,
      status: TableStatus.available,
    ),
    RestaurantTable(
      number: 'M12',
      capacity: 4,
      status: TableStatus.available,
    ),
  ];

  final List<MenuItemData> _menu = [
    MenuItemData(
      name: 'Nasi Ayam',
      category: 'Makanan',
      price: 25000,
      description: 'Nasi putih dengan ayam dan sambal khas.',
    ),
    MenuItemData(
      name: 'Nasi Goreng',
      category: 'Makanan',
      price: 22000,
      description: 'Nasi goreng spesial RM Abah Kenari.',
    ),
    MenuItemData(
      name: 'Ayam Bakar',
      category: 'Makanan',
      price: 35000,
      description: 'Ayam bakar dengan bumbu khas.',
    ),
    MenuItemData(
      name: 'Soto Ayam',
      category: 'Makanan',
      price: 28000,
      description: 'Soto ayam hangat lengkap dengan pelengkap.',
    ),
    MenuItemData(
      name: 'Es Teh',
      category: 'Minuman',
      price: 7000,
      description: 'Es teh manis segar.',
    ),
    MenuItemData(
      name: 'Es Jeruk',
      category: 'Minuman',
      price: 9000,
      description: 'Es jeruk segar.',
    ),
    MenuItemData(
      name: 'Paket Hemat',
      category: 'Paket',
      price: 45000,
      description: 'Paket makanan dan minuman pilihan.',
    ),
  ];

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _totalItems {
    return _menu.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  int get _subtotal {
    return _menu.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int get _service {
    if (_subtotal == 0) return 0;
    return (_subtotal * 5 / 100).round();
  }

  int get _grandTotal {
    return _subtotal + _service;
  }

  List<MenuItemData> get _filteredMenu {
    return _menu.where((item) {
      final categoryMatch =
          _category == 'Semua' || item.category == _category;

      final searchMatch =
          _search.isEmpty ||
          item.name.toLowerCase().contains(
                _search.toLowerCase(),
              );

      return categoryMatch && searchMatch;
    }).toList();
  }

  String _money(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  int _availableCount() {
    return _tables
        .where((table) => table.status == TableStatus.available)
        .length;
  }

  int _occupiedCount() {
    return _tables
        .where((table) => table.status == TableStatus.occupied)
        .length;
  }

  int _paymentCount() {
    return _tables
        .where(
          (table) => table.status == TableStatus.paymentPending,
        )
        .length;
  }

  void _selectTable(RestaurantTable table) {
    if (table.status != TableStatus.available) {
      _showTableInfo(table);
      return;
    }

    setState(() {
      _selectedTable = table;
      _stage = OrderStage.customer;
    });
  }

  void _showTableInfo(RestaurantTable table) {
    showDialog<void>(
      context: context,
      builder: (_) {
        final status = table.status == TableStatus.occupied
            ? 'SEDANG TERISI'
            : 'MENUNGGU PEMBAYARAN';

        return AlertDialog(
          title: Text(
            'Meja ${table.number}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$status\n\nCustomer: ${table.customer ?? '-'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('TUTUP'),
            ),
          ],
        );
      },
    );
  }

  void _startOrder() {
    final name = _customerController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama customer wajib diisi.'),
        ),
      );
      return;
    }

    setState(() {
      _customerName = name;
      _stage = OrderStage.menu;
    });
  }

  void _addItem(MenuItemData item) {
    setState(() {
      item.quantity++;
    });
  }

  void _removeItem(MenuItemData item) {
    if (item.quantity <= 0) return;

    setState(() {
      item.quantity--;
    });
  }

  void _sendToKitchen() {
    if (_totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada menu yang dipilih.'),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedTable case final table?) {
        table.status = TableStatus.occupied;
        table.customer = _customerName;
      }

      _stage = OrderStage.kitchen;
    });
  }

  void _openPayment() {
    if (_totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada menu untuk dibayar.'),
        ),
      );
      return;
    }

    setState(() {
      _paymentMethod = '';
      _stage = OrderStage.payment;
    });
  }

  void _pay() {
    if (_paymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran.'),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedTable case final table?) {
        table.status = TableStatus.paymentPending;
        table.customer = _customerName;
      }

      _stage = OrderStage.success;
    });
  }

  void _finish() {
    setState(() {
      if (_selectedTable case final table?) {
        table.status = TableStatus.available;
        table.customer = null;
      }

      for (final item in _menu) {
        item.quantity = 0;
      }

      _selectedTable = null;
      _customerName = '';
      _paymentMethod = '';
      _customerController.clear();
      _phoneController.clear();
      _stage = OrderStage.table;
    });
  }

  void _backToMenu() {
    setState(() {
      _stage = OrderStage.menu;
    });
  }

  void _backToCart() {
    setState(() {
      _stage = OrderStage.cart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            NusaDhipaBrandHeader(
              title: AppConstants.appName,
              subtitle:
                  '${AppConstants.appSubtitle} • ${AppConstants.location}',
            ),
            Expanded(
              child: _buildStage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case OrderStage.table:
        return _buildTablePage();
      case OrderStage.customer:
        return _buildCustomerPage();
      case OrderStage.menu:
        return _buildMenuPage();
      case OrderStage.cart:
        return _buildCartPage();
      case OrderStage.kitchen:
        return _buildKitchenPage();
      case OrderStage.active:
        return _buildActivePage();
      case OrderStage.payment:
        return _buildPaymentPage();
      case OrderStage.success:
        return _buildSuccessPage();
    }
  }

  Widget _page({
    required Widget child,
    Widget? bottom,
  }) {
    final children = <Widget>[
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            24,
          ),
          child: child,
        ),
      ),
    ];

    if (bottom != null) {
      children.add(bottom);
    }

    return Column(
      children: children,
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(AppConstants.text),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(AppConstants.muted),
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required String label,
    required String value,
    required IconData icon,
    required int color,
    required int background,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(background),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color(color).withValues(alpha: .15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color(color).withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Color(color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(color),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(AppConstants.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablePage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'Pilih Meja',
                'Pilih meja customer untuk memulai pesanan.',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _statusCard(
                    label: 'TERSEDIA',
                    value: '${_availableCount()}',
                    icon: Icons.check_circle_outline,
                    color: AppConstants.green,
                    background: AppConstants.greenSoft,
                  ),
                  const SizedBox(width: 12),
                  _statusCard(
                    label: 'TERISI',
                    value: '${_occupiedCount()}',
                    icon: Icons.people_outline,
                    color: AppConstants.primaryRed,
                    background: AppConstants.redSoft,
                  ),
                  const SizedBox(width: 12),
                  _statusCard(
                    label: 'MENUNGGU BAYAR',
                    value: '${_paymentCount()}',
                    icon: Icons.payments_outlined,
                    color: AppConstants.yellow,
                    background: AppConstants.yellowSoft,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 3
                          : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.28,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (_, index) {
                      return _tableCard(_tables[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableCard(RestaurantTable table) {
    final available =
        table.status == TableStatus.available;
    final pending =
        table.status == TableStatus.paymentPending;

    final color = available
        ? AppConstants.green
        : pending
            ? AppConstants.yellow
            : AppConstants.primaryRed;

    final bg = available
        ? AppConstants.greenSoft
        : pending
            ? AppConstants.yellowSoft
            : AppConstants.redSoft;

    final status = available
        ? 'TERSEDIA'
        : pending
            ? 'MENUNGGU BAYAR'
            : 'TERISI';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selectTable(table),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(AppConstants.line),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  table.number,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(AppConstants.text),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Color(bg),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(color),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 17,
                  color: Color(AppConstants.muted),
                ),
                const SizedBox(width: 5),
                Text(
                  '${table.capacity} Orang',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(AppConstants.muted),
                  ),
                ),
              ],
            ),
            if (table.customer != null) ...[
              const SizedBox(height: 4),
              Text(
                table.customer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(AppConstants.text),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerPage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 620,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(
                onPressed: () {
                  setState(() {
                    _stage = OrderStage.table;
                  });
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.redSoft),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_outlined,
                    color: Color(AppConstants.primaryRed),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'MEJA ${_selectedTable?.number ?? '-'}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${_selectedTable?.capacity ?? 0} Orang',
                  style: const TextStyle(
                    color: Color(AppConstants.muted),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _fieldLabel('Nama Customer *'),
              const SizedBox(height: 8),
              TextField(
                controller: _customerController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama customer',
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _fieldLabel('No. HP (Opsional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _startOrder,
                  icon: const Icon(
                    Icons.restaurant_menu,
                  ),
                  label: const Text(
                    'MULAI PESANAN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(AppConstants.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(AppConstants.text),
      ),
    );
  }

  Widget _backButton({
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back),
      label: const Text('KEMBALI'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(AppConstants.text),
        side: const BorderSide(
          color: Color(AppConstants.line),
        ),
      ),
    );
  }

  Widget _sessionHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(AppConstants.line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(AppConstants.redSoft),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.table_restaurant_outlined,
              color: Color(AppConstants.primaryRed),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Meja ${_selectedTable?.number ?? '-'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _customerName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(AppConstants.muted),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_totalItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(AppConstants.redSoft),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$_totalItems ITEM',
                style: const TextStyle(
                  color: Color(AppConstants.primaryRed),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuPage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sessionHeader(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _sectionTitle(
                      'Digital Menu',
                      'Pilih menu untuk $_customerName.',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _stage = OrderStage.cart;
                      });
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                    ),
                    label: Text(
                      '$_totalItems ITEM',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari menu...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Semua',
                    'Makanan',
                    'Minuman',
                    'Paket',
                  ].map((category) {
                    final selected =
                        _category == category;

                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _category = category;
                          });
                        },
                        selectedColor:
                            const Color(AppConstants.redSoft),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(
                                  AppConstants.primaryRed,
                                )
                              : const Color(
                                  AppConstants.muted,
                                ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.85,
                    ),
                    itemCount: _filteredMenu.length,
                    itemBuilder: (_, index) {
                      return _menuCard(
                        _filteredMenu[index],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottom: _cartBottomBar(),
    );
  }

  Widget _menuCard(MenuItemData item) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(AppConstants.line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(AppConstants.redSoft),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              color: Color(AppConstants.primaryRed),
              size: 32,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: Color(AppConstants.muted),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _money(item.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(AppConstants.primaryRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: () => _addItem(item),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(AppConstants.primaryRed),
                  foregroundColor: Colors.white,
                ),
              ),
              if (item.quantity > 0)
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(AppConstants.line),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_totalItems ITEM',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(AppConstants.muted),
                      ),
                    ),
                    Text(
                      _money(_subtotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _totalItems == 0
                      ? null
                      : () {
                          setState(() {
                            _stage = OrderStage.cart;
                          });
                        },
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                  ),
                  label: const Text(
                    'LIHAT PESANAN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(AppConstants.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPage() {
    final items = _menu
        .where((item) => item.quantity > 0)
        .toList();

    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(
                onPressed: _backToMenu,
              ),
              const SizedBox(height: 18),
              _sessionHeader(),
              const SizedBox(height: 22),
              _sectionTitle(
                'Pesanan Anda',
                'Periksa pesanan sebelum dikirim ke kitchen.',
              ),
              const SizedBox(height: 18),
              ...items.map(_cartItem),
              const SizedBox(height: 18),
              _summaryCard(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _sendToKitchen,
                  icon: const Icon(
                    Icons.send_outlined,
                  ),
                  label: const Text(
                    'KIRIM PESANAN KE KITCHEN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(AppConstants.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartItem(MenuItemData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(AppConstants.line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(AppConstants.redSoft),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: Color(AppConstants.primaryRed),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _money(item.price),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(AppConstants.muted),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeItem(item),
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: () => _addItem(item),
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(AppConstants.primaryRed),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              _money(item.price * item.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppConstants.line),
        ),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Subtotal',
            _money(_subtotal),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Service 5%',
            _money(_service),
          ),
          const Divider(height: 24),
          _summaryRow(
            'TOTAL',
            _money(_grandTotal),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight:
                bold ? FontWeight.w900 : FontWeight.w600,
            color: const Color(AppConstants.text),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 13,
            fontWeight:
                bold ? FontWeight.w900 : FontWeight.w700,
            color: bold
                ? const Color(AppConstants.primaryRed)
                : const Color(AppConstants.text),
          ),
        ),
      ],
    );
  }

  Widget _buildKitchenPage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Color(AppConstants.greenSoft),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(AppConstants.green),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'PESANAN TERKIRIM',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pesanan sudah masuk ke Kitchen.',
                style: TextStyle(
                  color: Color(AppConstants.muted),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _sessionHeader(),
              const SizedBox(height: 16),
              ..._menu
                  .where((item) => item.quantity > 0)
                  .map(
                    (item) => Container(
                      margin: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            AppConstants.line,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                              color: Color(
                                AppConstants.primaryRed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                          const Text(
                            'DIPROSES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w900,
                              color: Color(
                                AppConstants.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _stage = OrderStage.menu;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'TAMBAH MENU',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(
                          AppConstants.primaryRed,
                        ),
                        side: const BorderSide(
                          color: Color(
                            AppConstants.primaryRed,
                          ),
                        ),
                        padding:
                            const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _stage = OrderStage.active;
                        });
                      },
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                      ),
                      label: const Text(
                        'LIHAT PESANAN',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(
                          AppConstants.primaryRed,
                        ),
                        padding:
                            const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sessionHeader(),
              const SizedBox(height: 20),
              _sectionTitle(
                'Pesanan Aktif',
                'Customer masih dapat menambah menu sebelum settlement.',
              ),
              const SizedBox(height: 18),
              ..._menu
                  .where((item) => item.quantity > 0)
                  .map(_cartItem),
              const SizedBox(height: 14),
              _summaryCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _stage = OrderStage.menu;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'TAMBAH MENU',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.all(16),
                        foregroundColor: const Color(
                          AppConstants.primaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openPayment,
                      icon: const Icon(
                        Icons.payments_outlined,
                      ),
                      label: const Text(
                        'BAYAR SEKARANG',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(
                          AppConstants.primaryRed,
                        ),
                        padding:
                            const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentPage() {
    final methods = [
      (
        'Cash',
        Icons.payments_outlined,
      ),
      (
        'QRIS',
        Icons.qr_code_2_outlined,
      ),
      (
        'Transfer',
        Icons.account_balance_outlined,
      ),
    ];

    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: Column(
            children: [
              _backButton(
                onPressed: _backToCart,
              ),
              const SizedBox(height: 20),
              const Text(
                'PEMBAYARAN',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Meja ${_selectedTable?.number ?? '-'} • $_customerName',
                style: const TextStyle(
                  color: Color(AppConstants.muted),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.redSoft),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL TAGIHAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(AppConstants.muted),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _money(_grandTotal),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(
                          AppConstants.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PILIH METODE PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...methods.map((method) {
                final selected =
                    _paymentMethod == method.$1;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _paymentMethod = method.$1;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(
                              AppConstants.redSoft,
                            )
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(
                                AppConstants.primaryRed,
                              )
                            : const Color(
                                AppConstants.line,
                              ),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method.$2,
                          color: selected
                              ? const Color(
                                  AppConstants.primaryRed,
                                )
                              : const Color(
                                  AppConstants.muted,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            method.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(
                              AppConstants.primaryRed,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _pay,
                  icon: const Icon(
                    Icons.lock_outline,
                  ),
                  label: const Text(
                    'KONFIRMASI PEMBAYARAN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(AppConstants.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessPage() {
    return _page(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(AppConstants.greenSoft),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(AppConstants.green),
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'PEMBAYARAN BERHASIL',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_money(_grandTotal)} • $_paymentMethod',
                style: const TextStyle(
                  color: Color(AppConstants.muted),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(AppConstants.line),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'RM ABAH KENARI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _receiptRow(
                      'Meja',
                      _selectedTable?.number ?? '-',
                    ),
                    _receiptRow(
                      'Customer',
                      _customerName,
                    ),
                    _receiptRow(
                      'Order',
                      'AK-000127',
                    ),
                    _receiptRow(
                      'Pembayaran',
                      _paymentMethod,
                    ),
                    _receiptRow(
                      'Status',
                      'PAID',
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      'TOTAL',
                      _money(_grandTotal),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Struk siap dicetak.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.print_outlined,
                      ),
                      label: const Text(
                        'CETAK STRUK',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _finish,
                      icon: const Icon(
                        Icons.done_all,
                      ),
                      label: const Text(
                        'SELESAI',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(
                          AppConstants.primaryRed,
                        ),
                        padding:
                            const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(AppConstants.muted),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}






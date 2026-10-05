import '../../features/dashboard/data/dashboard_repository.dart';

enum BusinessMode {
  product,
  service,
  food,
  workshop,
  hybrid,
  general,
}

enum BusinessCapability {
  products,
  services,
  menu,
  orders,
  inventory,
  purchases,
  suppliers,
  sales,
  customers,
  serviceOrders,
  spareparts,
  quotations,
  invoices,
  payments,
  finance,
  employees,
  reports,
  aiCopilot,
  legal,
  notifications,
  settings,
}

class BusinessModule {
  final String title;
  final String route;
  final BusinessCapability capability;

  const BusinessModule({
    required this.title,
    required this.route,
    required this.capability,
  });
}

class BusinessContext {
  final BusinessMode mode;
  final String businessType;
  final String activity;
  final String kbliCode;
  final String kbliName;

  const BusinessContext({
    required this.mode,
    required this.businessType,
    required this.activity,
    required this.kbliCode,
    required this.kbliName,
  });

  bool has(BusinessCapability capability) {
    return modules.any((module) => module.capability == capability);
  }

  List<BusinessModule> get modules {
    final result = <BusinessModule>[
      const BusinessModule(
        title: 'Business',
        route: '/business',
        capability: BusinessCapability.employees,
      ),
      const BusinessModule(
        title: 'Customers',
        route: '/customers',
        capability: BusinessCapability.customers,
      ),
    ];

    switch (mode) {
      case BusinessMode.product:
        result.addAll(const [
          BusinessModule(
            title: 'Products',
            route: '/products',
            capability: BusinessCapability.products,
          ),
          BusinessModule(
            title: 'Inventory',
            route: '/inventory',
            capability: BusinessCapability.inventory,
          ),
          BusinessModule(
            title: 'Purchases',
            route: '/purchases',
            capability: BusinessCapability.purchases,
          ),
          BusinessModule(
            title: 'Suppliers',
            route: '/suppliers',
            capability: BusinessCapability.suppliers,
          ),
          BusinessModule(
            title: 'Sales',
            route: '/sales',
            capability: BusinessCapability.sales,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Payments',
            route: '/payments',
            capability: BusinessCapability.payments,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);

      case BusinessMode.service:
        result.addAll(const [
          BusinessModule(
            title: 'Services',
            route: '/services',
            capability: BusinessCapability.services,
          ),
          BusinessModule(
            title: 'Quotations',
            route: '/quotations',
            capability: BusinessCapability.quotations,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Payments',
            route: '/payments',
            capability: BusinessCapability.payments,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);

      case BusinessMode.food:
        result.addAll(const [
          BusinessModule(
            title: 'Menu',
            route: '/products',
            capability: BusinessCapability.menu,
          ),
          BusinessModule(
            title: 'Orders',
            route: '/sales',
            capability: BusinessCapability.orders,
          ),
          BusinessModule(
            title: 'Inventory',
            route: '/inventory',
            capability: BusinessCapability.inventory,
          ),
          BusinessModule(
            title: 'Purchases',
            route: '/purchases',
            capability: BusinessCapability.purchases,
          ),
          BusinessModule(
            title: 'Sales',
            route: '/sales',
            capability: BusinessCapability.sales,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);

      case BusinessMode.workshop:
        result.addAll(const [
          BusinessModule(
            title: 'Service Orders',
            route: '/services',
            capability: BusinessCapability.serviceOrders,
          ),
          BusinessModule(
            title: 'Services',
            route: '/services',
            capability: BusinessCapability.services,
          ),
          BusinessModule(
            title: 'Spareparts',
            route: '/products',
            capability: BusinessCapability.spareparts,
          ),
          BusinessModule(
            title: 'Inventory',
            route: '/inventory',
            capability: BusinessCapability.inventory,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);

      case BusinessMode.hybrid:
        result.addAll(const [
          BusinessModule(
            title: 'Products',
            route: '/products',
            capability: BusinessCapability.products,
          ),
          BusinessModule(
            title: 'Services',
            route: '/services',
            capability: BusinessCapability.services,
          ),
          BusinessModule(
            title: 'Inventory',
            route: '/inventory',
            capability: BusinessCapability.inventory,
          ),
          BusinessModule(
            title: 'Sales',
            route: '/sales',
            capability: BusinessCapability.sales,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);

      case BusinessMode.general:
        result.addAll(const [
          BusinessModule(
            title: 'Products',
            route: '/products',
            capability: BusinessCapability.products,
          ),
          BusinessModule(
            title: 'Services',
            route: '/services',
            capability: BusinessCapability.services,
          ),
          BusinessModule(
            title: 'Invoices',
            route: '/invoices',
            capability: BusinessCapability.invoices,
          ),
          BusinessModule(
            title: 'Finance',
            route: '/finance',
            capability: BusinessCapability.finance,
          ),
        ]);
    }

    result.addAll(const [
      BusinessModule(
        title: 'Reports',
        route: '/reports',
        capability: BusinessCapability.reports,
      ),
      BusinessModule(
        title: 'AI Copilot',
        route: '/ai-copilot',
        capability: BusinessCapability.aiCopilot,
      ),
      BusinessModule(
        title: 'Legal',
        route: '/legal',
        capability: BusinessCapability.legal,
      ),
      BusinessModule(
        title: 'Notifications',
        route: '/notifications',
        capability: BusinessCapability.notifications,
      ),
      BusinessModule(
        title: 'Settings',
        route: '/settings',
        capability: BusinessCapability.settings,
      ),
    ]);

    return result;
  }
}

class BusinessModuleResolver {
  static BusinessContext fromSnapshot(DashboardSnapshot snapshot) {
    return resolve(
      businessType: snapshot.businessType,
      activity: snapshot.activity,
      kbliCode: snapshot.kbliCode,
      kbliName: snapshot.kbliName,
    );
  }

  static BusinessContext resolve({
    required String businessType,
    required String activity,
    required String kbliCode,
    required String kbliName,
  }) {
    final type = businessType.toLowerCase().trim();
    final act = activity.toLowerCase().trim();
    final code = kbliCode.trim();
    final name = kbliName.toLowerCase().trim();

    final text = '$type $act $name';

    // ============================================================
    // NUSA-DHIPA BUSINESS MODULE RESOLUTION
    // ============================================================
    //
    // Priority:
    // 1. Verified KBLI code
    // 2. Registered business type
    // 3. Activity / KBLI name fallback
    //
    // IMPORTANT:
    // Do not identify a business by company name.
    // This keeps Business Mobile multi-UMKM.
    //
    // Product/trade is intentionally evaluated BEFORE food because
    // terms such as "petfood" contain "food" but are not restaurants.
    // ============================================================

    if (_isProduct(code, text, type)) {
      return BusinessContext(
        mode: BusinessMode.product,
        businessType: businessType,
        activity: activity,
        kbliCode: kbliCode,
        kbliName: kbliName,
      );
    }

    if (_isFood(code, text)) {
      return BusinessContext(
        mode: BusinessMode.food,
        businessType: businessType,
        activity: activity,
        kbliCode: kbliCode,
        kbliName: kbliName,
      );
    }

    if (_isWorkshop(text)) {
      return BusinessContext(
        mode: BusinessMode.workshop,
        businessType: businessType,
        activity: activity,
        kbliCode: kbliCode,
        kbliName: kbliName,
      );
    }

    if (_isService(code, text)) {
      return BusinessContext(
        mode: BusinessMode.service,
        businessType: businessType,
        activity: activity,
        kbliCode: kbliCode,
        kbliName: kbliName,
      );
    }

    return BusinessContext(
      mode: BusinessMode.general,
      businessType: businessType,
      activity: activity,
      kbliCode: kbliCode,
      kbliName: kbliName,
    );
  }

  static bool _isProduct(
    String code,
    String text,
    String businessType,
  ) {
    // ------------------------------------------------------------
    // KBLI perdagangan / produk
    // ------------------------------------------------------------
    //
    // These are generic NUSA-DHIPA business classifications.
    // They are NOT tied to PT Sauri.
    //
    // Exact registered KBLI remains authoritative from backend.
    // ------------------------------------------------------------
    const productCodes = {
      '47111',
      '47112',
      '47911',

      // Wholesale / trade
      '46321',
      '46322',
      '46323',
      '46324',
      '46325',
      '46326',
      '46327',
      '46329',

      // Retail processed food products
      '47245',
      '47246',
    };

    if (productCodes.contains(code)) {
      return true;
    }

    // ------------------------------------------------------------
    // Business type fallback
    // ------------------------------------------------------------
    const productBusinessTypes = {
      'supplier',
      'wholesale',
      'wholesaler',
      'retail',
      'product',
      'distributor',
      'seller',
      'merchant',
    };

    if (productBusinessTypes.contains(businessType)) {
      return true;
    }

    // ------------------------------------------------------------
    // Activity / KBLI name fallback
    // ------------------------------------------------------------
    return text.contains('supplier') ||
        text.contains('grosir') ||
        text.contains('wholesale') ||
        text.contains('perdagangan') ||
        text.contains('perdagangan besar') ||
        text.contains('perdagangan eceran') ||
        text.contains('retail') ||
        text.contains('eceran') ||
        text.contains('produk') ||
        text.contains('penjualan') ||
        text.contains('distributor') ||
        text.contains('online seller');
  }

  static bool _isFood(String code, String text) {
    const foodCodes = {
      '56101',
      '56303',
    };

    if (foodCodes.contains(code)) {
      return true;
    }

    return text.contains('restoran') ||
        text.contains('kafe') ||
        text.contains('cafe') ||
        text.contains('food') ||
        text.contains('makanan') ||
        text.contains('minuman') ||
        text.contains('kuliner');
  }

  static bool _isService(String code, String text) {
    const serviceCodes = {
      '62010',
      '85500',
      '79111',
    };

    if (serviceCodes.contains(code)) {
      return true;
    }

    return text.contains('service') ||
        text.contains('jasa') ||
        text.contains('software') ||
        text.contains('programming') ||
        text.contains('pemrograman') ||
        text.contains('pendidikan') ||
        text.contains('pelatihan') ||
        text.contains('perjalanan') ||
        text.contains('konsultan') ||
        text.contains('consult');
  }

  static bool _isWorkshop(String text) {
    return text.contains('bengkel') ||
        text.contains('workshop') ||
        text.contains('reparasi') ||
        text.contains('servis kendaraan') ||
        text.contains('service kendaraan');
  }
}


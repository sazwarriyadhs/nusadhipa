import 'package:flutter/material.dart';

import '../../../core/widgets/business_bottom_navigation.dart';

enum AiBusinessMode {
  product,
  service,
  hybrid,
  food,
  workshop,
  general,
}

class AiCopilotPage extends StatelessWidget {
  final AiBusinessMode businessMode;

  const AiCopilotPage({
    super.key,
    this.businessMode = AiBusinessMode.general,
  });

  @override
  Widget build(BuildContext context) {
    final profile = _AiBusinessProfile.fromMode(businessMode);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      bottomNavigationBar: const BusinessBottomNavigation(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'AI Copilot',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroHeader(profile: profile),
                  const SizedBox(height: 24),
                  _KpiGrid(profile: profile),
                  const SizedBox(height: 24),
                  _ActionPanel(profile: profile),
                  const SizedBox(height: 24),
                  _ModulePanel(profile: profile),
                  const SizedBox(height: 24),
                  _InsightPanel(profile: profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BUSINESS PROFILE
// ============================================================

class _AiBusinessProfile {
  final AiBusinessMode mode;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<_AiAction> actions;
  final List<_AiModule> modules;

  const _AiBusinessProfile({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.actions,
    required this.modules,
  });

  factory _AiBusinessProfile.fromMode(AiBusinessMode mode) {
    switch (mode) {
      case AiBusinessMode.product:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.product,
          title: 'AI Sales Copilot',
          subtitle: 'AI untuk bisnis berbasis produk',
          description:
              'Bantu menganalisis katalog, penjualan, stok, pelanggan, '
              'harga, dan peluang pertumbuhan bisnis.',
          icon: Icons.inventory_2_rounded,
          actions: [
            _AiAction(
              'Analisis Produk',
              'Identifikasi produk yang perlu diperhatikan.',
              Icons.inventory_2_rounded,
            ),
            _AiAction(
              'Analisis Penjualan',
              'Ringkas performa penjualan dan pelanggan.',
              Icons.trending_up_rounded,
            ),
            _AiAction(
              'Strategi Promosi',
              'Buat ide promosi berdasarkan katalog.',
              Icons.campaign_rounded,
            ),
            _AiAction(
              'Cek Stok',
              'Identifikasi kebutuhan stok dan inventory.',
              Icons.warehouse_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Product Intelligence',
              'Analisis produk dan katalog.',
              Icons.inventory_2_rounded,
            ),
            _AiModule(
              'Sales Intelligence',
              'Analisis transaksi dan pelanggan.',
              Icons.point_of_sale_rounded,
            ),
            _AiModule(
              'Inventory Intelligence',
              'Pantau stok dan kebutuhan pembelian.',
              Icons.warehouse_rounded,
            ),
          ],
        );

      case AiBusinessMode.service:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.service,
          title: 'AI Service Copilot',
          subtitle: 'AI untuk bisnis berbasis jasa',
          description:
              'Bantu mengelola layanan, quotation, pelanggan, pekerjaan, '
              'invoice, dan peluang bisnis.',
          icon: Icons.home_repair_service_rounded,
          actions: [
            _AiAction(
              'Analisis Layanan',
              'Analisis layanan yang tersedia.',
              Icons.home_repair_service_rounded,
            ),
            _AiAction(
              'Buat Quotation',
              'Bantu menyusun penawaran layanan.',
              Icons.request_quote_rounded,
            ),
            _AiAction(
              'Analisis Pelanggan',
              'Pahami pelanggan dan kebutuhan mereka.',
              Icons.groups_rounded,
            ),
            _AiAction(
              'Follow Up',
              'Bantu membuat strategi follow-up.',
              Icons.follow_the_signs_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Service Intelligence',
              'Analisis katalog layanan.',
              Icons.home_repair_service_rounded,
            ),
            _AiModule(
              'Quotation Assistant',
              'Bantu membuat penawaran.',
              Icons.request_quote_rounded,
            ),
            _AiModule(
              'Customer Intelligence',
              'Analisis pelanggan dan peluang.',
              Icons.groups_rounded,
            ),
          ],
        );

      case AiBusinessMode.hybrid:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.hybrid,
          title: 'AI Business Copilot',
          subtitle: 'AI untuk produk & layanan',
          description:
              'AI memahami bisnis yang menjual produk sekaligus menyediakan '
              'layanan dalam satu operasional.',
          icon: Icons.hub_rounded,
          actions: [
            _AiAction(
              'Business Analysis',
              'Analisis kondisi bisnis secara menyeluruh.',
              Icons.insights_rounded,
            ),
            _AiAction(
              'Product Intelligence',
              'Analisis produk dan performanya.',
              Icons.inventory_2_rounded,
            ),
            _AiAction(
              'Service Intelligence',
              'Analisis layanan dan pelanggan.',
              Icons.home_repair_service_rounded,
            ),
            _AiAction(
              'Growth Strategy',
              'Temukan peluang pengembangan bisnis.',
              Icons.trending_up_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Business Intelligence',
              'Analisis seluruh aktivitas bisnis.',
              Icons.insights_rounded,
            ),
            _AiModule(
              'Product Intelligence',
              'Analisis produk.',
              Icons.inventory_2_rounded,
            ),
            _AiModule(
              'Service Intelligence',
              'Analisis layanan.',
              Icons.home_repair_service_rounded,
            ),
          ],
        );

      case AiBusinessMode.food:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.food,
          title: 'AI F&B Copilot',
          subtitle: 'AI untuk restoran, cafe, hotel & kuliner',
          description:
              'Bantu memahami menu, order, pelanggan, operasional, '
              'dan peluang peningkatan bisnis.',
          icon: Icons.restaurant_rounded,
          actions: [
            _AiAction(
              'Menu Intelligence',
              'Analisis menu dan performanya.',
              Icons.restaurant_menu_rounded,
            ),
            _AiAction(
              'Sales Analysis',
              'Analisis order dan penjualan.',
              Icons.point_of_sale_rounded,
            ),
            _AiAction(
              'Menu Strategy',
              'Bantu menyusun strategi menu.',
              Icons.auto_awesome_rounded,
            ),
            _AiAction(
              'Customer Insight',
              'Pahami perilaku pelanggan.',
              Icons.groups_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Menu Intelligence',
              'Analisis menu.',
              Icons.restaurant_menu_rounded,
            ),
            _AiModule(
              'Order Intelligence',
              'Analisis order.',
              Icons.receipt_long_rounded,
            ),
            _AiModule(
              'Customer Intelligence',
              'Analisis pelanggan.',
              Icons.groups_rounded,
            ),
          ],
        );

      case AiBusinessMode.workshop:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.workshop,
          title: 'AI Workshop Copilot',
          subtitle: 'AI untuk bengkel & technical service',
          description:
              'Bantu mengelola pekerjaan service, sparepart, pelanggan, '
              'quotation, dan histori pekerjaan.',
          icon: Icons.build_circle_rounded,
          actions: [
            _AiAction(
              'Service Analysis',
              'Analisis pekerjaan service.',
              Icons.build_circle_rounded,
            ),
            _AiAction(
              'Sparepart Check',
              'Periksa kebutuhan sparepart.',
              Icons.settings_rounded,
            ),
            _AiAction(
              'Quotation',
              'Bantu menyusun estimasi pekerjaan.',
              Icons.request_quote_rounded,
            ),
            _AiAction(
              'Customer History',
              'Lihat pola histori pelanggan.',
              Icons.history_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Service Intelligence',
              'Analisis pekerjaan service.',
              Icons.build_circle_rounded,
            ),
            _AiModule(
              'Sparepart Intelligence',
              'Analisis sparepart.',
              Icons.settings_rounded,
            ),
            _AiModule(
              'Customer History',
              'Analisis histori pelanggan.',
              Icons.history_rounded,
            ),
          ],
        );

      case AiBusinessMode.general:
        return const _AiBusinessProfile(
          mode: AiBusinessMode.general,
          title: 'AI Business Copilot',
          subtitle: 'AI assistant untuk operasional bisnis',
          description:
              'AI akan menyesuaikan bantuan berdasarkan modul dan '
              'kapabilitas bisnis yang tersedia.',
          icon: Icons.auto_awesome_rounded,
          actions: [
            _AiAction(
              'Business Analysis',
              'Analisis kondisi bisnis.',
              Icons.insights_rounded,
            ),
            _AiAction(
              'Sales Insight',
              'Analisis penjualan dan pelanggan.',
              Icons.trending_up_rounded,
            ),
            _AiAction(
              'Operational Insight',
              'Analisis aktivitas operasional.',
              Icons.settings_suggest_rounded,
            ),
            _AiAction(
              'Growth Strategy',
              'Cari peluang pengembangan.',
              Icons.rocket_launch_rounded,
            ),
          ],
          modules: [
            _AiModule(
              'Business Intelligence',
              'Analisis kondisi bisnis.',
              Icons.insights_rounded,
            ),
            _AiModule(
              'Sales Intelligence',
              'Analisis penjualan.',
              Icons.point_of_sale_rounded,
            ),
            _AiModule(
              'Operational Intelligence',
              'Analisis operasional.',
              Icons.settings_suggest_rounded,
            ),
          ],
        );
    }
  }
}

// ============================================================
// HERO
// ============================================================

class _HeroHeader extends StatelessWidget {
  final _AiBusinessProfile profile;

  const _HeroHeader({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF172554),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              profile.icon,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  profile.description,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KPI
// ============================================================

class _KpiGrid extends StatelessWidget {
  final _AiBusinessProfile profile;

  const _KpiGrid({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_KpiItem>[
      _KpiItem(
        'MODE',
        _modeLabel(profile.mode),
        Icons.business_center_rounded,
      ),
      _KpiItem(
        'AI',
        'READY',
        Icons.auto_awesome_rounded,
      ),
      _KpiItem(
        'MODULES',
        profile.modules.length.toString(),
        Icons.apps_rounded,
      ),
      _KpiItem(
        'STATUS',
        'ACTIVE',
        Icons.check_circle_outline_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5EAF0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: const Color(0xFF1769FF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _modeLabel(AiBusinessMode mode) {
    switch (mode) {
      case AiBusinessMode.product:
        return 'PRODUCT';
      case AiBusinessMode.service:
        return 'SERVICE';
      case AiBusinessMode.hybrid:
        return 'HYBRID';
      case AiBusinessMode.food:
        return 'F&B';
      case AiBusinessMode.workshop:
        return 'WORKSHOP';
      case AiBusinessMode.general:
        return 'GENERAL';
    }
  }
}

// ============================================================
// ACTIONS
// ============================================================

class _ActionPanel extends StatelessWidget {
  final _AiBusinessProfile profile;

  const _ActionPanel({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: Color(0xFF1769FF),
              ),
              SizedBox(width: 10),
              Text(
                'AI Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rekomendasi AI disesuaikan dengan jenis bisnis.',
            style: TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4.0,
                ),
                itemBuilder: (context, index) {
                  final action = profile.actions[index];

                  return Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${action.title} akan menggunakan AI berdasarkan data bisnis.',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                action.icon,
                                color: const Color(0xFF1769FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    action.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODULES
// ============================================================

class _ModulePanel extends StatelessWidget {
  final _AiBusinessProfile profile;

  const _ModulePanel({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI BUSINESS MODULES',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Intelligence yang tersedia',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...profile.modules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModuleTile(module: module),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _AiModule module;

  const _ModuleTile({
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5EAF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              module.icon,
              color: const Color(0xFF1769FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  module.description,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INSIGHT
// ============================================================

class _InsightPanel extends StatelessWidget {
  final _AiBusinessProfile profile;

  const _InsightPanel({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFF5F3FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE7F7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF1769FF),
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Context',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Copilot menggunakan konteks ${_modeLabel(profile.mode)} '
                  'dan nantinya dapat mengakses capability bisnis yang aktif.',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(AiBusinessMode mode) {
    switch (mode) {
      case AiBusinessMode.product:
        return 'produk';
      case AiBusinessMode.service:
        return 'jasa';
      case AiBusinessMode.hybrid:
        return 'produk dan layanan';
      case AiBusinessMode.food:
        return 'F&B';
      case AiBusinessMode.workshop:
        return 'workshop';
      case AiBusinessMode.general:
        return 'bisnis umum';
    }
  }
}

// ============================================================
// MODELS
// ============================================================

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;

  const _KpiItem(
    this.label,
    this.value,
    this.icon,
  );
}

class _AiAction {
  final String title;
  final String description;
  final IconData icon;

  const _AiAction(
    this.title,
    this.description,
    this.icon,
  );
}

class _AiModule {
  final String title;
  final String description;
  final IconData icon;

  const _AiModule(
    this.title,
    this.description,
    this.icon,
  );
}
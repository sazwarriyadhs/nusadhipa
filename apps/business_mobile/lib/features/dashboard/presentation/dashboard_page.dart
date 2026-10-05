import '../../../core/widgets/business_bottom_navigation.dart';
import '../../../core/business/business_module_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/dashboard_repository.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Image.asset(
          'assets/images/logo.png',
          width: 180,
          height: 52,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              ref.invalidate(dashboardSnapshotProvider);
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF171717)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const BusinessBottomNavigation(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSnapshotProvider);
          await ref.read(dashboardSnapshotProvider.future);
        },
        child: snapshotAsync.when(
          loading: () => const _DashboardLoading(),
          error: (error, stack) => _DashboardError(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(dashboardSnapshotProvider);
            },
          ),
          data: (snapshot) {
            if (snapshot == null) {
              return const _NoBusinessState();
            }

            return _DashboardContent(snapshot: snapshot);
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _DashboardContent({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 11
        ? 'Good morning'
        : hour < 15
        ? 'Good afternoon'
        : 'Good evening';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _WelcomeHero(greeting: greeting, snapshot: snapshot),
        const SizedBox(height: 16),
        const _SectionTitle(
          eyebrow: 'BUSINESS SNAPSHOT',
          title: 'Your business at a glance',
        ),
        const SizedBox(height: 10),
        _SnapshotGrid(snapshot: snapshot),
        const SizedBox(height: 18),
        _AiInsightCard(onTap: () => context.go('/ai-copilot')),
        const SizedBox(height: 18),
        _ModuleStatusCard(snapshot: snapshot),
        const SizedBox(height: 18),
        _LegalCard(snapshot: snapshot, onTap: () => context.go('/legal')),
        const SizedBox(height: 18),
        _QuickActions(
          snapshot: snapshot,
          onBusiness: () => context.go('/business'),
          onLegal: () => context.go('/legal'),
          onModules: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              builder: (_) => const _ModuleSheet(),
            );
          },
        ),
        const SizedBox(height: 18),
        _FooterMeta(snapshot: snapshot),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final String greeting;
  final DashboardSnapshot snapshot;

  const _WelcomeHero({required this.greeting, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/header.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Dark gradient keeps the real business data readable
          // regardless of the header image composition.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66B71C1C), Color(0xD9B71C1C)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5232E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF34D399,
                            ).withValues(alpha: 0.55),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BUSINESS ${snapshot.businessStatus}',
                      style: const TextStyle(
                        color: Color(0xFFFFEBEE),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  snapshot.businessName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  snapshot.businessType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (snapshot.kbliCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'KBLI 2025 • ${snapshot.kbliCode}'
                    '${snapshot.kbliName.isNotEmpty ? ' • ${snapshot.kbliName}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _SnapshotGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final businessContext = BusinessModuleResolver.fromSnapshot(snapshot);

    final primary = _primaryMetric(businessContext);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _MetricCard(
          icon: primary.icon,
          label: primary.label,
          value: primary.value,
          caption: primary.caption,
        ),
        _MetricCard(
          icon: primary.activeIcon,
          label: primary.activeLabel,
          value: primary.activeValue,
          caption: primary.activeCaption,
        ),
        _MetricCard(
          icon: Icons.business_center_rounded,
          label: 'BUSINESS',
          value: snapshot.businessStatus,
          caption: snapshot.businessType,
          compactValue: true,
        ),
        _MetricCard(
          icon: Icons.gavel_rounded,
          label: 'LEGAL',
          value: _legalShortStatus(snapshot),
          caption: 'Registration status',
          compactValue: true,
        ),
      ],
    );
  }

  ({
    IconData icon,
    String label,
    String value,
    String caption,
    IconData activeIcon,
    String activeLabel,
    String activeValue,
    String activeCaption,
  })
  _primaryMetric(BusinessContext context) {
    switch (context.mode) {
      case BusinessMode.product:
        return (
          icon: Icons.inventory_2_rounded,
          label: 'PRODUCTS',
          value: _productCount(),
          caption: 'Catalog products',
          activeIcon: Icons.check_circle_rounded,
          activeLabel: 'ACTIVE PRODUCTS',
          activeValue: _activeProductCount(),
          activeCaption: 'Available in catalog',
        );

      case BusinessMode.service:
        return (
          icon: Icons.home_repair_service_rounded,
          label: 'SERVICES',
          value: _serviceCount(),
          caption: 'Service catalog',
          activeIcon: Icons.check_circle_rounded,
          activeLabel: 'ACTIVE SERVICES',
          activeValue: _activeServiceCount(),
          activeCaption: 'Available in marketplace',
        );

      case BusinessMode.food:
        return (
          icon: Icons.restaurant_menu_rounded,
          label: 'MENU',
          value: _productCount(),
          caption: 'Menu items',
          activeIcon: Icons.check_circle_rounded,
          activeLabel: 'ACTIVE MENU',
          activeValue: _activeProductCount(),
          activeCaption: 'Available in catalog',
        );

      case BusinessMode.workshop:
        return (
          icon: Icons.home_repair_service_rounded,
          label: 'SERVICES',
          value: _serviceCount(),
          caption: 'Workshop services',
          activeIcon: Icons.check_circle_rounded,
          activeLabel: 'ACTIVE SERVICES',
          activeValue: _activeServiceCount(),
          activeCaption: 'Available services',
        );

      case BusinessMode.hybrid:
        return (
          icon: Icons.inventory_2_rounded,
          label: 'PRODUCTS',
          value: _productCount(),
          caption: 'Product catalog',
          activeIcon: Icons.home_repair_service_rounded,
          activeLabel: 'SERVICES',
          activeValue: _serviceCount(),
          activeCaption: 'Service catalog',
        );

      case BusinessMode.general:
        return (
          icon: Icons.inventory_2_rounded,
          label: 'PRODUCTS',
          value: _productCount(),
          caption: 'Catalog records',
          activeIcon: Icons.home_repair_service_rounded,
          activeLabel: 'SERVICES',
          activeValue: _serviceCount(),
          activeCaption: 'Service records',
        );
    }
  }

  String _legalShortStatus(DashboardSnapshot snapshot) {
    final legal = snapshot.legal;

    if (legal == null) {
      return 'UNKNOWN';
    }

    // Legal Service response:
    //
    // {
    //   "business_status": "ACTIVE",
    //   "can_operate": true,
    //   "legalization": {
    //     "nib": {
    //       "status": "VERIFIED"
    //     },
    //     "ahu": {
    //       "status": "VERIFIED"
    //     }
    //   }
    // }
    //
    // Business at a Glance should show the actual
    // legalization state, not legal["status"].

    final nibStatus = snapshot.nibStatus;
    final ahuStatus = snapshot.ahuStatus;

    if (nibStatus == 'VERIFIED' && ahuStatus == 'VERIFIED') {
      return 'VERIFIED';
    }

    if (nibStatus == 'VERIFIED' || ahuStatus == 'VERIFIED') {
      return 'PARTIAL';
    }

    final businessStatus = legal['business_status']
        ?.toString()
        .trim()
        .toUpperCase();

    if (businessStatus == 'ACTIVE') {
      return 'ACTIVE';
    }

    if (snapshot.canOperate) {
      return 'ACTIVE';
    }

    return 'UNKNOWN';
  }

  String _productCount() {
    return snapshot.productCount.toString();
  }

  String _activeProductCount() {
    return snapshot.activeProductCount.toString();
  }

  String _serviceCount() {
    return snapshot.serviceCount.toString();
  }

  String _activeServiceCount() {
    return snapshot.activeServiceCount.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final bool compactValue;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.compactValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF4B5563)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF171717),
              fontSize: compactValue ? 18 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AiInsightCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RASAI BUSINESS INTELLIGENCE',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'AI Copilot is ready for business analysis.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Open the AI workspace when business intelligence data is connected.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleStatusCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _ModuleStatusCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final businessContext = BusinessModuleResolver.fromSnapshot(snapshot);

    final modules = businessContext.modules.where((module) {
      switch (module.capability) {
        case BusinessCapability.products:
        case BusinessCapability.services:
        case BusinessCapability.menu:
        case BusinessCapability.orders:
        case BusinessCapability.serviceOrders:
        case BusinessCapability.inventory:
        case BusinessCapability.purchases:
        case BusinessCapability.suppliers:
        case BusinessCapability.sales:
        case BusinessCapability.customers:
        case BusinessCapability.quotations:
        case BusinessCapability.invoices:
        case BusinessCapability.payments:
        case BusinessCapability.finance:
        case BusinessCapability.spareparts:
          return true;

        case BusinessCapability.employees:
        case BusinessCapability.reports:
        case BusinessCapability.aiCopilot:
        case BusinessCapability.legal:
        case BusinessCapability.notifications:
        case BusinessCapability.settings:
          return false;
      }
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR BUSINESS',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _modeTitle(businessContext.mode),
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            businessContext.kbliCode.isNotEmpty
                ? 'KBLI ${businessContext.kbliCode}'
                : businessContext.businessType,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          for (var i = 0; i < modules.length; i++) ...[
            _ModuleRow(
              icon: _moduleIcon(modules[i].capability),
              title: modules[i].title,
              status: _moduleStatus(modules[i].capability, snapshot),
              active: _moduleActive(modules[i].capability, snapshot),
            ),
            if (i < modules.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }

  String _modeTitle(BusinessMode mode) {
    switch (mode) {
      case BusinessMode.product:
        return 'Product Business';
      case BusinessMode.service:
        return 'Service Business';
      case BusinessMode.food:
        return 'Food & Beverage';
      case BusinessMode.workshop:
        return 'Workshop Business';
      case BusinessMode.hybrid:
        return 'Hybrid Business';
      case BusinessMode.general:
        return 'Business Workspace';
    }
  }

  IconData _moduleIcon(BusinessCapability capability) {
    switch (capability) {
      case BusinessCapability.products:
        return Icons.inventory_2_rounded;
      case BusinessCapability.services:
        return Icons.home_repair_service_rounded;
      case BusinessCapability.menu:
        return Icons.restaurant_menu_rounded;
      case BusinessCapability.orders:
      case BusinessCapability.serviceOrders:
        return Icons.receipt_long_rounded;
      case BusinessCapability.inventory:
        return Icons.warehouse_rounded;
      case BusinessCapability.purchases:
        return Icons.shopping_cart_checkout_rounded;
      case BusinessCapability.suppliers:
        return Icons.local_shipping_rounded;
      case BusinessCapability.sales:
        return Icons.point_of_sale_rounded;
      case BusinessCapability.customers:
        return Icons.people_alt_rounded;
      case BusinessCapability.quotations:
        return Icons.request_quote_rounded;
      case BusinessCapability.invoices:
        return Icons.receipt_long_rounded;
      case BusinessCapability.payments:
        return Icons.payments_rounded;
      case BusinessCapability.finance:
        return Icons.account_balance_wallet_rounded;
      case BusinessCapability.spareparts:
        return Icons.build_circle_rounded;
      case BusinessCapability.employees:
        return Icons.badge_rounded;
      case BusinessCapability.reports:
        return Icons.bar_chart_rounded;
      case BusinessCapability.aiCopilot:
        return Icons.auto_awesome_rounded;
      case BusinessCapability.legal:
        return Icons.gavel_rounded;
      case BusinessCapability.notifications:
        return Icons.notifications_rounded;
      case BusinessCapability.settings:
        return Icons.settings_rounded;
    }
  }

  String _moduleStatus(
    BusinessCapability capability,
    DashboardSnapshot snapshot,
  ) {
    switch (capability) {
      case BusinessCapability.products:
        return '${snapshot.productCount} products';

      case BusinessCapability.services:
        return '${snapshot.serviceCount} services';

      case BusinessCapability.menu:
        return '${snapshot.productCount} menu items';

      case BusinessCapability.spareparts:
        return '${snapshot.productCount} spare parts';

      case BusinessCapability.customers:
      case BusinessCapability.orders:
      case BusinessCapability.serviceOrders:
      case BusinessCapability.quotations:
      case BusinessCapability.invoices:
      case BusinessCapability.payments:
      case BusinessCapability.finance:
      case BusinessCapability.inventory:
      case BusinessCapability.purchases:
      case BusinessCapability.suppliers:
      case BusinessCapability.sales:
        return 'Module available';

      default:
        return 'Available';
    }
  }

  bool _moduleActive(
    BusinessCapability capability,
    DashboardSnapshot snapshot,
  ) {
    switch (capability) {
      case BusinessCapability.products:
        return snapshot.productCount > 0;

      case BusinessCapability.services:
        return snapshot.serviceCount > 0;

      case BusinessCapability.menu:
        return snapshot.productCount > 0;

      case BusinessCapability.spareparts:
        return snapshot.productCount > 0;

      default:
        return true;
    }
  }
}

class _ModuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool active;

  const _ModuleRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF9FAFB) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Icon(
          active ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
          size: 17,
          color: active ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
        ),
      ],
    );
  }
}

class _LegalCard extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final VoidCallback onTap;

  const _LegalCard({required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final legal = snapshot.legal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEGAL STATUS',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Registration overview',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onTap, child: const Text('Manage')),
            ],
          ),
          const SizedBox(height: 14),
          if (legal == null)
            const Text(
              'Legal status unavailable. Open Legal for details.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            )
          else ...[
            if (snapshot.nibNumber.isNotEmpty)
              _LegalRow(
                title: 'NIB',
                value: snapshot.nibNumber,
                status: snapshot.nibStatus,
              ),
            if (snapshot.ahuNumber.isNotEmpty) ...[
              if (snapshot.nibNumber.isNotEmpty) const SizedBox(height: 10),
              _LegalRow(
                title: 'AHU',
                value: snapshot.ahuNumber,
                status: snapshot.ahuStatus,
              ),
            ],
            if (snapshot.nibNumber.isEmpty && snapshot.ahuNumber.isEmpty)
              const Text(
                'NIB dan AHU belum terdaftar. Status legalitas ditampilkan terpisah dari status operasional Business OS.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final String title;
  final String value;
  final String status;

  const _LegalRow({
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            size: 20,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ),
        _StatusChip(status: status),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final verified = status == 'VERIFIED';
    final pending = status == 'SUBMITTED' || status == 'IN_PROGRESS';

    final background = verified
        ? const Color(0xFFECFDF5)
        : pending
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF9FAFB);

    final foreground = verified
        ? const Color(0xFF16A34A)
        : pending
        ? const Color(0xFFB45309)
        : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final VoidCallback onBusiness;
  final VoidCallback onLegal;
  final VoidCallback onModules;

  const _QuickActions({
    required this.snapshot,
    required this.onBusiness,
    required this.onLegal,
    required this.onModules,
  });

  @override
  Widget build(BuildContext context) {
    final businessContext = BusinessModuleResolver.fromSnapshot(snapshot);

    final primaryModule = _primaryModule(businessContext);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'QUICK ACTIONS',
          title: 'Business workspace shortcuts',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.business_rounded,
                label: 'Business',
                onTap: onBusiness,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: _moduleIcon(primaryModule.capability),
                label: primaryModule.title,
                onTap: () => context.go(primaryModule.route),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.gavel_rounded,
                label: 'Legal',
                onTap: onLegal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.apps_rounded,
                label: 'Modules',
                onTap: onModules,
              ),
            ),
          ],
        ),
      ],
    );
  }

  BusinessModule _primaryModule(BusinessContext context) {
    late final BusinessCapability preferred;

    switch (context.mode) {
      case BusinessMode.product:
        preferred = BusinessCapability.products;
        break;

      case BusinessMode.service:
        preferred = BusinessCapability.services;
        break;

      case BusinessMode.food:
        preferred = BusinessCapability.menu;
        break;

      case BusinessMode.workshop:
        preferred = BusinessCapability.services;
        break;

      case BusinessMode.hybrid:
        preferred = BusinessCapability.products;
        break;

      case BusinessMode.general:
        preferred = BusinessCapability.products;
        break;
    }

    for (final module in context.modules) {
      if (module.capability == preferred) {
        return module;
      }
    }

    if (context.modules.isNotEmpty) {
      return context.modules.first;
    }

    throw StateError('No business modules available for ${context.mode}');
  }

  IconData _moduleIcon(BusinessCapability capability) {
    switch (capability) {
      case BusinessCapability.products:
        return Icons.inventory_2_rounded;
      case BusinessCapability.services:
        return Icons.home_repair_service_rounded;
      case BusinessCapability.menu:
        return Icons.restaurant_menu_rounded;
      case BusinessCapability.serviceOrders:
        return Icons.receipt_long_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: const Color(0xFF171717),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionTitle({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF171717),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FooterMeta extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _FooterMeta({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final time = snapshot.fetchedAt;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    return Center(
      child: Text(
        'Dashboard data refreshed at $hh:$mm • Real backend data only',
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
      ),
    );
  }
}

class _ModuleSheet extends ConsumerWidget {
  const _ModuleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Business data is not available.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
        ),
      ),
      data: (snapshot) {
        if (snapshot == null) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Business data is not available.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ),
            ),
          );
        }

        final businessContext = BusinessModuleResolver.fromSnapshot(snapshot);

        final modules = businessContext.modules;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NUSA-DHIPA Module Center',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _moduleSubtitle(businessContext),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (context, index) {
                      final module = modules[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(module.route);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                _moduleIcon(module.capability),
                                size: 21,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              module.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _moduleSubtitle(BusinessContext context) {
    if (context.kbliCode.isNotEmpty) {
      return '${_modeTitle(context.mode)} • KBLI ${context.kbliCode}';
    }

    return '${_modeTitle(context.mode)} • Dynamic business workspace';
  }

  String _modeTitle(BusinessMode mode) {
    switch (mode) {
      case BusinessMode.product:
        return 'Product Business';
      case BusinessMode.service:
        return 'Service Business';
      case BusinessMode.food:
        return 'Food & Beverage';
      case BusinessMode.workshop:
        return 'Workshop Business';
      case BusinessMode.hybrid:
        return 'Hybrid Business';
      case BusinessMode.general:
        return 'Business Workspace';
    }
  }

  IconData _moduleIcon(BusinessCapability capability) {
    switch (capability) {
      case BusinessCapability.products:
        return Icons.inventory_2_rounded;
      case BusinessCapability.services:
        return Icons.home_repair_service_rounded;
      case BusinessCapability.menu:
        return Icons.restaurant_menu_rounded;
      case BusinessCapability.orders:
      case BusinessCapability.serviceOrders:
        return Icons.receipt_long_rounded;
      case BusinessCapability.inventory:
        return Icons.warehouse_rounded;
      case BusinessCapability.purchases:
        return Icons.shopping_cart_checkout_rounded;
      case BusinessCapability.suppliers:
        return Icons.local_shipping_rounded;
      case BusinessCapability.sales:
        return Icons.point_of_sale_rounded;
      case BusinessCapability.customers:
        return Icons.people_alt_rounded;
      case BusinessCapability.quotations:
        return Icons.request_quote_rounded;
      case BusinessCapability.invoices:
        return Icons.receipt_long_rounded;
      case BusinessCapability.payments:
        return Icons.payments_rounded;
      case BusinessCapability.finance:
        return Icons.account_balance_wallet_rounded;
      case BusinessCapability.spareparts:
        return Icons.build_circle_rounded;
      case BusinessCapability.employees:
        return Icons.badge_rounded;
      case BusinessCapability.reports:
        return Icons.bar_chart_rounded;
      case BusinessCapability.aiCopilot:
        return Icons.auto_awesome_rounded;
      case BusinessCapability.legal:
        return Icons.gavel_rounded;
      case BusinessCapability.notifications:
        return Icons.notifications_rounded;
      case BusinessCapability.settings:
        return Icons.settings_rounded;
    }
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _LoadingBox(height: 155)),
            const SizedBox(width: 10),
            Expanded(child: _LoadingBox(height: 155)),
          ],
        ),
        const SizedBox(height: 18),
        const _LoadingBox(height: 150),
        const SizedBox(height: 18),
        const _LoadingBox(height: 190),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  final double height;

  const _LoadingBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xFF6B7280)),
        const SizedBox(height: 18),
        const Text(
          'Dashboard unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _NoBusinessState extends StatelessWidget {
  const _NoBusinessState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.business_center_rounded,
          size: 54,
          color: Color(0xFF6B7280),
        ),
        const SizedBox(height: 18),
        const Text(
          'Business setup required',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Complete your business profile before using the Command Center.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

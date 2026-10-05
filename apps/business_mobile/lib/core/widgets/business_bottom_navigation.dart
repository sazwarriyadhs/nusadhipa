import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../business/business_module_profile.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/dashboard/data/dashboard_repository.dart';

class BusinessBottomNavigation extends ConsumerWidget {
  const BusinessBottomNavigation({super.key});

  static const Color navy = Color(0xFF212121);
  static const Color blue = Color(0xFFD32F2F);
  static const Color muted = Color(0xFF757575);
  static const Color border = Color(0xFFE5E5E5);
  static const Color surface = Color(0xFFFFFFFF);

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location == '/dashboard' || location.startsWith('/dashboard/')) {
      return 0;
    }

    if (location == '/business' || location.startsWith('/business/')) {
      return 1;
    }

    if (location == '/notifications' ||
        location.startsWith('/notifications/')) {
      return 2;
    }

    if (location == '/settings' || location.startsWith('/settings/')) {
      return 3;
    }

    return -1;
  }

  void _onItemTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/business');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.analytics_outlined,
                label: 'Business',
                index: 1,
                currentIndex: currentIndex,
              ),
            ),
            SizedBox(
              width: 74,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showModuleCenter(
                    context,
                    snapshotAsync,
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apps_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.notifications_none_rounded,
                label: 'Alerts',
                index: 2,
                currentIndex: currentIndex,
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                index: 3,
                currentIndex: currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final selected = currentIndex == index;

    return InkWell(
      onTap: () => _onItemTap(context, index),
      child: SizedBox(
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? blue : muted,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? navy : muted,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModuleCenter(
    BuildContext context,
    AsyncValue<DashboardSnapshot?> snapshotAsync,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            color: blue,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: snapshotAsync.when(
                            loading: () => const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NUSA-DHIPA',
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Module Center',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            error: (error, stack) => const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NUSA-DHIPA',
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Module Center',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            data: (snapshot) {
                              if (snapshot == null) {
                                return const Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NUSA-DHIPA',
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Module Center',
                                      style: TextStyle(
                                        color: navy,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final businessContext =
                                  BusinessModuleResolver
                                      .fromSnapshot(snapshot);

                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessContext.businessType
                                            .isNotEmpty
                                        ? businessContext.businessType
                                        : 'NUSA-DHIPA',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _modeTitle(
                                      businessContext.mode,
                                    ),
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: snapshotAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => const Center(
                        child: Text(
                          'Business modules unavailable',
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      data: (snapshot) {
                        if (snapshot == null) {
                          return const Center(
                            child: Text(
                              'No business selected',
                              style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        final businessContext =
                            BusinessModuleResolver
                                .fromSnapshot(snapshot);

                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            30,
                          ),
                          children: [
                            _sectionTitle('BUSINESS'),
                            _moduleGrid(
                              sheetContext,
                              businessContext.modules,
                            ),
                            const SizedBox(height: 12),
                            _businessContextInfo(
                              businessContext,
                            ),
                          ],
                        );
                      },
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
        return 'Business Modules';
    }
  }

  Widget _businessContextInfo(BusinessContext context) {
    final kbli = context.kbliCode.isNotEmpty
        ? 'KBLI ${context.kbliCode}'
        : 'KBLI not set';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_rounded,
            color: muted,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$kbli • Modules adapt to your business activity',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _moduleGrid(
    BuildContext context,
    List<BusinessModule> modules,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.25,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];

        return InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            Navigator.pop(context);
            context.go(module.route);
          },
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _moduleIcon(module.capability),
                    color: blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _moduleSubtitle(module.capability),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      case BusinessCapability.aiCopilot:
        return Icons.auto_awesome_rounded;
      case BusinessCapability.reports:
        return Icons.bar_chart_rounded;
      case BusinessCapability.legal:
        return Icons.gavel_rounded;
      case BusinessCapability.notifications:
        return Icons.notifications_rounded;
      case BusinessCapability.settings:
        return Icons.settings_rounded;
      case BusinessCapability.employees:
        return Icons.badge_rounded;
    }
  }

  String _moduleSubtitle(BusinessCapability capability) {
    switch (capability) {
      case BusinessCapability.products:
        return 'Product catalog';
      case BusinessCapability.services:
        return 'Service catalog';
      case BusinessCapability.menu:
        return 'Food & beverage menu';
      case BusinessCapability.orders:
        return 'Order management';
      case BusinessCapability.inventory:
        return 'Stock control';
      case BusinessCapability.purchases:
        return 'Purchase management';
      case BusinessCapability.suppliers:
        return 'Supplier management';
      case BusinessCapability.sales:
        return 'Sales transactions';
      case BusinessCapability.customers:
        return 'Customer management';
      case BusinessCapability.quotations:
        return 'Quotes & proposals';
      case BusinessCapability.invoices:
        return 'Billing & invoices';
      case BusinessCapability.payments:
        return 'Payment tracking';
      case BusinessCapability.finance:
        return 'Financial overview';
      case BusinessCapability.serviceOrders:
        return 'Service order management';
      case BusinessCapability.spareparts:
        return 'Parts catalog';
      case BusinessCapability.aiCopilot:
        return 'Business assistant';
      case BusinessCapability.reports:
        return 'Business analytics';
      case BusinessCapability.legal:
        return 'Legal & registration';
      case BusinessCapability.notifications:
        return 'Alerts & updates';
      case BusinessCapability.settings:
        return 'App configuration';
      case BusinessCapability.employees:
        return 'Business workspace';
    }
  }
}


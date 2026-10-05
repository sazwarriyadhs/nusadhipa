import 'package:flutter/material.dart';
import '../../core/theme/nusa_dhipa_theme.dart';
import '../../core/widgets/brand_header.dart';

class KitchenHomePage extends StatelessWidget {
  const KitchenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const NusaDhipaBrandHeader(
            title: 'RM Abah Kenari',
            subtitle: 'Kitchen • Kitchen Display',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text(
                  'Kitchen Orders',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Pesanan yang perlu diproses dapur.',
                  style: TextStyle(color: NusaDhipaColors.textSecondary),
                ),
                SizedBox(height: 20),
                _KitchenOrderCard(
                  orderNumber: '#ORDER-001',
                  table: 'Meja 01',
                  status: 'NEW',
                  items: ['Nasi Ayam × 2', 'Es Teh × 2'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final String orderNumber;
  final String table;
  final String status;
  final List<String> items;

  const _KitchenOrderCard({
    required this.orderNumber,
    required this.table,
    required this.status,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NusaDhipaColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              table,
              style: const TextStyle(color: NusaDhipaColors.textSecondary),
            ),
            const Divider(height: 28),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Mulai Diproses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

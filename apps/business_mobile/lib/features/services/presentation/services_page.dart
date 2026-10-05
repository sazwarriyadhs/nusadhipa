import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';

import '../../../core/widgets/business_bottom_navigation.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/data/models/catalog_product.dart';
import '../../catalog/providers/catalog_provider.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  static const categories = <ServiceCategory>[
    ServiceCategory('Software Development', Icons.code_rounded, [
      'Custom Web App',
      'Mobile App',
      'Desktop App',
      'Enterprise Application',
    ]),
    ServiceCategory('AI & Automation', Icons.smart_toy_rounded, [
      'AI Agent',
      'AI Chatbot',
      'Business AI',
      'Workflow Automation',
      'AI Document Processing',
    ]),
    ServiceCategory('Enterprise IT', Icons.business_rounded, [
      'System Integration',
      'API Integration',
      'Microservices',
      'ERP / HIS / POS / CRM',
    ]),
    ServiceCategory('Cloud & DevOps', Icons.cloud_rounded, [
      'Cloud Migration',
      'Docker',
      'CI/CD',
      'Server Deployment',
      'Monitoring',
    ]),
    ServiceCategory('Data & Analytics', Icons.analytics_rounded, [
      'Dashboard',
      'BI',
      'Reporting',
      'Data Integration',
      'Predictive Analytics',
    ]),
    ServiceCategory('GIS & Tracking', Icons.map_rounded, [
      'Fleet Tracking',
      'Courier Tracking',
      'Asset Tracking',
      'Geospatial Dashboard',
    ]),
    ServiceCategory('Cybersecurity', Icons.security_rounded, [
      'Security Assessment',
      'Hardening',
      'Access Control',
      'Backup & Disaster Recovery',
    ]),
    ServiceCategory('Digital Product', Icons.phone_android_rounded, [
      'Marketplace',
      'Community Platform',
      'Booking System',
      'Loyalty System',
    ]),
    ServiceCategory('Industry Solutions', Icons.factory_rounded, [
      'Logistics',
      'Retail',
      'Healthcare',
      'Plantation',
      'Manufacturing',
      'Maritime',
    ]),
    ServiceCategory('IT Consulting', Icons.psychology_rounded, [
      'IT Architecture',
      'Digital Transformation',
      'Technology Strategy',
      'System Assessment',
    ]),
    ServiceCategory('IT Maintenance', Icons.build_circle_rounded, [
      'Application Maintenance',
      'Technical Support',
      'Server/Application Monitoring',
    ]),
    ServiceCategory('Training', Icons.school_rounded, [
      'Programming',
      'AI',
      'Cloud',
      'DevOps',
      'Cybersecurity',
      'Digital Transformation',
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessIdAsync = ref.watch(businessIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: const BusinessBottomNavigation(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'Services',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: businessIdAsync.when(
        data: (businessId) {
          if (businessId == null || businessId.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah Layanan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => _openForm(context, ref, businessId),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, _) => const SizedBox.shrink(),
      ),
      body: businessIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(businessIdProvider),
        ),
        data: (businessId) {
          if (businessId == null || businessId.isEmpty) {
            return const _EmptyBusinessState();
          }

          return _ServicesBody(businessId: businessId, categories: categories);
        },
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    String businessId, {
    CatalogProduct? service,
    String? category,
  }) async {
    final repository = ref.read(catalogRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        businessId: businessId,
        repository: repository,
        service: service,
        initialCategory: category,
        onSaved: () {
          ref.invalidate(catalogProductsProvider(businessId));
        },
      ),
    );

    ref.invalidate(catalogProductsProvider(businessId));
  }
}

class ServiceCategory {
  final String name;
  final IconData icon;
  final List<String> services;

  const ServiceCategory(this.name, this.icon, this.services);
}

class _ServicesBody extends ConsumerWidget {
  final String businessId;
  final List<ServiceCategory> categories;

  const _ServicesBody({required this.businessId, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(catalogProductsProvider(businessId));

    return RefreshIndicator(
      color: const Color(0xFFD32F2F),
      onRefresh: () async {
        ref.invalidate(catalogProductsProvider(businessId));
        await ref.read(catalogProductsProvider(businessId).future);
      },
      child: servicesAsync.when(
        loading: () => const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: _LoadingState(),
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            _ErrorState(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(catalogProductsProvider(businessId));
              },
            ),
          ],
        ),
        data: (allProducts) {
          final services = allProducts
              .where((item) => item.productType.toLowerCase() == 'service')
              .toList();

          final active = services
              .where((item) => item.status.toLowerCase() == 'active')
              .length;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              _Hero(
                total: services.length,
                active: active,
                onAdd: () => ServicesPage._openForm(context, ref, businessId),
              ),
              const SizedBox(height: 20),
              _StatsRow(
                total: services.length,
                active: active,
                categories: categories.length,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Layanan Saya',
                subtitle: services.isEmpty
                    ? 'Belum ada layanan yang dipublikasikan.'
                    : 'Layanan aktif otomatis tersedia di Marketplace.',
              ),
              const SizedBox(height: 12),
              if (services.isEmpty)
                _EmptyServices(
                  onAdd: () => ServicesPage._openForm(context, ref, businessId),
                )
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceCard(
                      service: service,
                      onEdit: () => ServicesPage._openForm(
                        context,
                        ref,
                        businessId,
                        service: service,
                      ),
                      onDelete: () =>
                          _delete(context, ref, businessId, service),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Kategori Layanan',
                subtitle: 'Template layanan khusus PT DIGI MEDIA KOMUNIKA.',
              ),
              const SizedBox(height: 12),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryCard(
                    category: category,
                    existingServices: services,
                    onAdd: (name) => ServicesPage._openForm(
                      context,
                      ref,
                      businessId,
                      category: category.name,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String businessId,
    CatalogProduct service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text('Layanan "${service.name}" akan dihapus dari katalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(catalogRepositoryProvider)
          .deleteProduct(businessId: businessId, productId: service.id);

      ref.invalidate(catalogProductsProvider(businessId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan berhasil dihapus.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $error')));
      }
    }
  }
}

class _Hero extends StatelessWidget {
  final int total;
  final int active;
  final VoidCallback onAdd;

  const _Hero({required this.total, required this.active, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIGI SERVICES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$total layanan • $active aktif di Marketplace',
                  style: const TextStyle(
                    color: Color(0xFFFFEAEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB71C1C),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int categories;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TOTAL',
            value: '$total',
            icon: Icons.grid_view_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'ACTIVE',
            value: '$active',
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'CATEGORIES',
            value: '$categories',
            icon: Icons.category_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD32F2F), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF737373),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF222222),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF737373), fontSize: 12),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final CatalogProduct service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = service.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        active ? 'MARKETPLACE' : 'INACTIVE',
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF737373),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF737373),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  service.price > 0
                      ? 'Mulai Rp ${_formatPrice(service.price)} / ${service.unit}'
                      : 'Harga berdasarkan kebutuhan / ${service.unit}',
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final List<CatalogProduct> existingServices;
  final void Function(String name) onAdd;

  const _CategoryCard({
    required this.category,
    required this.existingServices,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final existingNames = existingServices
        .map((item) => item.name.toLowerCase())
        .toSet();

    final available = category.services.where(
      (name) => !existingNames.contains(name.toLowerCase()),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(category.icon, color: const Color(0xFFD32F2F), size: 21),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Text(
          '${category.services.length} template layanan',
          style: const TextStyle(color: Color(0xFF737373), fontSize: 11),
        ),
        children: [
          for (final service in available)
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFFD32F2F),
                size: 20,
              ),
              title: Text(
                service,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: TextButton(
                onPressed: () => onAdd(service),
                child: const Text('Tambah'),
              ),
            ),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Semua template di kategori ini sudah ditambahkan.',
                style: TextStyle(color: Color(0xFF737373), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  final String businessId;
  final CatalogRepository repository;
  final CatalogProduct? service;
  final String? initialCategory;
  final VoidCallback onSaved;

  const _ServiceFormSheet({
    required this.businessId,
    required this.repository,
    required this.service,
    required this.initialCategory,
    required this.onSaved,
  });

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  late final TextEditingController nameController;
  late final TextEditingController skuController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController unitController;

  String? selectedCategory;
  bool saving = false;

  List<String> get categoryNames =>
      ServicesPage.categories.map((item) => item.name).toList();

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    nameController = TextEditingController(text: service?.name ?? '');
    skuController = TextEditingController(text: service?.sku ?? '');
    descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    priceController = TextEditingController(
      text: service != null && service.price > 0
          ? service.price.toStringAsFixed(0)
          : '',
    );
    unitController = TextEditingController(text: service?.unit ?? 'project');

    selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    unitController.dispose();
    super.dispose();
  }

  String _generateSku(String name) {
    final normalized = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return 'DIGI-SVC';
    }

    final words = normalized.split(RegExp(r'\s+'));

    final code = words.length == 1
        ? words.first.substring(
            0,
            words.first.length > 8 ? 8 : words.first.length,
          )
        : words.map((word) => word[0]).join();

    return 'DIGI-$code';
  }

  Future<void> _save() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      _showError('Nama layanan wajib diisi.');
      return;
    }

    if (skuController.text.trim().isEmpty) {
      skuController.text = _generateSku(name);
    }

    final price =
        double.tryParse(
          priceController.text.trim().replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    setState(() => saving = true);

    try {
      if (widget.service == null) {
        await widget.repository.createProduct(
          businessId: widget.businessId,
          sku: skuController.text.trim(),
          name: name,
          description: descriptionController.text.trim(),
          productType: 'service',
          unit: unitController.text.trim().isEmpty
              ? 'project'
              : unitController.text.trim(),
          price: price,
          costPrice: 0,
          trackInventory: false,
        );
      } else {
        await widget.repository.updateProduct(
          businessId: widget.businessId,
          productId: widget.service!.id,
          sku: skuController.text.trim(),
          name: name,
          description: descriptionController.text.trim(),
          categoryId: widget.service!.categoryId,
          productType: 'service',
          unit: unitController.text.trim().isEmpty
              ? 'project'
              : unitController.text.trim(),
          price: price,
          costPrice: widget.service!.costPrice,
          trackInventory: false,
        );
      }

      widget.onSaved();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null
                  ? 'Layanan berhasil ditambahkan dan aktif di Marketplace.'
                  : 'Layanan berhasil diperbarui.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        _showError(error.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.service != null;

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 850),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                editing ? 'Edit Layanan' : 'Tambah Layanan',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Layanan aktif akan tersedia di Marketplace NUSA-DHIPA.',
                style: TextStyle(color: Color(0xFF737373), fontSize: 12),
              ),
              const SizedBox(height: 22),
              _Field(
                controller: nameController,
                label: 'Nama Layanan *',
                hint: 'Contoh: AI Chatbot',
                icon: Icons.design_services_rounded,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: skuController,
                label: 'Kode Layanan / SKU',
                hint: 'Otomatis jika dikosongkan',
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: _inputDecoration(
                  'Kategori',
                  Icons.category_rounded,
                ),
                items: categoryNames
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() => selectedCategory = value);
                      },
              ),
              const SizedBox(height: 14),
              _Field(
                controller: descriptionController,
                label: 'Deskripsi',
                hint: 'Jelaskan layanan dan ruang lingkupnya',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: priceController,
                label: 'Harga Mulai',
                hint: 'Kosongkan jika berdasarkan quotation',
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: unitController,
                label: 'Satuan',
                hint: 'project / hour / month',
                icon: Icons.straighten_rounded,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: Color(0xFFD32F2F)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Layanan akan menggunakan product_type = service '
                        'dan track_inventory = false. Status active akan '
                        'membuatnya terbaca oleh Marketplace.',
                        style: TextStyle(
                          color: Color(0xFF7F1D1D),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    saving
                        ? 'Menyimpan...'
                        : editing
                        ? 'Simpan Perubahan'
                        : 'Simpan & Publikasikan',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyServices({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_repair_service_outlined,
            size: 48,
            color: Color(0xFFD32F2F),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Layanan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan layanan DIGI untuk mulai tampil di Marketplace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF737373),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Layanan'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFFD32F2F),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat Services',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF737373), fontSize: 11),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _EmptyBusinessState extends StatelessWidget {
  const _EmptyBusinessState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Business context belum tersedia.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _formatPrice(double value) {
  final rounded = value.round().toString();
  final chars = rounded.split('');
  final buffer = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && (chars.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(chars[i]);
  }

  return buffer.toString();
}

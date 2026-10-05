import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/kbli_catalog.dart';
import '../data/models/business_setup_data.dart';
import '../../../core/config/providers.dart';
import '../../business/providers/business_provider.dart';

class BusinessSetupPage extends ConsumerStatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  ConsumerState<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends ConsumerState<BusinessSetupPage> {
  static const blue = Color(0xFF1769FF);
  static const navy = Color(0xFF123B68);
  static const muted = Color(0xFF718096);
  static const border = Color(0xFFE5EAF0);
  static const background = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _activityController = TextEditingController();

  String? _businessType;
  KbliOption? _selectedKbli;

  bool _saving = false;

  final List<String> _businessTypes = const [
    'Retail / Grosir',
    'F&B',
    'Salon / Beauty',
    'Fashion',
    'Service / Bengkel',
    'Online Seller',
    'Agriculture',
    'Property / Kos',
    'Freelancer',
    'Course / Training',
    'Travel',
    'Ticketing',
    'Professional Service',
    'Lainnya',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_businessType == null) {
      _showMessage('Pilih jenis bisnis terlebih dahulu.');
      return;
    }

    if (_selectedKbli == null) {
      _showMessage('Pilih KBLI atau aktivitas usaha.');
      return;
    }

    final businessId = await ref.read(businessIdProvider.future);

    if (businessId == null || businessId.isEmpty) {
      _showMessage('Business ID tidak ditemukan. Silakan login kembali.');
      return;
    }

    final setup = BusinessSetupData(
      businessName: _businessNameController.text.trim(),
      businessType: _businessType!,
      activity: _activityController.text.trim(),
      kbliCode: _selectedKbli!.code,
      kbliName: _selectedKbli!.name,
    );

    setState(() {
      _saving = true;
    });

    try {
      await ref
          .read(businessRepositoryProvider)
          .updateProfile(
            businessId: businessId,
            name: setup.businessName,
            businessType: setup.businessType,
            activity: setup.activity,
            kbliCode: setup.kbliCode,
            kbliName: setup.kbliName,
            phone: '+62 812-0000-0000',
            email: 'info@rajatelur.demo',
            address:
                'Cimahpar Stoneyard Bogor Blok E No 1 Cimahpar Bogor, 16155',
            shortName: setup.businessName,
            tagline: 'Pusat Telur Segar & Berkualitas',
            description:
                'Raja Telur menyediakan telur segar dan kebutuhan pangan pilihan untuk rumah tangga, UMKM, warung, dan pelanggan usaha di wilayah Bogor.',
            whatsapp: '+62 812-0000-0000',
            website: 'https://rajatelur.demo',
            logoUrl: 'assets/business/raja_telur_logo.png',
            coverImageUrl: 'assets/images/header.png',
            brandColor: '#F59E0B',
          );

      ref.invalidate(businessProfileProvider);

      if (!mounted) {
        return;
      }

      _showMessage('Business profile berhasil disimpan.');

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) {
        return;
      }

      context.go('/dashboard');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Gagal menyimpan business profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text(
          'Business Setup',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              const Text(
                'Siapkan profil bisnis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Informasi ini menjadi konteks utama untuk Catalog, '
                'Inventory, Sales, Finance, dan AI Business Assistant.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 28),

              _sectionTitle('01', 'Business Profile'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _businessNameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Nama bisnis',
                  Icons.storefront_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama bisnis wajib diisi';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _businessType,
                decoration: _inputDecoration(
                  'Jenis bisnis',
                  Icons.business_outlined,
                ),
                items: _businessTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _businessType = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _activityController,
                maxLines: 2,
                decoration: _inputDecoration(
                  'Aktivitas usaha utama',
                  Icons.work_outline_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Aktivitas usaha wajib diisi';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              _sectionTitle('02', 'KBLI / Aktivitas Usaha'),

              const SizedBox(height: 8),

              const Text(
                'KBLI digunakan sebagai business context. '
                'Belum memiliki legalitas bukan berarti bisnis tidak dapat berjalan.',
                style: TextStyle(color: muted, height: 1.5),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<KbliOption>(
                initialValue: _selectedKbli,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Pilih KBLI',
                  Icons.account_tree_outlined,
                ),
                items: KbliCatalog.options
                    .map(
                      (option) => DropdownMenuItem<KbliOption>(
                        value: option,
                        child: Text(
                          '${option.code} — ${option.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedKbli = value;
                  });
                },
                validator: (_) {
                  if (_selectedKbli == null) {
                    return 'KBLI / aktivitas usaha wajib dipilih';
                  }

                  return null;
                },
              ),

              if (_selectedKbli != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_outlined, color: blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedKbli!.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedKbli!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedKbli!.description,
                              style: const TextStyle(color: muted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Legalitas belum lengkap? Tidak masalah. '
                        'Bisnis tetap dapat berjalan. Nusa Dhipa dapat '
                        'membantu proses legalitas secara paralel.',
                        style: TextStyle(color: muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Simpan & Lanjut ke Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: blue,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
    );
  }
}


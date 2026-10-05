import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/widgets/business_bottom_navigation.dart';
import '../providers/business_provider.dart';

class BusinessPage extends ConsumerStatefulWidget {
  const BusinessPage({super.key});

  @override
  ConsumerState<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends ConsumerState<BusinessPage> {
  static const _primary = Color(0xFFE5232E);
  static const _navy = Color(0xFF171717);
  static const _background = Color(0xFFF7F9FC);
  static const _border = Color(0xFFE5EAF0);
  static const _muted = Color(0xFF718096);
  static const _success = Color(0xFF16A34A);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _activityController = TextEditingController();
  final _kbliCodeController = TextEditingController();
  final _kbliNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  final _addressController = TextEditingController();

  final _logoUrlController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  final _brandColorController = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _taglineController.dispose();
    _businessTypeController.dispose();
    _activityController.dispose();
    _kbliCodeController.dispose();
    _kbliNameController.dispose();
    _descriptionController.dispose();

    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();

    _addressController.dispose();

    _logoUrlController.dispose();
    _coverImageUrlController.dispose();
    _brandColorController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  void _populate(Map<String, dynamic> data) {
    if (_initialized) {
      return;
    }

    _nameController.text = _string(data['name']);
    _shortNameController.text = _string(data['short_name']);
    _taglineController.text = _string(data['tagline']);

    _businessTypeController.text = _normalizeBusinessType(
      _string(data['business_type']),
    );

    _activityController.text = _string(data['activity']);
    _kbliCodeController.text = _string(data['kbli_code']);
    _kbliNameController.text = _string(data['kbli_name']);
    _descriptionController.text = _string(data['description']);

    _phoneController.text = _string(data['phone']);
    _whatsappController.text = _string(data['whatsapp']);
    _emailController.text = _string(data['email']);
    _websiteController.text = _string(data['website']);

    _addressController.text = _string(data['address']);

    _logoUrlController.text = _string(data['logo_url']);
    _coverImageUrlController.text = _string(data['cover_image_url']);

    final brandColor = _string(data['brand_color']);
    _brandColorController.text =
        brandColor.isEmpty ? '#E5232E' : brandColor;

    _initialized = true;
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  /// Canonical business modes used by BusinessModuleResolver.
  ///
  /// The UI may receive legacy/display values such as:
  /// "Retail / Grosir", "F&B", "Salon / Beauty", etc.
  ///
  /// Internally we keep a small canonical vocabulary so every UMKM
  /// can use the same business engine.
  String _normalizeBusinessType(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'general';
    }

    switch (normalized) {
      case 'product':
      case 'products':
      case 'produk':
      case 'retail':
      case 'retail / grosir':
      case 'retail/grosir':
      case 'grosir':
      case 'fashion':
      case 'online seller':
      case 'agriculture':
      case 'pertanian':
        return 'product';

      case 'service':
      case 'services':
      case 'jasa':
      case 'service / bengkel':
      case 'service/bengkel':
      case 'salon / beauty':
      case 'salon/beauty':
      case 'freelancer':
      case 'professional service':
      case 'property / kos':
      case 'property/kos':
      case 'course / training':
      case 'course/training':
      case 'travel':
      case 'ticketing':
        return 'service';

      case 'hybrid':
      case 'product + service':
      case 'product/service':
      case 'produk + jasa':
      case 'produk dan layanan':
      case 'produk & layanan':
        return 'hybrid';

      case 'food':
      case 'f&b':
      case 'fnb':
      case 'food & beverage':
      case 'restaurant':
      case 'restoran':
      case 'cafe':
      case 'café':
        return 'food';

      case 'workshop':
      case 'bengkel':
        return 'workshop';

      case 'general':
      case 'umum':
      case 'lainnya':
        return 'general';

      default:
        return value.trim();
    }
  }

  String _businessTypeLabel(String value) {
    switch (_normalizeBusinessType(value)) {
      case 'product':
        return 'Product Business';

      case 'service':
        return 'Service Business';

      case 'hybrid':
        return 'Product & Service';

      case 'food':
        return 'Food & Beverage';

      case 'workshop':
        return 'Workshop / Bengkel';

      case 'general':
        return 'General Business';

      default:
        return value;
    }
  }

  // ---------------------------------------------------------------------------
  // COLOR / IMAGE
  // ---------------------------------------------------------------------------

  Color _brandColor() {
    final raw = _brandColorController.text.trim();

    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;

    if (normalized.length == 6) {
      final value = int.tryParse(
        'FF$normalized',
        radix: 16,
      );

      if (value != null) {
        return Color(value);
      }
    }

    if (normalized.length == 8) {
      final value = int.tryParse(
        normalized,
        radix: 16,
      );

      if (value != null) {
        return Color(value);
      }
    }

    return _primary;
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  Widget _logoPreview({
    required String value,
    double size = 88,
  }) {
    final url = value.trim();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: url.isEmpty
          ? Icon(
              Icons.storefront_rounded,
              size: size * .42,
              color: _muted,
            )
          : _isNetworkImage(url)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) {
                return Icon(
                  Icons.storefront_rounded,
                  size: size * .42,
                  color: _muted,
                );
              },
            )
          : Image.asset(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) {
                return Icon(
                  Icons.storefront_rounded,
                  size: size * .42,
                  color: _muted,
                );
              },
            ),
    );
  }

  Widget _coverPreview() {
    final url = _coverImageUrlController.text.trim();

    if (url.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _brandColor(),
              _navy,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            color: Colors.white70,
            size: 42,
          ),
        ),
      );
    }

    final image = _isNetworkImage(url)
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) {
              return Container(
                color: _navy,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 38,
                  ),
                ),
              );
            },
          )
        : Image.asset(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) {
              return Container(
                color: _navy,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 38,
                  ),
                ),
              );
            },
          );

    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: image,
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final businessId = await ref.read(businessIdProvider.future);

    if (businessId == null || businessId.isEmpty) {
      _showMessage(
        'Business ID tidak ditemukan.',
        error: true,
      );
      return;
    }

    final canonicalBusinessType = _normalizeBusinessType(
      _businessTypeController.text,
    );

    setState(() {
      _saving = true;
    });

    try {
      await ref
          .read(businessRepositoryProvider)
          .updateProfile(
            businessId: businessId,
            name: _nameController.text.trim(),
            businessType: canonicalBusinessType,
            activity: _activityController.text.trim(),
            kbliCode: _kbliCodeController.text.trim(),
            kbliName: _kbliNameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
            shortName: _shortNameController.text.trim(),
            tagline: _taglineController.text.trim(),
            description: _descriptionController.text.trim(),
            whatsapp: _whatsappController.text.trim(),
            website: _websiteController.text.trim(),
            logoUrl: _logoUrlController.text.trim(),
            coverImageUrl: _coverImageUrlController.text.trim(),
            brandColor: _brandColorController.text.trim(),
          );

      ref.invalidate(businessProfileProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _editing = false;
        _initialized = false;
      });

      _showMessage(
        'Business Profile berhasil disimpan.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Gagal menyimpan Business Profile: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CANCEL / EDIT
  // ---------------------------------------------------------------------------

  void _startEditing() {
    setState(() {
      _editing = true;
    });
  }

  void _cancelEditing() {
    if (_saving) {
      return;
    }

    // Refresh provider so the form is repopulated from the
    // last persisted backend state instead of keeping unsaved edits.
    ref.invalidate(businessProfileProvider);

    setState(() {
      _editing = false;
      _initialized = false;
    });
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              error ? Colors.red.shade700 : _success,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // FORM
  // ---------------------------------------------------------------------------

  InputDecoration _decoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 20,
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && _editing && !_saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(
        label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _section({
    required String eyebrow,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _identityHeader(
    Map<String, dynamic> data,
  ) {
    final name = _string(data['name']);
    final tagline = _string(data['tagline']);
    final status = _string(data['status']).toUpperCase();
    final type = _businessTypeLabel(
      _string(data['business_type']),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brandColor(),
            _navy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _logoPreview(
            value: _string(data['logo_url']),
            size: 82,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'BUSINESS IDENTITY',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: .7,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name.isEmpty
                      ? 'Business Owner'
                      : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: .82,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: .12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: .14,
              ),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status.isEmpty
                      ? 'ACTIVE'
                      : status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BAR
  // ---------------------------------------------------------------------------

  Widget _actionBar() {
    return Row(
      children: [
        if (_editing)
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _saving ? null : _cancelEditing,
              icon: const Icon(
                Icons.close_rounded,
              ),
              label: const Text('Cancel'),
            ),
          ),
        if (_editing)
          const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving
                ? null
                : () {
                    if (_editing) {
                      _save();
                    } else {
                      _startEditing();
                    }
                  },
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _editing
                        ? Icons.save_rounded
                        : Icons.edit_rounded,
                  ),
            label: Text(
              _saving
                  ? 'Saving...'
                  : _editing
                  ? 'Save Changes'
                  : 'Edit Profile',
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Business Profile',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_editing)
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: IconButton(
                tooltip: 'Edit Business',
                onPressed: _startEditing,
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: _primary,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          const BusinessBottomNavigation(),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: _muted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Business Profile gagal dimuat.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(
                      businessProfileProvider,
                    );
                    setState(() {
                      _initialized = false;
                    });
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text(
                'Business belum tersedia.',
              ),
            );
          }

          _populate(data);

          return Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 800;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 16,
                    18,
                    wide ? 32 : 16,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1080,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _identityHeader(data),

                          _section(
                            eyebrow: '01',
                            title: 'Business Identity',
                            icon: Icons.storefront_rounded,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _logoPreview(
                                      value:
                                          _logoUrlController
                                              .text,
                                      size: 96,
                                    ),
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _field(
                                            _nameController,
                                            'Business Name',
                                            icon: Icons
                                                .business_rounded,
                                            validator:
                                                (value) {
                                              if (value ==
                                                      null ||
                                                  value
                                                      .trim()
                                                      .isEmpty) {
                                                return 'Nama bisnis wajib diisi';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          _field(
                                            _shortNameController,
                                            'Short Name',
                                            icon: Icons
                                                .short_text_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                _field(
                                  _taglineController,
                                  'Tagline',
                                  icon: Icons
                                      .auto_awesome_rounded,
                                  hint:
                                      'Tagline bisnis Anda',
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                _field(
                                  _logoUrlController,
                                  'Business Logo',
                                  icon: Icons.image_rounded,
                                  hint:
                                      'assets/business/logo.png atau https://...',
                                ),
                              ],
                            ),
                          ),

                          _section(
                            eyebrow: '02',
                            title: 'Business Information',
                            icon: Icons.badge_rounded,
                            child: Column(
                              children: [
                                if (wide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _field(
                                          _businessTypeController,
                                          'Business Mode',
                                          icon: Icons
                                              .category_rounded,
                                          hint:
                                              'product / service / hybrid / food / workshop',
                                          validator:
                                              (value) {
                                            if (value ==
                                                    null ||
                                                value
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Business mode wajib diisi';
                                            }

                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: _field(
                                          _activityController,
                                          'Activity',
                                          icon: Icons
                                              .work_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _field(
                                    _businessTypeController,
                                    'Business Mode',
                                    icon: Icons
                                        .category_rounded,
                                    hint:
                                        'product / service / hybrid / food / workshop',
                                    validator:
                                        (value) {
                                      if (value ==
                                              null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Business mode wajib diisi';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  _field(
                                    _activityController,
                                    'Activity',
                                    icon: Icons
                                        .work_outline_rounded,
                                  ),
                                ],
                                const SizedBox(
                                  height: 12,
                                ),
                                if (wide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _field(
                                          _kbliCodeController,
                                          'Primary KBLI Code',
                                          icon: Icons
                                              .numbers_rounded,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _field(
                                          _kbliNameController,
                                          'Primary KBLI Name',
                                          icon: Icons
                                              .description_rounded,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _field(
                                    _kbliCodeController,
                                    'Primary KBLI Code',
                                    icon: Icons
                                        .numbers_rounded,
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  _field(
                                    _kbliNameController,
                                    'Primary KBLI Name',
                                    icon: Icons
                                        .description_rounded,
                                  ),
                                ],
                                const SizedBox(
                                  height: 12,
                                ),
                                _field(
                                  _descriptionController,
                                  'Business Description',
                                  icon: Icons.notes_rounded,
                                  maxLines: 5,
                                ),
                              ],
                            ),
                          ),

                          _section(
                            eyebrow: '03',
                            title: 'Contact',
                            icon: Icons.contact_phone_rounded,
                            child: Column(
                              children: [
                                if (wide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _field(
                                          _phoneController,
                                          'Phone',
                                          icon: Icons
                                              .phone_rounded,
                                          keyboardType:
                                              TextInputType.phone,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: _field(
                                          _whatsappController,
                                          'WhatsApp',
                                          icon: Icons
                                              .chat_rounded,
                                          keyboardType:
                                              TextInputType.phone,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _field(
                                    _phoneController,
                                    'Phone',
                                    icon: Icons
                                        .phone_rounded,
                                    keyboardType:
                                        TextInputType.phone,
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  _field(
                                    _whatsappController,
                                    'WhatsApp',
                                    icon: Icons
                                        .chat_rounded,
                                    keyboardType:
                                        TextInputType.phone,
                                  ),
                                ],
                                const SizedBox(
                                  height: 12,
                                ),
                                if (wide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _field(
                                          _emailController,
                                          'Email',
                                          icon: Icons
                                              .email_rounded,
                                          keyboardType:
                                              TextInputType
                                                  .emailAddress,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: _field(
                                          _websiteController,
                                          'Website',
                                          icon: Icons
                                              .language_rounded,
                                          keyboardType:
                                              TextInputType.url,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _field(
                                    _emailController,
                                    'Email',
                                    icon: Icons
                                        .email_rounded,
                                    keyboardType:
                                        TextInputType
                                            .emailAddress,
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  _field(
                                    _websiteController,
                                    'Website',
                                    icon: Icons
                                        .language_rounded,
                                    keyboardType:
                                        TextInputType.url,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          _section(
                            eyebrow: '04',
                            title: 'Location',
                            icon: Icons
                                .location_on_rounded,
                            child: _field(
                              _addressController,
                              'Business Address',
                              icon: Icons
                                  .location_on_rounded,
                              maxLines: 4,
                            ),
                          ),

                          _section(
                            eyebrow: '05',
                            title: 'Appearance',
                            icon: Icons.palette_rounded,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            _brandColor(),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: _field(
                                        _brandColorController,
                                        'Brand Color',
                                        icon: Icons
                                            .color_lens_rounded,
                                        hint: '#E5232E',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                _field(
                                  _coverImageUrlController,
                                  'Cover Image',
                                  icon: Icons
                                      .wallpaper_rounded,
                                  hint:
                                      'assets/images/header.png atau https://...',
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                _coverPreview(),
                              ],
                            ),
                          ),

                          _actionBar(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';

class DashboardSnapshot {
  final Map<String, dynamic>? business;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? legal;
  final DateTime fetchedAt;

  const DashboardSnapshot({
    required this.business,
    required this.products,
    required this.legal,
    required this.fetchedAt,
  });

  // ============================================================
  // PRODUCT METRICS
  // ============================================================

  int get productCount {
    return products.where((product) {
      return !_isService(product);
    }).length;
  }

  int get activeProductCount {
    return products.where((product) {
      return !_isService(product) && _isActive(product);
    }).length;
  }

  int get inactiveProductCount {
    return products.where((product) {
      return !_isService(product) && !_isActive(product);
    }).length;
  }

  // ============================================================
  // SERVICE METRICS
  // ============================================================

  /// Total real services returned by Catalog API.
  ///
  /// A catalog item is a service only when:
  /// product_type == "service".
  int get serviceCount {
    return products.where(_isService).length;
  }

  /// Total real services explicitly marked active.
  ///
  /// Only status == ACTIVE or active == true is counted.
  /// Missing status/active is NOT assumed to be active.
  int get activeServiceCount {
    return products
        .where((product) => _isService(product) && _isActive(product))
        .length;
  }

  /// Total real services that are not active.
  int get inactiveServiceCount {
    return products
        .where((product) => _isService(product) && !_isActive(product))
        .length;
  }

  // ============================================================
  // BUSINESS
  // ============================================================

  String get businessName {
    final value = business?['name'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return 'Business Owner';
  }

  String get businessType {
    final value = business?['business_type'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }

    return 'general';
  }

  String get businessStatus {
    final value = business?['status'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toUpperCase();
    }

    return 'ACTIVE';
  }

  String get activity {
    final value = business?['activity'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  String get kbliCode {
    final value = business?['kbli_code'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  String get kbliName {
    final value = business?['kbli_name'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  // ============================================================
  // LEGAL
  // ============================================================

  String get nibStatus {
    final nib = _legalizationItem('nib');

    if (nib != null) {
      return (nib['status']?.toString() ?? 'NOT_REGISTERED').toUpperCase();
    }

    return 'NOT_REGISTERED';
  }

  String get ahuStatus {
    final ahu = _legalizationItem('ahu');

    if (ahu != null) {
      return (ahu['status']?.toString() ?? 'NOT_REGISTERED').toUpperCase();
    }

    return 'NOT_REGISTERED';
  }

  String get nibNumber {
    final nib = _legalizationItem('nib');

    if (nib != null) {
      return nib['number']?.toString() ?? '';
    }

    return '';
  }

  String get ahuNumber {
    final ahu = _legalizationItem('ahu');

    if (ahu != null) {
      return ahu['number']?.toString() ?? '';
    }

    return '';
  }

  bool get legalizationRequired {
    return legal?['legalization_required'] == true;
  }

  bool get canOperate {
    return legal?['can_operate'] != false;
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  bool _isService(Map<String, dynamic> product) {
    final type = product['product_type']?.toString().trim().toLowerCase();

    return type == 'service';
  }

  bool _isActive(Map<String, dynamic> product) {
    final status = product['status']?.toString().trim().toUpperCase();

    if (status == 'ACTIVE') {
      return true;
    }

    if (status == 'INACTIVE') {
      return false;
    }

    final active = product['active'];

    if (active is bool) {
      return active;
    }

    // Catalog does not provide an explicit active state.
    // Never invent "active" from missing data.
    return false;
  }

  Map<String, dynamic>? _legalizationItem(String key) {
    final value = legal?['legalization'];

    if (value is Map) {
      final item = value[key];

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }
}

// ================================================================
// DASHBOARD REPOSITORY
// ================================================================

class DashboardRepository {
  final Ref ref;

  DashboardRepository(this.ref);

  Future<DashboardSnapshot> fetchSnapshot({required String businessId}) async {
    final normalizedBusinessId = businessId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError('businessId is required to load dashboard data.');
    }

    final api = ref.read(apiClientProvider);

    Map<String, dynamic>? business;
    List<Map<String, dynamic>> products = <Map<String, dynamic>>[];
    Map<String, dynamic>? legal;

    // ============================================================
    // 1. BUSINESS PROFILE
    // ============================================================

    try {
      final response = await api.dio.get(
        '/api/v1/businesses/$normalizedBusinessId',
      );

      business = _extractMap(response.data);
    } catch (_) {
      business = null;
    }

    // ============================================================
    // 2. CATALOG
    //
    // IMPORTANT:
    // business_id wajib dikirim karena Catalog Service
    // menggunakan business isolation.
    // ============================================================

    try {
      final response = await api.dio.get(
        '/api/v1/catalog/products',
        queryParameters: <String, dynamic>{'business_id': normalizedBusinessId},
      );

      products = _extractListOfMaps(response.data);
    } catch (_) {
      products = <Map<String, dynamic>>[];
    }

    // ============================================================
    // 3. LEGAL STATUS
    // ============================================================

    try {
      final response = await api.dio.get(
        '/api/v1/legal/businesses/$normalizedBusinessId/status',
      );

      legal = _extractMap(response.data);

      debugPrint('DASHBOARD LEGAL RESPONSE: ${response.data}');

      debugPrint('DASHBOARD LEGAL EXTRACTED: $legal');
    } catch (error, stackTrace) {
      legal = null;

      debugPrint('DASHBOARD LEGAL REQUEST FAILED: $error');

      debugPrint('DASHBOARD LEGAL STACK: $stackTrace');
    }

    // ============================================================
    // SNAPSHOT
    // ============================================================

    return DashboardSnapshot(
      business: business,
      products: products,
      legal: legal,
      fetchedAt: DateTime.now(),
    );
  }

  // ============================================================
  // RESPONSE PARSERS
  // ============================================================

  Map<String, dynamic>? _extractMap(dynamic responseData) {
    if (responseData is! Map) {
      return null;
    }

    dynamic current = responseData;

    // Example:
    //
    // {
    //   "success": true,
    //   "data": {
    //      ...
    //   }
    // }
    //
    if (current['data'] is Map) {
      current = current['data'];
    }

    // Example:
    //
    // {
    //   "success": true,
    //   "data": {
    //      "success": true,
    //      "data": {
    //         ...
    //      }
    //   }
    // }
    //
    while (current is Map &&
        current['data'] is Map &&
        _looksLikeWrapper(current)) {
      current = current['data'];
    }

    if (current is Map) {
      return Map<String, dynamic>.from(current);
    }

    return null;
  }

  List<Map<String, dynamic>> _extractListOfMaps(dynamic responseData) {
    if (responseData is! Map) {
      return <Map<String, dynamic>>[];
    }

    dynamic current = responseData;

    // Unwrap:
    //
    // response
    //   -> data
    //      -> list
    //
    while (current is Map && current['data'] != null) {
      final next = current['data'];

      if (next is List) {
        current = next;
        break;
      }

      if (next is Map) {
        current = next;
        continue;
      }

      break;
    }

    if (current is List) {
      return current
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  bool _looksLikeWrapper(Map current) {
    final keys = current.keys.map((key) => key.toString()).toSet();

    return keys.contains('success') ||
        keys.contains('message') ||
        keys.contains('error') ||
        keys.length <= 3;
  }
}

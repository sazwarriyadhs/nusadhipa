import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tenantIdKey = 'nusa_dhipa_tenant_id';
  static const String _businessIdKey = 'nusa_dhipa_business_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);

    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveSession({
    required String tenantId,
    required String businessId,
  }) async {
    await _storage.write(key: _tenantIdKey, value: tenantId);

    await _storage.write(key: _businessIdKey, value: businessId);
  }

  Future<String?> getTenantId() {
    return _storage.read(key: _tenantIdKey);
  }

  Future<String?> getBusinessId() {
    return _storage.read(key: _businessIdKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

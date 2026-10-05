import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  final ApiClient client;
  final TokenStorage tokenStorage;

  AuthRepository(this.client, this.tokenStorage);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await client.dio.post(
      AppConstants.loginPath,
      data: {'email': email, 'password': password},
    );

    final body = Map<String, dynamic>.from(response.data as Map);

    final outerData = Map<String, dynamic>.from(body['data'] as Map);

    // Backend currently returns:
    //
    // data
    // └── data
    //     ├── user
    //     ├── tenant
    //     ├── business
    //     ├── branch
    //     └── tokens

    final data = outerData['data'] is Map
        ? Map<String, dynamic>.from(outerData['data'] as Map)
        : outerData;

    final tokens = Map<String, dynamic>.from(data['tokens'] as Map);

    await tokenStorage.saveTokens(
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
    );

    final tenant = data['tenant'];
    final business = data['business'];

    if (tenant is Map && business is Map) {
      final tenantId = tenant['id']?.toString();
      final businessId = business['id']?.toString();

      if (tenantId != null &&
          tenantId.isNotEmpty &&
          businessId != null &&
          businessId.isNotEmpty) {
        await tokenStorage.saveSession(
          tenantId: tenantId,
          businessId: businessId,
        );
      }
    }

    return data;
  }

  Future<void> logout() async {
    await tokenStorage.clear();
  }
}

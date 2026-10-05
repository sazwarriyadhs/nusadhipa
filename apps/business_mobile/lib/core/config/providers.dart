import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.read(tokenStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  ),
);

final authStateProvider = FutureProvider<bool>((ref) async {
  final token = await ref.read(tokenStorageProvider).getAccessToken();

  return token != null && token.isNotEmpty;
});

final businessIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(tokenStorageProvider).getBusinessId();
});

final tenantIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(tokenStorageProvider).getTenantId();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../data/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.read(apiClientProvider)),
);

final businessProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final businessId = await ref.read(businessIdProvider.future);

      if (businessId == null || businessId.isEmpty) {
        return null;
      }

      return ref.read(businessRepositoryProvider).getBusiness(businessId);
    });

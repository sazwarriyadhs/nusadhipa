import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../data/legal_repository.dart';

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepository(ref.read(apiClientProvider)),
);

final businessLegalStatusProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final businessId = await ref.read(businessIdProvider.future);

      if (businessId == null || businessId.isEmpty) {
        return null;
      }

      return ref
          .read(legalRepositoryProvider)
          .getBusinessLegalStatus(businessId);
    });

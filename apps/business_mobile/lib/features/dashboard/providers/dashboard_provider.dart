import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref),
);

final dashboardSnapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot?>((ref) async {
      final businessId = await ref.read(businessIdProvider.future);

      if (businessId == null || businessId.isEmpty) {
        return null;
      }

      return ref
          .read(dashboardRepositoryProvider)
          .fetchSnapshot(businessId: businessId);
    });

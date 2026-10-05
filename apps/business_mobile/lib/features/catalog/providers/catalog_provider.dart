import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../data/catalog_repository.dart';
import '../data/models/catalog_product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.read(apiClientProvider).dio);
});

final catalogProductsProvider = FutureProvider.autoDispose
    .family<List<CatalogProduct>, String>((ref, businessId) async {
      final repository = ref.watch(catalogRepositoryProvider);

      return repository.getProducts(businessId: businessId);
    });

final catalogProductsRealtimeProvider = StreamProvider.autoDispose
    .family<List<CatalogProduct>, String>((ref, businessId) async* {
      final repository = ref.watch(catalogRepositoryProvider);

      while (true) {
        yield await repository.getProducts(businessId: businessId);

        await Future<void>.delayed(const Duration(seconds: 30));
      }
    });

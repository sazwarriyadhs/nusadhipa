import 'package:dio/dio.dart';

import 'models/catalog_product.dart';

class CatalogRepository {
  final Dio dio;

  CatalogRepository(this.dio);

  Future<List<CatalogProduct>> getProducts({required String businessId}) async {
    final response = await dio.get(
      '/api/v1/catalog/products',
      queryParameters: {'business_id': businessId},
    );

    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid catalog response');
    }

    final data = body['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(CatalogProduct.fromJson)
        .toList();
  }

  Future<CatalogProduct> createProduct({
    required String businessId,
    required String sku,
    required String name,
    String description = '',
    String? categoryId,
    String productType = 'product',
    String unit = 'pcs',
    double price = 0,
    double costPrice = 0,
    bool trackInventory = false,
  }) async {
    final response = await dio.post(
      '/api/v1/catalog/products',
      queryParameters: {'business_id': businessId},
      data: {
        'sku': sku,
        'name': name,
        'description': description,
        'category_id': categoryId,
        'product_type': productType,
        'unit': unit,
        'price': price,
        'cost_price': costPrice,
        'track_inventory': trackInventory,
      },
    );

    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid create catalog response');
    }

    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception(
        body['error']?.toString() ?? 'Service could not be created',
      );
    }

    return CatalogProduct.fromJson(data);
  }

  Future<CatalogProduct> updateProduct({
    required String businessId,
    required String productId,
    required String sku,
    required String name,
    String description = '',
    String? categoryId,
    String productType = 'product',
    String unit = 'pcs',
    double price = 0,
    double costPrice = 0,
    bool trackInventory = false,
  }) async {
    final response = await dio.put(
      '/api/v1/catalog/products/$productId',
      queryParameters: {'business_id': businessId},
      data: {
        'sku': sku,
        'name': name,
        'description': description,
        'category_id': categoryId,
        'product_type': productType,
        'unit': unit,
        'price': price,
        'cost_price': costPrice,
        'track_inventory': trackInventory,
      },
    );

    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid update catalog response');
    }

    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception(
        body['error']?.toString() ?? 'Service could not be updated',
      );
    }

    return CatalogProduct.fromJson(data);
  }

  Future<void> deleteProduct({
    required String businessId,
    required String productId,
  }) async {
    final response = await dio.delete(
      '/api/v1/catalog/products/$productId',
      queryParameters: {'business_id': businessId},
    );

    final body = response.data;

    if (body is Map<String, dynamic> && body['success'] == false) {
      throw Exception(
        body['error']?.toString() ?? 'Service could not be deleted',
      );
    }
  }
}

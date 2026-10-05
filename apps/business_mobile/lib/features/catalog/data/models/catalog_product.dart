class CatalogProduct {
  final String id;
  final String businessId;
  final String? categoryId;
  final String sku;
  final String name;
  final String description;
  final String productType;
  final String unit;
  final double price;
  final double costPrice;
  final bool trackInventory;
  final String status;

  const CatalogProduct({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.sku,
    required this.name,
    required this.description,
    required this.productType,
    required this.unit,
    required this.price,
    required this.costPrice,
    required this.trackInventory,
    required this.status,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      productType: json['product_type']?.toString() ?? 'product',
      unit: json['unit']?.toString() ?? 'pcs',
      price: _toDouble(json['price']),
      costPrice: _toDouble(json['cost_price']),
      trackInventory: json['track_inventory'] == true,
      status: json['status']?.toString() ?? 'active',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

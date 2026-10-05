import '../../../core/network/api_client.dart';

class LegalRepository {
  final ApiClient client;

  LegalRepository(this.client);

  Future<Map<String, dynamic>> getBusinessLegalStatus(String businessId) async {
    final response = await client.dio.get(
      '/api/v1/legal/businesses/$businessId/status',
    );

    final body = Map<String, dynamic>.from(response.data as Map);

    dynamic data = body['data'];

    if (data is Map && data['data'] is Map) {
      data = data['data'];
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid legal status response');
  }
}

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';

class BusinessRepository {
  final ApiClient client;

  BusinessRepository(this.client);

  Future<Map<String, dynamic>> getBusiness(String businessId) async {
    final response = await client.dio.get('/api/v1/businesses/$businessId');

    final body = Map<String, dynamic>.from(response.data as Map);

    final data = body['data'];

    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid business response');
  }

  Future<String> uploadMedia({
    required String businessId,
    required XFile file,
    required String type,
  }) async {
    if (type != 'logo' && type != 'header') {
      throw ArgumentError('type must be logo or header');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await client.dio.post(
      '/api/v1/businesses/$businessId/media?type=$type',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = Map<String, dynamic>.from(response.data as Map);
    final data = body['data'];

    if (data is Map && data['data'] is Map) {
      final nested = Map<String, dynamic>.from(data['data'] as Map);
      final url = nested['url'];

      if (url is String && url.isNotEmpty) {
        return url;
      }
    }

    if (data is Map) {
      final url = data['url'];

      if (url is String && url.isNotEmpty) {
        return url;
      }
    }

    throw Exception('Invalid media upload response');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String businessId,
    required String name,
    required String businessType,
    required String activity,
    required String kbliCode,
    required String kbliName,
    required String phone,
    required String email,
    required String address,
    required String shortName,
    required String tagline,
    required String description,
    required String whatsapp,
    required String website,
    required String logoUrl,
    required String coverImageUrl,
    required String brandColor,
  }) async {
    final response = await client.dio.put(
      '/api/v1/businesses/$businessId',
      data: {
        'name': name,
        'business_type': businessType,
        'activity': activity,
        'kbli_code': kbliCode,
        'kbli_name': kbliName,
        'phone': phone,
        'email': email,
        'address': address,
        'short_name': shortName,
        'tagline': tagline,
        'description': description,
        'whatsapp': whatsapp,
        'website': website,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'brand_color': brandColor,
      },
    );

    final body = Map<String, dynamic>.from(response.data as Map);

    final data = body['data'];

    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid business update response');
  }
}

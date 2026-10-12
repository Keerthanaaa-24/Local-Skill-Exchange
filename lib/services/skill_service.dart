import 'package:flutter/foundation.dart';
import 'api_client.dart';

class SkillService {
  Future<List<Map<String, dynamic>>> getSkills() async {
    try {
      final response = await apiClient.dio.get('/skills/');
      final dynamic raw = response.data;
      final List list = (raw is Map && raw.containsKey('data')) ? raw['data'] : (raw is List ? raw : []);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Get skills error: $e');
      return [];
    }
  }

  Future<bool> offerSkill(int skillId) async {
    try {
      final response = await apiClient.dio.post('/skills/offer/$skillId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Offer skill error: $e');
      return false;
    }
  }

  Future<bool> wantSkill(int skillId) async {
    try {
      final response = await apiClient.dio.post('/skills/want/$skillId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Want skill error: $e');
      return false;
    }
  }
}

final skillService = SkillService();

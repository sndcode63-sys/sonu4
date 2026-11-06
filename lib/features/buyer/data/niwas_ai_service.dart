import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/niwas_ai_models.dart';

class NiwasAiService {
  NiwasAiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  static final NiwasAiService instance = NiwasAiService._internal();
  static const String baseUrl = 'http://187.127.140.51:8585';

  late final Dio _dio;

  /// POST /v1/chat
  /// Sends a message and receives the assistant's reply along with property cards and sources
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? sessionId,
    String? propertyId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message.trim(),
      };
      if (sessionId != null && sessionId.trim().isNotEmpty) {
        payload['session_id'] = sessionId.trim();
      }
      if (propertyId != null && propertyId.trim().isNotEmpty) {
        payload['property_id'] = propertyId.trim();
      }

      final response = await _dio.post(
        '/v1/chat',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final replyText = data['reply']?.toString() ?? 'I could not find an answer at this moment.';
        final returnedSessionId = data['session_id']?.toString() ?? sessionId;

        List<AiPropertyCard> propertyCards = [];
        if (data['properties'] is List) {
          propertyCards = (data['properties'] as List)
              .whereType<Map<String, dynamic>>()
              .map((p) => AiPropertyCard.fromJson(p))
              .toList();
        }

        List<AiSource> sources = [];
        if (data['sources'] is List) {
          sources = (data['sources'] as List)
              .whereType<Map<String, dynamic>>()
              .map((s) => AiSource.fromJson(s))
              .toList();
        }

        return {
          'success': true,
          'session_id': returnedSessionId,
          'reply': replyText,
          'properties': propertyCards,
          'sources': sources,
          'model': data['model']?.toString(),
        };
      }

      throw Exception('Unexpected server response format');
    } on DioException catch (e) {
      debugPrint('NiwasAiService DioException: ${e.message} - ${e.response?.data}');
      String errorMsg = 'Could not reach Niwas AI. Please check your connection.';
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        errorMsg = e.response?.data['detail'].toString() ?? errorMsg;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Niwas AI is taking longer than usual. Please try again.';
      }
      return {
        'success': false,
        'error': errorMsg,
        'session_id': sessionId,
      };
    } catch (e) {
      debugPrint('NiwasAiService Error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
        'session_id': sessionId,
      };
    }
  }

  /// GET /v1/sessions/{session_id}/history
  Future<List<Map<String, dynamic>>> getSessionHistory(String sessionId) async {
    try {
      final response = await _dio.get('/v1/sessions/$sessionId/history');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('NiwasAiService getSessionHistory error: $e');
      return [];
    }
  }

  /// DELETE /v1/sessions/{session_id}
  Future<bool> deleteSession(String sessionId) async {
    try {
      await _dio.delete('/v1/sessions/$sessionId');
      return true;
    } catch (e) {
      debugPrint('NiwasAiService deleteSession error: $e');
      return false;
    }
  }

  /// GET /v1/properties/{property_id}/snapshot
  Future<PropertySnapshotData?> getPropertySnapshot(String propertyId) async {
    try {
      final response = await _dio.get('/v1/properties/$propertyId/snapshot');
      if (response.data is Map<String, dynamic>) {
        return PropertySnapshotData.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('NiwasAiService getPropertySnapshot error: $e');
      return null;
    }
  }

  /// GET /health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.data != null && response.data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;

  static const String _tag = '[ApiClient]';

  // Uses Tailscale explicit routed IP for remote Python connectivity
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://100.122.139.123:8080',
            // connectTimeout MUST be set — null/unset causes Dio to treat it as 0ms
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 5),
          ),
        ) {
    _dio.interceptors.add(_buildLoggingInterceptor());
  }

  Interceptor _buildLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('$_tag ➡️  REQUEST [${options.method}] ${options.uri}');
        debugPrint('$_tag    connectTimeout : ${options.connectTimeout}');
        debugPrint('$_tag    sendTimeout    : ${options.sendTimeout}');
        debugPrint('$_tag    receiveTimeout : ${options.receiveTimeout}');
        if (options.data is FormData) {
          final fd = options.data as FormData;
          debugPrint('$_tag    FormData fields: ${fd.fields.map((f) => '${f.key}=${f.value}').join(', ')}');
          debugPrint('$_tag    FormData files : ${fd.files.map((f) => '${f.key}=${f.value.filename}').join(', ')}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('$_tag ✅  RESPONSE [${response.statusCode}] ${response.requestOptions.uri}');
        debugPrint('$_tag    Body: ${response.data}');
        handler.next(response);
      },
      onError: (DioException err, handler) {
        debugPrint('$_tag ❌  ERROR [${err.type.name}] ${err.requestOptions.uri}');
        debugPrint('$_tag    Message : ${err.message}');
        debugPrint('$_tag    Response: ${err.response?.statusCode} — ${err.response?.data}');
        if (err.error is SocketException) {
          final se = err.error as SocketException;
          debugPrint('$_tag    SocketException: ${se.message} (errno=${se.osError?.errorCode})');
          debugPrint('$_tag    Host: ${se.address?.address}  Port: ${se.port}');
        }
        handler.next(err);
      },
    );
  }

  Future<Map<String, dynamic>?> processAudio(String filePath) async {
    debugPrint('$_tag processAudio() — file: $filePath');

    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('$_tag ⚠️  File does not exist at path: $filePath');
      return null;
    }
    final fileSize = file.lengthSync();
    debugPrint('$_tag    File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        'Patient': 'Rahul',     // Mock default speaker
        'Doctor': 'Dr. Smith',  // Mock default speaker
      });

      debugPrint('$_tag Posting to /upload-audio …');
      final response = await _dio.post('/upload-audio', data: formData);

      debugPrint('$_tag Server responded: HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('$_tag Pipeline result keys: ${(response.data['data'] as Map?)?.keys.toList()}');
        return response.data['data'] as Map<String, dynamic>?;
      }
      debugPrint('$_tag Unexpected status: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('$_tag ❌ DioException: ${e.type.name} — ${e.message}');
      return null;
    } catch (e, st) {
      debugPrint('$_tag ❌ Unexpected error: $e');
      debugPrint('$_tag    StackTrace: $st');
      return null;
    }
  }

  Future<String> askAssistant(String patientName, String doctorName, String userQuery) async {
    debugPrint('$_tag askAssistant() — Query: $userQuery');
    try {
      // 1. Combine names to match backend "user_id" format: Rahul_Dr_Smith
      String userId = "${patientName}_$doctorName".replaceAll(" ", "_");

      // 2. Prepare Form Data
      final formData = FormData.fromMap({
        '''user_id''': userId,
        '''query''': userQuery,
      });

      // 3. Send Request
      final response = await _dio.post('/chat-assistant', data: formData);

      if (response.statusCode == 200) {
        return response.data['answer']?.toString() ?? 'Error: Empty answer received';
      } else {
        return "Error: Server returned ${response.statusCode}";
      }
    } on DioException catch (e) {
      debugPrint('$_tag ❌ DioException in askAssistant: ${e.message}');
      return "Connection Failed: ${e.type.name}";
    } catch (e) {
      debugPrint('$_tag ❌ Error in askAssistant: $e');
      return "Error: $e";
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ---------------------------------------------------------------------------
// Memory Layer Client — Secure Semantic Memory Backend
// Base: http://100.120.18.48:8000
// Endpoints: /semantic-search, /user-timeline/{id}, /update-record/{id}
// ---------------------------------------------------------------------------

class MemoryLayerClient {
  final Dio _dio;
  static const String _tag = '[MemoryLayer]';

  MemoryLayerClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://100.120.18.48:8000',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('$_tag ➡️  ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('$_tag ✅  ${response.statusCode} ${response.requestOptions.path}');
        debugPrint('$_tag    Body: ${response.data}');
        handler.next(response);
      },
      onError: (err, handler) {
        debugPrint('$_tag ❌  ${err.type.name}: ${err.message}');
        handler.next(err);
      },
    ));
  }

  /// GET / — Check if the Memory Layer is online
  Future<bool> checkStatus() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200 &&
          (response.data['status'] as String?)?.toLowerCase() == 'online';
    } catch (_) {
      return false;
    }
  }

  /// GET /semantic-search?query=...&user_id=...
  /// Returns a list of matching records
  Future<List<Map<String, dynamic>>> semanticSearch(
    String query, {
    String? userId,
  }) async {
    try {
      final params = <String, dynamic>{'query': query};
      if (userId != null && userId.isNotEmpty) params['user_id'] = userId;

      final response = await _dio.get('/semantic-search', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        // Some backends wrap in a results key
        if (data is Map && data['results'] is List) {
          return (data['results'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('$_tag semanticSearch error: ${e.message}');
      return [];
    }
  }

  /// GET /user-timeline/{user_id}
  /// Returns chronological list of visits/interactions
  Future<List<Map<String, dynamic>>> getUserTimeline(String userId) async {
    try {
      final response = await _dio.get('/user-timeline/$userId');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map && data['timeline'] is List) {
          return (data['timeline'] as List).cast<Map<String, dynamic>>();
        }
        if (data is Map && data['history'] is List) {
          return (data['history'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('$_tag getUserTimeline error: ${e.message}');
      return [];
    }
  }

  /// PUT /update-record/{db_id}
  /// Human correction — submits corrected transcript + extraction
  Future<bool> updateRecord(
    String dbId, {
    required String correctedTranscript,
    required Map<String, dynamic> correctedExtraction,
  }) async {
    try {
      final response = await _dio.put(
        '/update-record/$dbId',
        data: {
          'corrected_transcript': correctedTranscript,
          'corrected_extraction': correctedExtraction,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('$_tag updateRecord error: ${e.message}');
      return false;
    }
  }
}

final memoryLayerClientProvider = Provider<MemoryLayerClient>((ref) {
  return MemoryLayerClient();
});

/// Convenience provider: polls the Memory Layer status once on first read
final memoryStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(memoryLayerClientProvider).checkStatus();
});

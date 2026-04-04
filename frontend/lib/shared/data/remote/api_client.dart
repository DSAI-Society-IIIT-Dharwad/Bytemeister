import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl:
            'https://api.example.com', // Placeholder - should be configured via env
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response> uploadAudio(String filePath, String workflowType) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath, filename: fileName),
      'workflow_type': workflowType,
    });

    return await _dio.post(
      '/process-audio',
      data: formData,
      onSendProgress: (count, total) {
        // Progress tracking if needed
      },
    );
  }
}

final apiClientProvider = ApiClient();

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  static const String defaultRemoteStagingUrl = 'https://supports-incidents-jail-admissions.trycloudflare.com/api/v1';

  static Future<String> getBaseUrl() async {
    final custom = await SecureStorageService.getCustomApiUrl();
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return defaultRemoteStagingUrl;
  }

  static Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'MeetMind-Flutter-Mobile/6.0.0',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final base = await getBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please verify your network.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final base = await getBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please verify your network.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final base = await getBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please verify your network.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final base = await getBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please verify your network.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  static Future<dynamic> uploadAudioFile({
    required String filePath,
    required String title,
    String? category,
    String? meetingDate,
    String? idempotencyKey,
  }) async {
    final base = await getBaseUrl();
    final url = Uri.parse('$base/meetings/upload');
    final headers = await _getHeaders(isJson: false);
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw ApiException('Audio file not found on device: $filePath');
    }

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      request.fields['title'] = title;
      if (category != null) request.fields['category'] = category;
      if (meetingDate != null) request.fields['meeting_date'] = meetingDate;

      final multipartFile = await http.MultipartFile.fromPath('audio', filePath);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(minutes: 3));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Offline: Unable to upload audio. Stored in Offline Vault.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload request failed: $e');
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final detail = body is Map ? (body['detail'] ?? body['message'] ?? response.body) : response.body;

    switch (response.statusCode) {
      case 401:
        throw ApiException('Unauthorized: Session expired or invalid credentials.', statusCode: 401, details: detail);
      case 402:
        throw ApiException('Usage Limit: Account usage credits needed (status code: 402).', statusCode: 402, details: detail);
      case 403:
        throw ApiException('Forbidden: Server-side security blocked this action.', statusCode: 403, details: detail);
      case 404:
        throw ApiException('Resource not found: $detail', statusCode: 404, details: detail);
      case 429:
        throw ApiException('Rate limit exceeded: Please wait before retrying.', statusCode: 429, details: detail);
      default:
        throw ApiException('Server error ($response.statusCode): $detail', statusCode: response.statusCode, details: detail);
    }
  }
}

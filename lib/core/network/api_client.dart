import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'api_endpoints.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final http.Client _client = http.Client();
  static const int timeoutSeconds = 15;

  // Generic request executor with error handling
  Future<http.Response> _executeRequest(Future<http.Response> Function() requestFunc) async {
    try {
      final response = await requestFunc().timeout(const Duration(seconds: timeoutSeconds));
      return response;
    } on TimeoutException {
      throw ApiException(message: 'Koneksi terputus. Waktu tunggu habis (timeout).', statusCode: 408);
    } on SocketException {
      throw ApiException(message: 'Tidak ada koneksi internet atau server mati.', statusCode: 503);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan jaringan: $e', statusCode: 500);
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = await _buildHeaders();
    debugPrint('[ApiClient] GET $uri');
    debugPrint('[ApiClient] Headers: ${headers.keys.map((k) => '$k: ${k == 'Authorization' || k == 'X-Custom-Token' ? '${headers[k]!.substring(0, headers[k]!.length > 30 ? 30 : headers[k]!.length)}...' : headers[k]}').join(', ')}');
    
    final response = await _executeRequest(() => _client.get(uri, headers: headers));
    return _handleResponse(response);
  }

  // POST request (JSON)
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _executeRequest(() => _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ));
    return _handleResponse(response);
  }

  // POST request with form-data (for file uploads)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final token = await TokenStorage.getToken();
    final customToken = await TokenStorage.getCustomToken();

    final request = http.MultipartRequest('POST', uri);

    // Add auth headers - same as _buildHeaders
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (customToken != null) {
      request.headers['X-Api-Token'] = customToken;
    }
    request.headers['Accept'] = 'application/json';

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file
    if (fileField != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    // executeRequest wrapper for StreamedResponse
    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: timeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Koneksi terputus. Waktu unggah habis (timeout).', statusCode: 408);
    } on SocketException {
      throw ApiException(message: 'Tidak ada koneksi internet saat mengunggah.', statusCode: 503);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan unggah: $e', statusCode: 500);
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _executeRequest(() => _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ));
    return _handleResponse(response);
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _executeRequest(() => _client.delete(uri, headers: headers));
    return _handleResponse(response);
  }

  // Build headers with auth token
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final sanctumToken = await TokenStorage.getToken();
    final customToken = await TokenStorage.getCustomToken();
    
    // auth:sanctum middleware expects: Authorization: Bearer {sanctum_token}
    if (sanctumToken != null) {
      headers['Authorization'] = 'Bearer $sanctumToken';
    }
    
    // custom.token middleware expects: X-Api-Token: {custom_token}
    if (customToken != null) {
      headers['X-Api-Token'] = customToken;
    }

    debugPrint('[ApiClient] Headers built - sanctumToken: ${sanctumToken != null ? "present(${sanctumToken.length} chars)" : "MISSING"}, customToken(X-Api-Token): ${customToken != null ? "present(${customToken.length} chars)" : "MISSING"}');

    return headers;
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    // 401 Unauthorized handling (token expired/invalid)
    if (response.statusCode == 401) {
       TokenStorage.clearAll(); // Clean local tokens
       
       // Redirect to login screen if context is available
       if (navigatorKey.currentState != null) {
         Future.microtask(() {
           navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
         });
       }
       
       throw ApiException(
         message: 'Sesi Anda telah berakhir (401). Silakan login kembali.', 
         statusCode: 401
       );
    }

    late Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // If server returns HTML instead of JSON (e.g. 500 error page or routing error)
      throw ApiException(message: 'Server mengembalikan respons yang tidak terduga', statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract error message
    final message = body['message'] ?? 'Terjadi kesalahan pada server';
    debugPrint('[ApiClient] API Error ${response.statusCode}: $message');
    debugPrint('[ApiClient] Full response: ${response.body}');
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}

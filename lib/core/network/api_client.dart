import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final http.Client _client = http.Client();

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = await _buildHeaders();
    print('[ApiClient] GET $uri');
    print('[ApiClient] Headers: ${headers.keys.map((k) => '$k: ${k == 'Authorization' || k == 'X-Custom-Token' ? '${headers[k]!.substring(0, headers[k]!.length > 30 ? 30 : headers[k]!.length)}...' : headers[k]}').join(', ')}');
    final response = await _client.get(uri, headers: headers);

    return _handleResponse(response);
  }

  // POST request (JSON)
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _buildHeaders();

    final response = await _client.delete(uri, headers: headers);

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
    // (see ValidateCustomToken.php: $request->header('X-Api-Token'))
    if (customToken != null) {
      headers['X-Api-Token'] = customToken;
    }

    print('[ApiClient] Headers built - sanctumToken: ${sanctumToken != null ? "present(${sanctumToken.length} chars)" : "MISSING"}, customToken(X-Api-Token): ${customToken != null ? "present(${customToken.length} chars)" : "MISSING"}');

    return headers;
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract error message
    final message = body['message'] ?? 'Terjadi kesalahan pada server';
    print('[ApiClient] API Error ${response.statusCode}: $message');
    print('[ApiClient] Full response: ${response.body}');
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

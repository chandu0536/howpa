import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import 'api_logger.dart';
import 'api_response.dart';

class ApiClient {
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    String cleanPath;
    if (path.startsWith('http')) {
      cleanPath = path;
    } else {
      final base = ApiEndpoints.baseUrl.endsWith('/')
          ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
          : ApiEndpoints.baseUrl;
      final endpoint = path.startsWith('/') ? path : '/$path';
      cleanPath = '$base$endpoint';
    }
    return Uri.parse(cleanPath).replace(
      queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: 'GET',
      url: uri,
      headers: headers,
      queryParameters: queryParameters,
    );

    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: 'GET',
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: 'GET',
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: 'GET',
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: 'POST',
      url: uri,
      headers: headers,
      body: body,
    );

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: 'POST',
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: 'POST',
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: 'POST',
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: 'PUT',
      url: uri,
      headers: headers,
      body: body,
    );

    try {
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: 'PUT',
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: 'PUT',
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: 'PUT',
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: 'PATCH',
      url: uri,
      headers: headers,
      body: body,
    );

    try {
      final response = await _httpClient
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: 'PATCH',
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: 'PATCH',
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: 'PATCH',
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: 'DELETE',
      url: uri,
      headers: headers,
    );

    try {
      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: 'DELETE',
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: 'DELETE',
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: 'DELETE',
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  /// Sends a multipart form-data request (POST or PUT) with text fields and files
  Future<dynamic> multipartRequest(
    String method,
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    final uri = _buildUri(path);
    final stopwatch = Stopwatch()..start();

    final request = http.MultipartRequest(method, uri);

    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (final entry in files.entries) {
        if (entry.value.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              entry.value.path,
            ),
          );
        }
      }
    }

    ApiLogger.logRequest(
      method: method,
      url: uri,
      headers: request.headers,
      body: {'fields': fields, 'files': files?.keys.toList()},
    );

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      return _handleResponse(
        response: response,
        method: method,
        url: uri,
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        url: uri,
        error: 'No internet connection',
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      throw ApiException('No internet connection. Please check your network.');
    } catch (e, stack) {
      stopwatch.stop();
      if (e is! ApiException) {
        ApiLogger.logError(
          method: method,
          url: uri,
          error: e,
          duration: stopwatch.elapsed,
          stackTrace: stack,
        );
      }
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> multipartPost(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) =>
      multipartRequest('POST', path, fields: fields, files: files);

  Future<dynamic> multipartPut(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) =>
      multipartRequest('PUT', path, fields: fields, files: files);

  dynamic _handleResponse({
    required http.Response response,
    required String method,
    required Uri url,
    required Duration duration,
  }) {
    dynamic parsedBody;
    if (response.body.isNotEmpty) {
      try {
        parsedBody = jsonDecode(response.body);
      } catch (_) {
        parsedBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      ApiLogger.logResponse(
        method: method,
        url: url,
        statusCode: response.statusCode,
        body: parsedBody,
        duration: duration,
      );
      return parsedBody;
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      if (parsedBody is Map && parsedBody['message'] != null) {
        errorMessage = parsedBody['message'].toString();
      }

      ApiLogger.logError(
        method: method,
        url: url,
        error: errorMessage,
        statusCode: response.statusCode,
        responseBody: parsedBody,
        duration: duration,
      );

      throw ApiException(errorMessage, response.statusCode);
    }
  }
}


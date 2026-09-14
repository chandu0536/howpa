import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';
import 'api_logger.dart';
import 'token_storage.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 15);

  /// Standard Headers Builder
  Future<Map<String, String>> _getHeaders({
    bool isJson = true,
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Process HTTP Response and parse JSON
  dynamic _processResponse(http.Response response, {required String method, required Uri uri, required Duration duration}) {
    ApiLogger.logResponse(
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      responseBody: response.body,
      duration: duration,
    );

    dynamic responseBody;
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(
        message: _extractErrorMessage(responseBody) ?? 'Unauthorized session.',
      );
    } else if (response.statusCode >= 500) {
      throw ServerException(
        message: _extractErrorMessage(responseBody) ?? 'Server error occurred.',
      );
    } else {
      throw ApiException(
        message: _extractErrorMessage(responseBody) ?? 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
        data: responseBody,
      );
    }
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      return body['message'] as String? ??
          body['error'] as String? ??
          body['msg'] as String?;
    }
    return null;
  }

  /// GET Request
  Future<dynamic> get(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      ApiLogger.logRequest(method: 'GET', uri: uri, headers: headers);

      final response = await _client.get(uri, headers: headers).timeout(_timeout);
      stopwatch.stop();
      return _processResponse(response, method: 'GET', uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'GET', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'GET', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'GET', uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// POST Request
  Future<dynamic> post(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final encodedBody = body is String ? body : (body != null ? jsonEncode(body) : null);
      ApiLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: body);

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);
      stopwatch.stop();
      return _processResponse(response, method: 'POST', uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'POST', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'POST', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'POST', uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// PUT Request
  Future<dynamic> put(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final encodedBody = body is String ? body : (body != null ? jsonEncode(body) : null);
      ApiLogger.logRequest(method: 'PUT', uri: uri, headers: headers, body: body);

      final response = await _client
          .put(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);
      stopwatch.stop();
      return _processResponse(response, method: 'PUT', uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PUT', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PUT', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PUT', uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// PATCH Request
  Future<dynamic> patch(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse(url);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final encodedBody = body is String ? body : (body != null ? jsonEncode(body) : null);
      ApiLogger.logRequest(method: 'PATCH', uri: uri, headers: headers, body: body);

      final response = await _client
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);
      stopwatch.stop();
      return _processResponse(response, method: 'PATCH', uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PATCH', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PATCH', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PATCH', uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// DELETE Request
  Future<dynamic> delete(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      ApiLogger.logRequest(method: 'DELETE', uri: uri, headers: headers);

      final response = await _client.delete(uri, headers: headers).timeout(_timeout);
      stopwatch.stop();
      return _processResponse(response, method: 'DELETE', uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'DELETE', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'DELETE', uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'DELETE', uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Multipart Form Data Upload (e.g. KYC Documents / Profile with Image)
  Future<dynamic> multipartRequest({
    required String method,
    required String url,
    Map<String, String>? fields,
    Map<String, File>? files,
    bool requiresAuth = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse(url);

    try {
      final request = http.MultipartRequest(method, uri);

      if (requiresAuth) {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        for (final entry in files.entries) {
          if (entry.value.existsSync()) {
            final multipartFile = await http.MultipartFile.fromPath(
              entry.key,
              entry.value.path,
            );
            request.files.add(multipartFile);
          }
        }
      }

      ApiLogger.logRequest(
        method: method,
        uri: uri,
        headers: request.headers,
        fields: fields,
        fileKeys: files?.keys.toList(),
      );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      return _processResponse(response, method: method, uri: uri, duration: stopwatch.elapsed);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: method, uri: uri, error: e, duration: stopwatch.elapsed);
      throw const NetworkException();
    } on TimeoutException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: method, uri: uri, error: e, duration: stopwatch.elapsed);
      throw const ApiException(message: 'Upload timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: method, uri: uri, error: e, duration: stopwatch.elapsed);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}

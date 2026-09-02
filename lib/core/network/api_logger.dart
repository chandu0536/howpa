import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  ApiLogger._();

  static const String _lineSeparator = '────────────────────────────────────────────────────────────────────────';

  /// Log outgoing HTTP request
  static void logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌── 🌐 [HTTP REQUEST] $method: $url');
    buffer.writeln('│ 🕒 Time: ${DateTime.now().toIso8601String()}');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      buffer.writeln('│ 🔍 Query Parameters: ${_formatJson(queryParameters)}');
    }

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('│ 📋 Headers: ${_formatJson(headers)}');
    }

    if (body != null) {
      buffer.writeln('│ 📦 Body:');
      buffer.writeln(_indentLines(_formatJson(body)));
    }

    buffer.writeln('└${_lineSeparator.substring(0, 60)}');
    _printLog(buffer.toString());
  }

  /// Log successful HTTP response
  static void logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required dynamic body,
    Map<String, String>? headers,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final durationText = duration != null ? ' (took ${duration.inMilliseconds}ms)' : '';
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '⚠️';

    final buffer = StringBuffer();
    buffer.writeln('\n┌── $emoji [HTTP RESPONSE] [$statusCode] $method: $url$durationText');
    buffer.writeln('│ 🕒 Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('│ 📊 Status Code: $statusCode');

    if (body != null) {
      buffer.writeln('│ 📄 Response Body:');
      buffer.writeln(_indentLines(_formatJson(body)));
    } else {
      buffer.writeln('│ 📄 Response Body: <empty>');
    }

    buffer.writeln('└${_lineSeparator.substring(0, 60)}');
    _printLog(buffer.toString());
  }

  /// Log HTTP error or exception
  static void logError({
    required String method,
    required Uri url,
    required dynamic error,
    int? statusCode,
    dynamic responseBody,
    Duration? duration,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final durationText = duration != null ? ' (took ${duration.inMilliseconds}ms)' : '';
    final statusText = statusCode != null ? ' [$statusCode]' : '';

    final buffer = StringBuffer();
    buffer.writeln('\n┌── ❌ [HTTP ERROR]$statusText $method: $url$durationText');
    buffer.writeln('│ 🕒 Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('│ ⚠️ Error: $error');

    if (responseBody != null) {
      buffer.writeln('│ 📄 Response Body:');
      buffer.writeln(_indentLines(_formatJson(responseBody)));
    }

    if (stackTrace != null) {
      buffer.writeln('│ 📍 StackTrace:');
      buffer.writeln(_indentLines(stackTrace.toString().split('\n').take(4).join('\n')));
    }

    buffer.writeln('└${_lineSeparator.substring(0, 60)}');
    _printLog(buffer.toString());
  }

  /// Format dynamic objects or JSON strings into pretty-printed JSON
  static String _formatJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } else if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {}
    return data.toString();
  }

  /// Indent multiline strings with vertical border character
  static String _indentLines(String text) {
    return text.split('\n').map((line) => '│   $line').join('\n');
  }

  /// Print log cleanly in chunks so debug console won't truncate large JSON bodies
  static void _printLog(String message) {
    // Avoid truncation by printing line by line
    final lines = message.split('\n');
    for (final line in lines) {
      debugPrint(line);
    }
  }
}

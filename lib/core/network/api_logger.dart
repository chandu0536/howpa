import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Professional Pretty API Logger / Interceptor for Debug Console
class ApiLogger {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// Log outgoing API HTTP Request
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? fields,
    List<String>? fileKeys,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌── 🌐 [API REQUEST] ──────────────────────────────────────────────────────────');
    buffer.writeln('│ ➡️  Method: $method');
    buffer.writeln('│ 🔗  URL:    ${uri.toString()}');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('│ 📋  Headers:');
      headers.forEach((k, v) {
        if (k.toLowerCase() == 'authorization' && v.startsWith('Bearer ')) {
          buffer.writeln('│     $k: ${v.substring(0, 15)}... (Token attached)');
        } else {
          buffer.writeln('│     $k: $v');
        }
      });
    }

    if (body != null) {
      buffer.writeln('│ 📦  Request Body:');
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          final formatted = _prettyEncoder.convert(decoded);
          for (final line in formatted.split('\n')) {
            buffer.writeln('│     $line');
          }
        } else {
          final formatted = _prettyEncoder.convert(body);
          for (final line in formatted.split('\n')) {
            buffer.writeln('│     $line');
          }
        }
      } catch (_) {
        buffer.writeln('│     $body');
      }
    }

    if (fields != null && fields.isNotEmpty) {
      buffer.writeln('│ 📝  Form Fields:');
      fields.forEach((k, v) => buffer.writeln('│     $k: $v'));
    }

    if (fileKeys != null && fileKeys.isNotEmpty) {
      buffer.writeln('│ 📁  Files: ${fileKeys.join(', ')}');
    }

    buffer.writeln('└─────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log incoming API HTTP Response
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required String responseBody,
    required Duration duration,
  }) {
    if (!kDebugMode) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final statusEmoji = isSuccess
        ? '🟢'
        : (statusCode == 401
            ? '🔒'
            : (statusCode >= 400 && statusCode < 500 ? '🟡' : '🔴'));

    final buffer = StringBuffer();
    buffer.writeln('\n┌── $statusEmoji [API RESPONSE] ─────────────────────────────────────────────────────────');
    buffer.writeln('│ ⬅️  Method:   $method');
    buffer.writeln('│ 🔗  URL:      ${uri.toString()}');
    buffer.writeln('│ 📊  Status:   $statusEmoji $statusCode');
    buffer.writeln('│ ⏱️  Duration: ${duration.inMilliseconds} ms');
    buffer.writeln('│ 📦  Response Body:');

    if (responseBody.isEmpty) {
      buffer.writeln('│     <EMPTY BODY>');
    } else {
      try {
        final decoded = jsonDecode(responseBody);
        final formatted = _prettyEncoder.convert(decoded);
        for (final line in formatted.split('\n')) {
          buffer.writeln('│     $line');
        }
      } catch (_) {
        for (final line in responseBody.split('\n')) {
          buffer.writeln('│     $line');
        }
      }
    }

    buffer.writeln('└─────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log API Error or Exception
  static void logError({
    required String method,
    required Uri uri,
    required dynamic error,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌── ❌ [API ERROR] ────────────────────────────────────────────────────────────');
    buffer.writeln('│ ⬅️  Method:   $method');
    buffer.writeln('│ 🔗  URL:      ${uri.toString()}');
    if (duration != null) {
      buffer.writeln('│ ⏱️  Duration: ${duration.inMilliseconds} ms');
    }
    buffer.writeln('│ ⚠️  Error:    $error');
    buffer.writeln('└─────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }
}

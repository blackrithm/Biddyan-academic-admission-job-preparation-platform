import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';

/// Thin wrapper around `package:http` used by every service in the app.
///
/// Automatically prefixes the configured [AppConstants.apiBaseUrl], encodes
/// JSON bodies, attaches the bearer token when present and normalizes errors
/// into [ApiException].
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  String? authToken;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$_baseUrl$normalized');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query), headers: _headers());
    return _decode(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool json = true,
  }) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(json: json),
      body: json ? jsonEncode(body ?? <String, dynamic>{}) : body,
    );
    return _decode(res);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.put(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers());
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = body is Map<String, dynamic>
        ? (body['error'] as String?) ?? 'Request failed'
        : 'Request failed';
    throw ApiException(message, statusCode: res.statusCode);
  }
}

/// Typed exception carrying the HTTP status for richer UI error messages.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
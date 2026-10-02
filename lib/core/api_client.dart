import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  static const _tokenKey = 'access_token';

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  /// Loads the stored token or creates an anonymous user on first use.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token == null) {
      await _authenticate(prefs);
    }
  }

  Future<void> _authenticate(SharedPreferences prefs) async {
    final json = await _send('POST', '/auth/anonymous', auth: false);
    _token = (json as Map<String, dynamic>)['accessToken'] as String;
    await prefs.setString(_tokenKey, _token!);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, Object body) =>
      _send('POST', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };

    final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 15)),
      );
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(
      _errorMessage(response),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'Sessão inválida ou expirada.';
    }
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = json is Map ? json['detail'] : null;
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {}
    return 'Erro ${response.statusCode} ao falar com o servidor.';
  }
}

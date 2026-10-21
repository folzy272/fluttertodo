import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/todo.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Усі HTTP-запити до JSONPlaceholder знаходяться в одному місці.
class ApiService {
  ApiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  final http.Client _client;
  final bool _ownsClient;

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=UTF-8';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request).timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamed).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('Помилка сервера: HTTP ${response.statusCode}.');
      }
      return response;
    } on TimeoutException {
      throw const ApiException('Час очікування вичерпано. Перевірте інтернет.');
    } on http.ClientException {
      throw const ApiException('Немає з’єднання із сервером. Перевірте інтернет.');
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('Сервер повернув некоректний JSON.');
    }
  }

  Future<List<Todo>> getTodos({int? userId}) async {
    final query = userId == null ? '' : '?userId=$userId';
    final data = _decode(await _request('GET', '/todos$query')) as List<dynamic>;
    return data
        .map((value) => Todo.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppUser>> getUsers() async {
    final data = _decode(await _request('GET', '/users')) as List<dynamic>;
    return data
        .map((value) => AppUser.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTodo(Todo todo) async {
    _decode(await _request('POST', '/todos', body: todo.toJson()));
  }

  Future<void> updateTodo(Todo todo) async {
    _decode(await _request('PUT', '/todos/${todo.id}', body: todo.toJson()));
  }

  Future<void> setCompleted(int id, bool completed) async {
    _decode(await _request(
      'PATCH',
      '/todos/$id',
      body: {'completed': completed},
    ));
  }

  Future<void> deleteTodo(int id) async {
    await _request('DELETE', '/todos/$id');
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

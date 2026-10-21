import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_manager/models/todo.dart';
import 'package:flutter_todo_manager/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET /todos?userId=2 повертає задачі користувача', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/todos');
      expect(request.url.queryParameters['userId'], '2');
      return http.Response(jsonEncode([
        {'id': 1, 'userId': 2, 'title': 'Задача', 'completed': true},
      ]), 200);
    });
    final api = ApiService(client: client);
    final todos = await api.getTodos(userId: 2);
    expect(todos, hasLength(1));
    expect(todos.single.completed, isTrue);
    client.close();
  });

  test('POST, PUT, PATCH, DELETE відправляють правильні методи', () async {
    final methods = <String>[];
    final client = MockClient((request) async {
      methods.add(request.method);
      expect(request.url.host, 'jsonplaceholder.typicode.com');
      if (request.method == 'DELETE') return http.Response('', 200);
      return http.Response('{}', 200);
    });
    final api = ApiService(client: client);
    const todo = Todo(id: 12, userId: 3, title: 'Тест', completed: false);
    await api.createTodo(todo);
    await api.updateTodo(todo);
    await api.setCompleted(todo.id, true);
    await api.deleteTodo(todo.id);
    expect(methods, ['POST', 'PUT', 'PATCH', 'DELETE']);
    client.close();
  });

  test('Серверна помилка повертає ApiException', () async {
    final client = MockClient((request) async => http.Response('error', 503));
    final api = ApiService(client: client);
    expect(api.getTodos(), throwsA(isA<ApiException>()));
    client.close();
  });
}

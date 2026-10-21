import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/todo.dart';
import 'api_service.dart';

/// JSONPlaceholder не зберігає POST/PUT/PATCH/DELETE на сервері.
/// Тому зміни додатково зберігаються на цьому пристрої.
class TodoRepository {
  TodoRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<int, Todo> _changes = {};
  final Set<int> _deleted = {};
  Future<void>? _loadFuture;

  static const _changesKey = 'todo_changes_v1';
  static const _deletedKey = 'todo_deleted_v1';

  Future<void> _ensureLocalData() => _loadFuture ??= _loadLocalData();

  Future<void> _loadLocalData() async {
    final changesJson = await _prefs.getString(_changesKey);
    final deletedJson = await _prefs.getString(_deletedKey);

    if (changesJson != null) {
      final list = jsonDecode(changesJson) as List<dynamic>;
      for (final value in list) {
        final todo = Todo.fromJson(value as Map<String, dynamic>);
        _changes[todo.id] = todo;
      }
    }
    if (deletedJson != null) {
      final list = jsonDecode(deletedJson) as List<dynamic>;
      _deleted.addAll(list.map((value) => (value as num).toInt()));
    }
  }

  Future<void> _saveLocalData() async {
    await _prefs.setString(
      _changesKey,
      jsonEncode(_changes.values.map((todo) => todo.toJson()).toList()),
    );
    await _prefs.setString(_deletedKey, jsonEncode(_deleted.toList()));
  }

  Future<List<AppUser>> getUsers() => _api.getUsers();

  Future<List<Todo>> getTodos({int? userId}) async {
    await _ensureLocalData();
    // userId використовує справжній ендпоїнт GET /todos?userId=...
    final remote = await _api.getTodos(userId: userId);
    final byId = <int, Todo>{
      for (final todo in remote) todo.id: todo,
    };

    for (final entry in _changes.entries) {
      final item = entry.value;
      if (userId == null || item.userId == userId) {
        byId[entry.key] = item;
      } else {
        byId.remove(entry.key);
      }
    }
    for (final id in _deleted) {
      byId.remove(id);
    }
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<Todo> create({
    required String title,
    required int userId,
    bool completed = false,
  }) async {
    await _ensureLocalData();
    final draft = Todo(id: 0, userId: userId, title: title, completed: completed);
    await _api.createTodo(draft); // POST /todos
    // JSONPlaceholder повертає один і той самий ID для нових задач.
    // Використовуємо локальний унікальний ID, щоб задачі не перезаписувались.
    var id = DateTime.now().microsecondsSinceEpoch;
    while (_changes.containsKey(id)) {
      id++;
    }
    final created = Todo(
      id: id,
      userId: userId,
      title: title,
      completed: completed,
    );
    _changes[id] = created;
    await _saveLocalData();
    return created;
  }

  Future<Todo> update(Todo todo) async {
    await _ensureLocalData();
    // Нових локальних задач на сервері немає, тож їх редагуємо локально.
    if (todo.id <= 200) await _api.updateTodo(todo); // PUT /todos/{id}
    _changes[todo.id] = todo;
    await _saveLocalData();
    return todo;
  }

  Future<Todo> toggle(Todo todo, bool completed) async {
    await _ensureLocalData();
    if (todo.id <= 200) {
      await _api.setCompleted(todo.id, completed); // PATCH /todos/{id}
    }
    final changed = todo.copyWith(completed: completed);
    _changes[todo.id] = changed;
    await _saveLocalData();
    return changed;
  }

  Future<void> delete(Todo todo) async {
    await _ensureLocalData();
    if (todo.id <= 200) await _api.deleteTodo(todo.id); // DELETE /todos/{id}
    _changes.remove(todo.id);
    _deleted.add(todo.id);
    await _saveLocalData();
  }

  Future<void> restore(Todo todo) async {
    await _ensureLocalData();
    _deleted.remove(todo.id);
    // Повертає навіть відредаговану версію задачі після Undo.
    _changes[todo.id] = todo;
    await _saveLocalData();
  }

  void dispose() => _api.dispose();
}

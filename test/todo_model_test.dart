import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_manager/models/todo.dart';

void main() {
  test('Todo.fromJson читає JSON', () {
    final todo = Todo.fromJson({
      'id': 5,
      'userId': 2,
      'title': 'Написати тест',
      'completed': false,
    });
    expect(todo.id, 5);
    expect(todo.userId, 2);
    expect(todo.title, 'Написати тест');
    expect(todo.completed, false);
  });

  test('Todo.toJson і copyWith працюють правильно', () {
    const todo = Todo(id: 3, userId: 1, title: 'Задача', completed: false);
    final changed = todo.copyWith(completed: true);
    expect(changed.id, 3);
    expect(changed.completed, isTrue);
    expect(changed.toJson(), {
      'id': 3,
      'userId': 1,
      'title': 'Задача',
      'completed': true,
    });
  });
}

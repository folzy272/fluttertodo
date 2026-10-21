import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.todo,
    required this.userName,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    this.isBusy = false,
  });

  final Todo todo;
  final String userName;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey('todo_${todo.id}'),
        direction: isBusy ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        // Видаляємо через HTTP перед оновленням списку.
        // false запобігає помилці "dismissed widget still in tree".
        confirmDismiss: (_) async {
          await onDelete();
          return false;
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            leading: isBusy
                ? const SizedBox.square(
                    dimension: 28,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Checkbox(
                    value: todo.completed,
                    onChanged: (value) {
                      if (value != null) onToggle(value);
                    },
                  ),
            title: Text(
              todo.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: todo.completed ? TextDecoration.lineThrough : null,
                color: todo.completed ? Theme.of(context).colorScheme.outline : null,
              ),
            ),
            subtitle: Text(
              '${todo.completed ? 'Виконано' : 'Очікує'} · $userName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: isBusy ? null : onTap,
          ),
        ),
      );
}

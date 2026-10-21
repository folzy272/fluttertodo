import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/todo.dart';
import '../models/todo_input.dart';
import '../services/todo_repository.dart';
import 'create_edit_screen.dart';

class DetailResult {
  const DetailResult({this.changed = false, this.deletedTodo});
  final bool changed;
  final Todo? deletedTodo;
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.todo,
    required this.users,
    required this.repository,
  });

  final Todo todo;
  final List<AppUser> users;
  final TodoRepository repository;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Todo _todo;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _todo = widget.todo;
  }

  String get _userName {
    for (final user in widget.users) {
      if (user.id == _todo.userId) return user.name;
    }
    return 'Користувач ${_todo.userId}';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.toggle(_todo, value);
      if (!mounted) return;
      setState(() {
        _todo = updated;
        _changed = true;
      });
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final input = await Navigator.of(context).push<TodoInput>(
      MaterialPageRoute(
        builder: (_) => CreateEditScreen(
          users: widget.users,
          initial: _todo,
        ),
      ),
    );
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.update(_todo.copyWith(
        title: input.title,
        userId: input.userId,
        completed: input.completed,
      ));
      if (!mounted) return;
      setState(() {
        _todo = updated;
        _changed = true;
      });
      _message('Зміни збережено');
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити задачу?'),
        content: const Text('Задачу можна буде повернути протягом 3 секунд.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ні'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.delete(_todo);
      if (!mounted) return;
      Navigator.pop(context, DetailResult(changed: true, deletedTodo: _todo));
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Деталі задачі'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(
              context,
              DetailResult(changed: _changed),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_busy) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Задача #${_todo.id}',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 14),
                        Text(_todo.title,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Користувач'),
                          subtitle: Text(_userName),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_todo.completed ? 'Виконано' : 'Очікує'),
                          subtitle: const Text('Змінити статус задачі (PATCH)'),
                          value: _todo.completed,
                          onChanged: _busy ? null : _toggle,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Редагувати (PUT)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Видалити (DELETE)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
}

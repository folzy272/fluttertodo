import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/todo.dart';
import '../models/todo_input.dart';
import '../services/todo_repository.dart';
import '../widgets/error_widget.dart';
import '../widgets/item_card.dart';
import 'create_edit_screen.dart';
import 'detail_screen.dart';

enum TodoFilter { all, completed, pending }

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TodoRepository _repository = TodoRepository();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _busyIds = <int>{};

  late Future<void> _loadingFuture;
  List<AppUser> _users = [];
  List<Todo> _todos = [];
  int _selectedUserId = 0;
  TodoFilter _filter = TodoFilter.all;
  String _search = '';
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _load();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _search = _searchController.text.trim().toLowerCase());
      }
    });
  }

  Future<void> _load() async {
    if (_users.isEmpty) _users = await _repository.getUsers();
    final result = await _repository.getTodos(
      userId: _selectedUserId == 0 ? null : _selectedUserId,
    );
    if (!mounted) return;
    _todos = result;
  }

  void _reload() => setState(() => _loadingFuture = _load());

  @override
  void dispose() {
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  String _userName(int userId) {
    for (final user in _users) {
      if (user.id == userId) return user.name;
    }
    return 'Користувач $userId';
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _create() async {
    if (_creating || _users.isEmpty) return;
    final input = await Navigator.of(context).push<TodoInput>(
      MaterialPageRoute(
        builder: (_) => CreateEditScreen(
          users: _users,
          initialUserId: _selectedUserId == 0 ? null : _selectedUserId,
        ),
      ),
    );
    if (input == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final todo = await _repository.create(
        title: input.title,
        userId: input.userId,
        completed: input.completed,
      );
      if (!mounted) return;
      if (_selectedUserId != 0 && _selectedUserId != todo.userId) {
        _selectedUserId = todo.userId;
        _reload();
      } else {
        setState(() => _todos = [..._todos, todo]);
      }
      _showMessage('Задачу створено');
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _toggle(Todo todo, bool value) async {
    if (_busyIds.contains(todo.id)) return;
    setState(() => _busyIds.add(todo.id));
    try {
      final changed = await _repository.toggle(todo, value);
      if (!mounted) return;
      setState(() {
        _todos = _todos.map((item) => item.id == todo.id ? changed : item).toList();
      });
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _busyIds.remove(todo.id));
    }
  }

  Future<void> _delete(Todo todo) async {
    if (_busyIds.contains(todo.id)) return;
    setState(() => _busyIds.add(todo.id));
    try {
      await _repository.delete(todo);
      if (!mounted) return;
      setState(() => _todos.removeWhere((item) => item.id == todo.id));
      _showUndo(todo);
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _busyIds.remove(todo.id));
    }
  }

  void _showUndo(Todo todo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Задачу видалено'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'СКАСУВАТИ',
          onPressed: () async {
            try {
              await _repository.restore(todo);
              if (mounted) _reload();
            } catch (error) {
              _showMessage('$error');
            }
          },
        ),
      ));
  }

  Future<void> _details(Todo todo) async {
    final result = await Navigator.of(context).push<DetailResult>(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          todo: todo,
          users: _users,
          repository: _repository,
        ),
      ),
    );
    if (!mounted) return;
    _reload();
    if (result?.deletedTodo != null) _showUndo(result!.deletedTodo!);
  }

  List<Todo> get _visibleTodos {
    final filtered = _todos.where((todo) {
      final matchesStatus = switch (_filter) {
        TodoFilter.all => true,
        TodoFilter.completed => todo.completed,
        TodoFilter.pending => !todo.completed,
      };
      return matchesStatus && todo.title.toLowerCase().contains(_search);
    }).toList();
    filtered.sort((a, b) {
      final userCompare = a.userId.compareTo(b.userId);
      if (userCompare != 0) return userCompare;
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      return a.id.compareTo(b.id);
    });
    return filtered;
  }

  List<_TaskRow> _groupedRows(List<Todo> todos) {
    final rows = <_TaskRow>[];
    int? lastUser;
    for (final todo in todos) {
      if (lastUser != todo.userId) {
        rows.add(_TaskRow.header(todo.userId));
        lastUser = todo.userId;
      }
      rows.add(_TaskRow.todo(todo));
    }
    return rows;
  }

  Widget _stats() {
    final total = _todos.length;
    final completed = _todos.where((todo) => todo.completed).length;
    final pending = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 10),
                Text('Прогрес виконання',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 18, runSpacing: 6, children: [
              Text('Усього: $total'),
              Text('Виконано: $completed'),
              Text('Очікують: $pending'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _filters() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey(_selectedUserId),
            value: _selectedUserId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Задачі користувача',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: <DropdownMenuItem<int>>[
              const DropdownMenuItem<int>(
                value: 0,
                child: Text('Усі користувачі'),
              ),
              ..._users.map((user) => DropdownMenuItem<int>(
                    value: user.id,
                    child: Text(user.name, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (value) {
              if (value == null || _selectedUserId == value) return;
              _selectedUserId = value;
              _reload();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Пошук задач за назвою',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilterChip(
              label: const Text('Усі'),
              selected: _filter == TodoFilter.all,
              onSelected: (_) => setState(() => _filter = TodoFilter.all),
            ),
            FilterChip(
              label: const Text('Виконані'),
              selected: _filter == TodoFilter.completed,
              onSelected: (_) => setState(() => _filter = TodoFilter.completed),
            ),
            FilterChip(
              label: const Text('Очікують'),
              selected: _filter == TodoFilter.pending,
              onSelected: (_) => setState(() => _filter = TodoFilter.pending),
            ),
          ]),
        ],
      );

  Widget _content() {
    final visible = _visibleTodos;
    final rows = _groupedRows(visible);
    return Column(
      children: [
        _stats(),
        const SizedBox(height: 14),
        _filters(),
        const SizedBox(height: 10),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'За вибраними параметрами задач немає',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 95),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row.headerUserId != null) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          _userName(row.headerUserId!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    }
                    final todo = row.todo!;
                    return TodoCard(
                      todo: todo,
                      userName: _userName(todo.userId),
                      isBusy: _busyIds.contains(todo.id),
                      onToggle: (value) => _toggle(todo, value),
                      onTap: () => _details(todo),
                      onDelete: () => _delete(todo),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('TODO менеджер'),
          actions: [
            IconButton(
              onPressed: _reload,
              tooltip: 'Оновити список',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FutureBuilder<void>(
                future: _loadingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ErrorView(
                      message: '${snapshot.error}',
                      onRetry: _reload,
                    );
                  }
                  return _content();
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _creating || _users.isEmpty ? null : _create,
          icon: _creating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Нова задача'),
        ),
      );
}

class _TaskRow {
  const _TaskRow.header(int userId)
      : headerUserId = userId,
        todo = null;

  const _TaskRow.todo(Todo item)
      : headerUserId = null,
        todo = item;

  final int? headerUserId;
  final Todo? todo;
}

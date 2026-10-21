import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/todo.dart';
import '../models/todo_input.dart';

class CreateEditScreen extends StatefulWidget {
  const CreateEditScreen({
    super.key,
    required this.users,
    this.initial,
    this.initialUserId,
  });

  final List<AppUser> users;
  final Todo? initial;
  final int? initialUserId;

  @override
  State<CreateEditScreen> createState() => _CreateEditScreenState();
}

class _CreateEditScreenState extends State<CreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late int _userId;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    final suggested = widget.initial?.userId ?? widget.initialUserId;
    _userId = widget.users.any((user) => user.id == suggested)
        ? suggested!
        : widget.users.first.id;
    _completed = widget.initial?.completed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(TodoInput(
      title: _titleController.text.trim(),
      userId: _userId,
      completed: _completed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Редагувати задачу' : 'Нова задача')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !editing,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 180,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Назва задачі',
                    hintText: 'Наприклад: Виконати лабораторну роботу',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Введіть назву задачі'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _userId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Користувач',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: widget.users
                      .map((user) => DropdownMenuItem<int>(
                            value: user.id,
                            child: Text(user.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _userId = value);
                  },
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile(
                    title: const Text('Задача виконана'),
                    subtitle: const Text('За замовчуванням вимкнено'),
                    value: _completed,
                    onChanged: (value) => setState(() => _completed = value),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Зберегти зміни' : 'Створити задачу'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

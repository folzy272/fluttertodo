class TodoInput {
  const TodoInput({
    required this.title,
    required this.userId,
    required this.completed,
  });

  final String title;
  final int userId;
  final bool completed;
}

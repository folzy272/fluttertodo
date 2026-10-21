class Todo {
  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  final int id;
  final int userId;
  final String title;
  final bool completed;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'userId': userId,
        'title': title,
        'completed': completed,
      };

  Todo copyWith({int? userId, String? title, bool? completed}) => Todo(
        id: id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        completed: completed ?? this.completed,
      );
}

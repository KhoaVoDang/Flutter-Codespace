class Todo {
  String id;
  String text;
  bool isDone;
  bool isPinned;
  String tag;
  String userId;

  Todo({
    required this.id,
    required this.text,
    this.isDone = false,
    this.isPinned = false,
    this.tag = '',
    required this.userId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      text: json['text'] ?? '',
      isDone: json['is_done'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      tag: json['tag'] ?? '',
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_done': isDone,
      'is_pinned': isPinned,
      'tag': tag,
      'user_id': userId,
    };
  }
}

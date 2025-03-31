class Todo {
  int id;
  String text;
  bool isDone;
  bool isPinned;
  String tag;

  Todo({
    required this.id,
    required this.text,
    this.isDone = false,
     this.isPinned = false,
    
    this.tag = '',
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      text: json['text'],
      isDone: json['isDone'],
      isPinned: json['isPinned'],
      tag: json['tag']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
        'isPinned': isPinned,
      
        'tag': tag
    };
  }
}

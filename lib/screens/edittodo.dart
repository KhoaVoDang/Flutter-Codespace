import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/todo.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditTodoScreen extends StatefulWidget {
  final Todo todo;
  final VoidCallback onEdit;

  const EditTodoScreen({Key? key, required this.todo, required this.onEdit})
      : super(key: key);

  @override
  State<EditTodoScreen> createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  late TextEditingController _textController;
  late bool _isPinned;
  late String _selectedTag;
  String note = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.todo.text);
    _isPinned = widget.todo.isPinned;
    _selectedTag = widget.todo.tag;
    note = widget.todo.text;
  }

  Future<void> _saveEdit() async {
    if (_textController.text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final todoStrings = prefs.getStringList('todos') ?? [];

    // Create an updated Todo using widget.todo's id.
    final updatedTodo = Todo(
      id: widget.todo.id,
      text: _textController.text,
      isPinned: _isPinned,
      tag: _selectedTag,
    );

    // Find and replace the todo with the matching id.
    for (int i = 0; i < todoStrings.length; i++) {
      final Map<String, dynamic> todoMap = json.decode(todoStrings[i]);
      if (todoMap['id'] == widget.todo.id) {
        todoStrings[i] = json.encode(updatedTodo.toJson());
        break;
      }
    }

    await prefs.setStringList('todos', todoStrings);
    widget.onEdit();
    ShadToaster.of(context).show(
      const ShadToast(
        description: Text('Task edited'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit task',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          Expanded(
            child: ShadInput(
              onChanged: (value) => setState(() {
                note = value;
              }),
              controller: _textController,
             minLines: null,
              maxLines: null,
            expands: true,
              autofocus: true,
              style: ShadTheme.of(context).textTheme.h4.copyWith(fontSize: 20),
              decoration: ShadDecoration(
                color: ShadTheme.of(context).colorScheme.background,
                focusedBorder: ShadBorder.none,
                border: ShadBorder.none,
                secondaryBorder: ShadBorder.none,
                disableSecondaryBorder: true,
              ),
            ),
          ),
         
          Row(
            children: [
              _isPinned
                  ? ShadButton(
                      child: Text("Unpin"),
                      leading: Icon(Icons.push_pin),
                      onPressed: () => setState(() => _isPinned = !_isPinned),
                    )
                  : ShadButton.secondary(
                      leading: Icon(Icons.push_pin),
                      child: Text("Pin"),
                      onPressed: () => setState(() => _isPinned = !_isPinned),
                    ),
              Spacer(),
              note.isNotEmpty
                  ? ShadButton(
                      onPressed: _saveEdit,
                      child: Text("Save"),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

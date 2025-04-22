import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/todo.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTodoScreen extends StatefulWidget {
  final VoidCallback onAdd;
  final String? collectionId; // <-- Add this
  const AddTodoScreen({Key? key, required this.onAdd, this.collectionId}) : super(key: key);

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isPinned = false;
  String _selectedTag = '';
  String note = '';

  Future<void> _saveTodo() async {
    if (_textController.text.isEmpty) return;

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('You must be logged in to add tasks'),
          ),
        );
      }
      return;
    }

    try {
      await supabase.from('notes').insert({
        'text': _textController.text,
        'is_pinned': _isPinned,
        'tag': _selectedTag,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': currentUser.id,
        'collection_id': widget.collectionId, // <-- Assign to collection
      });

      widget.onAdd();
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Task added'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Failed to add task: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add task',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          Expanded(
            child: ShadInput(
              onChanged: (value) => setState(() {
                note = _textController.text;
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
              // decoration: InputDecoration(labelText: "Todo"),
            ),
          ),
          Row(
            children: [
              _isPinned
                  ? ShadButton(
                      child: Text("Unpin"),
                      leading: Icon(Icons.push_pin),
                      onPressed: () => setState(() {
                        _isPinned = !_isPinned;
                      }),
                    )
                  : ShadButton.secondary(
                      leading: Icon(Icons.push_pin),
                      child: Text("Pin"),
                      onPressed: () => setState(() {
                        _isPinned = !_isPinned;
                      }),
                    ),
              Spacer(),
              note.isNotEmpty
                  ? ShadButton(
                      onPressed: _saveTodo,
                      child: Text("Save"),
                    )
                  : SizedBox.shrink()
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/todo.dart';

class TodoRow extends StatelessWidget {
  final Todo todo;
  final bool isPinned;
  final ShadThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const TodoRow({
    required this.todo,
    required this.isPinned,
    required this.theme,
    required this.onTap,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShadCheckbox(
              value: todo.isDone,
              onChanged: (bool? value) => onToggle(),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.text,
                    style: theme.textTheme.p.copyWith(
                      decoration: todo.isDone ? TextDecoration.lineThrough : null,
                      color: todo.isDone
                          ? theme.colorScheme.mutedForeground
                          : theme.colorScheme.foreground,
                      fontWeight: isPinned ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

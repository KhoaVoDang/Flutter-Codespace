import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final int total;
  final int done;
  final int percent;
  final ShadThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CollectionCard({
    required this.collection,
    required this.total,
    required this.done,
    required this.percent,
    required this.theme,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  void _showCollectionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.folder, color: theme.colorScheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      collection['name'] ?? '',
                      style: theme.textTheme.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: theme.colorScheme.muted),
                  SizedBox(width: 8),
                  Text('Total tasks: $total', style: theme.textTheme.muted),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Completed: $done', style: theme.textTheme.muted),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.percent, size: 18, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Finished: $percent%', style: theme.textTheme.muted),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onTap != null) onTap();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 6),
                          Text('View'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onEdit != null) onEdit!();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 6),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShadButton.destructive(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onDelete != null) onDelete!();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 6),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$total tasks', style: theme.textTheme.muted),
                Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.ellipsis, size: 20, color: theme.colorScheme.mutedForeground),
                  onPressed: () => _showCollectionDetails(context),
                  tooltip: 'More',
                ),
              ],
            ),
            Text(
              collection['name'] ?? '',
              style: theme.textTheme.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Spacer(),
            Row(
              
              children: [
                Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: 4),
                Text('$percent%', style: theme.textTheme.small),
              ],
            ),
            SizedBox(height: 4),
            ShadProgress(
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              backgroundColor: theme.colorScheme.muted.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final int total;
  final int done;
  final int percent;
  final ShadThemeData theme;
  final VoidCallback onTap;

  const CollectionCard({
    required this.collection,
    required this.total,
    required this.done,
    required this.percent,
    required this.theme,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$total tasks', style: theme.textTheme.muted),
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
            LinearProgressIndicator(
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

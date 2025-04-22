import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PomodoroFlipTimer extends StatelessWidget {
  final Duration duration;
  final String label;
  const PomodoroFlipTimer({required this.duration, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return ShadCard(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: ShadTheme.of(context).textTheme.h4
          ),
          Text(
            label,
            style: ShadTheme.of(context).textTheme.small
          ),
        ],
      ),
    );
  }
}

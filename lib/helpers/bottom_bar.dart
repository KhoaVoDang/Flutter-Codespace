import 'package:flutter/material.dart';


class BottomBarItem extends StatelessWidget {
  final IconData icon;
  final bool isMain;
  final VoidCallback? onTap;

  const BottomBarItem({
    required this.icon,
    this.isMain = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMain ? Colors.grey[900] : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: isMain ? 32 : 24,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
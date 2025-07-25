import 'package:flutter/material.dart';
import '../../theme/system_theme.dart';

class ThemedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ThemedButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: SystemTheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SystemTheme.primary.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: SystemTheme.accent),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SystemTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
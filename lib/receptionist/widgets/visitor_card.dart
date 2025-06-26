import 'package:flutter/material.dart';
import '../../theme/receptionist_theme.dart';

class VisitorCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final Color color;
  final bool showCheckout;
  final VoidCallback? onCheckout;

  const VisitorCard({
    Key? key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.color,
    this.showCheckout = false,
    this.onCheckout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: color.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: ReceptionistTheme.text)),
        subtitle: Text(subtitle, style: TextStyle(color: ReceptionistTheme.text)),
        trailing: showCheckout
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReceptionistTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onCheckout,
                child: const Text('Check Out'),
              )
            : Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
} 
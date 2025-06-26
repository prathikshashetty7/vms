import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/visitor_card.dart';

class VisitorTrackingPage extends StatelessWidget {
  const VisitorTrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for illustration
    final visitors = [
      {'name': 'John Doe', 'status': 'Checked In'},
      {'name': 'Jane Smith', 'status': 'Checked Out'},
    ];
    return Scaffold(
      backgroundColor: ReceptionistTheme.background,
      appBar: AppBar(
        title: const Text('Visitor Tracking'),
        backgroundColor: ReceptionistTheme.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: visitors.length,
        itemBuilder: (context, index) {
          final visitor = visitors[index];
          return VisitorCard(
            name: visitor['name']!,
            subtitle: 'Status: ${visitor['status']}',
            status: visitor['status']!,
            color: visitor['status'] == 'Checked In'
                ? ReceptionistTheme.accent
                : ReceptionistTheme.secondary,
            showCheckout: visitor['status'] == 'Checked In',
            onCheckout: () {
              // TODO: Update Firestore
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${visitor['name']} checked out!')),
              );
            },
          );
        },
      ),
    );
  }
} 
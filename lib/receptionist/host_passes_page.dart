import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/visitor_card.dart';

class HostPassesPage extends StatelessWidget {
  const HostPassesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for illustration
    final passes = [
      {'visitor': 'John Doe', 'host': 'Alice', 'passcode': 'A123', 'status': 'Unused'},
      {'visitor': 'Jane Smith', 'host': 'Bob', 'passcode': 'B456', 'status': 'Used'},
    ];
    return Scaffold(
      backgroundColor: ReceptionistTheme.background,
      appBar: AppBar(
        title: const Text('Host-Generated Passes'),
        backgroundColor: ReceptionistTheme.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: passes.length,
        itemBuilder: (context, index) {
          final pass = passes[index];
          return VisitorCard(
            name: pass['visitor']!,
            subtitle: 'Host: ${pass['host']} | Pass: ${pass['passcode']}',
            status: pass['status']!,
            color: pass['status'] == 'Used'
                ? ReceptionistTheme.secondary
                : ReceptionistTheme.accent,
          );
        },
      ),
    );
  }
} 
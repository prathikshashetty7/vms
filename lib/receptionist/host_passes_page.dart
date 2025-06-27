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
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: const Text('Host-Generated Passes'),
        backgroundColor: Color(0xFF6CA4FE),
        automaticallyImplyLeading: false,
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 1,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            // Already here
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/receptionist_reports');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_rounded),
            label: 'Host Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Add Visitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
} 
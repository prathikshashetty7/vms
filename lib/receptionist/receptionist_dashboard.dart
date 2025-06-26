import 'package:flutter/material.dart';
import '../logout.dart';

class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptionist Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Text(
                'Receptionist Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('View Visitors'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to View Visitors page
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to View Report page
              },
            ),
            const Divider(),
            const LogoutTile(),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Receptionist Dashboard!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
} 
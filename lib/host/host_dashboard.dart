import 'package:flutter/material.dart';
import '../logout.dart';

class HostDashboard extends StatelessWidget {
  const HostDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Host Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Manage Visitors'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Manage Visitors page
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
          'Welcome to the Host Dashboard!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
} 
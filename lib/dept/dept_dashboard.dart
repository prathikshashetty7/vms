import 'package:flutter/material.dart';
import 'manage_roles.dart';
import 'manage_employees.dart';
import '../logout.dart';

class DeptDashboard extends StatelessWidget {
  const DeptDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Department Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Manage Roles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageRoles()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Manage Employees'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageEmployees()),
                );
              },
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
          'Welcome to the Department Dashboard!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';
import 'manage_roles.dart';
import 'manage_employees.dart';
import 'manage_visitors.dart';
import '../logout.dart';
import 'dept_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeptDashboard extends StatelessWidget {
  const DeptDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeptTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Color(0xFFD4E9FF),
        appBar: AppBar(
          title: const Text('Welcome to the Department Dashboard!', style: DeptTheme.appBarTitle),
          backgroundColor: Color(0xFF6CA4FE),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: DeptTheme.deptGradient,
                ),
                child: const Center(
                  child: Text(
                    'Department Menu',
                    style: DeptTheme.heading
                  
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.security, color: DeptTheme.deptPrimary),
                title: const Text('Manage Roles', style: DeptTheme.body),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageRoles()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_alt, color: DeptTheme.deptPrimary),
                title: const Text('Manage Employees', style: DeptTheme.body),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageEmployees()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: DeptTheme.deptPrimary),
                title: const Text('Manage Visitors', style: DeptTheme.body),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageVisitors()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: DeptTheme.deptPrimary),
                title: const Text('View Report', style: DeptTheme.body),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeptReport()),
                  );
                },
              ),
              const Divider(),
              const LogoutTile(),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              _DeptAnalytics(),
              const SizedBox(height: 16),
              Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: DeptTheme.deptLight.withOpacity(0.95),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment, size: 64, color: DeptTheme.deptPrimary),
                        const SizedBox(height: 16),
                        const Text('Department Dashboard!', style: DeptTheme.heading, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        const Text('Manage your department roles, employees, and visitors efficiently.', style: DeptTheme.body, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Chip(label: Text('Secure', style: TextStyle(color: DeptTheme.deptDark)), backgroundColor: DeptTheme.deptSecondary),
                            SizedBox(width: 8),
                            Chip(label: Text('Efficient', style: TextStyle(color: DeptTheme.deptDark)), backgroundColor: DeptTheme.deptSecondary),
                            SizedBox(width: 8),
                            Chip(label: Text('Professional', style: TextStyle(color: DeptTheme.deptDark)), backgroundColor: DeptTheme.deptSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AnalyticsTile(label: 'Roles', icon: Icons.security, collection: 'roles'),
              _AnalyticsTile(label: 'Receptionists', icon: Icons.person, collection: 'receptionist'),
              _AnalyticsTile(label: 'Hosts', icon: Icons.people_alt, collection: 'host'),
              _AnalyticsTile(label: 'Visitors', icon: Icons.people, collection: 'visitor'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String collection;
  const _AnalyticsTile({required this.label, required this.icon, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DeptTheme.deptPrimary, size: 32),
        const SizedBox(height: 8),
        StreamBuilder<int>(
          stream: _countStream(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('$count', style: DeptTheme.heading.copyWith(fontSize: 22));
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: DeptTheme.body),
      ],
    );
  }

  Stream<int> _countStream() {
    return FirebaseFirestore.instance.collection(collection).snapshots().map((snap) => snap.docs.length);
  }
} 
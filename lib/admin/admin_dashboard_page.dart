import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  final void Function(int) onCardTap;
  const AdminDashboardPage({Key? key, required this.onCardTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'Total Visitors',
                    value: '--',
                    icon: Icons.groups,
                    color: Colors.deepPurple,
                    onTap: () => onCardTap(3), // 3 = Visitor Management
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'Total Employees',
                    value: '--',
                    icon: Icons.people_alt,
                    color: Colors.blue,
                    onTap: () => onCardTap(4), // 4 = Employee Management
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('Admin Dashboard Content Goes Here', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
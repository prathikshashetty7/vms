import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/stat_card.dart';
import '../signin.dart';

class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReceptionistTheme.background,
      appBar: AppBar(
        title: const Text('Receptionist Dashboard'),
        backgroundColor: ReceptionistTheme.primary,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: ReceptionistTheme.primary,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ReceptionistTheme.accent,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 12),
                  Text('Receptionist', style: TextStyle(color: ReceptionistTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('receptionist@email.com', style: TextStyle(color: ReceptionistTheme.text, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: ReceptionistTheme.accent),
              title: const Text('Dashboard', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                // Already on dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: ReceptionistTheme.accent),
              title: const Text('Host Passes', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/host_passes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: ReceptionistTheme.accent),
              title: const Text('Manual Entry', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manual_entry');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: ReceptionistTheme.accent),
              title: const Text('Kiosk QR', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/kiosk_qr');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes, color: ReceptionistTheme.accent),
              title: const Text('Visitor Tracking', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/visitor_tracking');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatCard(
                  title: 'Current Visitors',
                  value: '12',
                  icon: Icons.people,
                  color: ReceptionistTheme.secondary,
                ),
                StatCard(
                  title: 'Checked In',
                  value: '8',
                  icon: Icons.login,
                  color: ReceptionistTheme.accent,
                ),
                StatCard(
                  title: 'Checked Out',
                  value: '4',
                  icon: Icons.logout,
                  color: ReceptionistTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Welcome, Receptionist!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ReceptionistTheme.text,
                  ),
            ),
            const SizedBox(height: 20),
            // Dashboard is now clean, navigation is in the drawer
          ],
        ),
      ),
    );
  }
} 
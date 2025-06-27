import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'themed_visitor_list_page.dart';

class ReceptionistReportsPage extends StatelessWidget {
  const ReceptionistReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Reports', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Color(0xFF6CA4FE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Manual Registrations',
                icon: Icons.edit_document,
                color: Colors.deepPurpleAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemedVisitorListPage(
                        collection: 'manual_registrations',
                        title: 'Manual Registrations',
                        icon: Icons.edit_document,
                        color: Colors.deepPurpleAccent,
                        nameField: 'fullName',
                        mobileField: 'mobile',
                        timeField: 'timestamp',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Kiosk Registrations',
                icon: Icons.qr_code,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemedVisitorListPage(
                        collection: 'kiosk_registrations',
                        title: 'Kiosk Registrations',
                        icon: Icons.qr_code,
                        color: Colors.teal,
                        nameField: 'fullName',
                        mobileField: 'mobile',
                        timeField: 'timestamp',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Host Passes',
                icon: Icons.vpn_key,
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemedVisitorListPage(
                        collection: 'host_passes',
                        title: 'Host Passes',
                        icon: Icons.vpn_key,
                        color: Colors.orangeAccent,
                        nameField: 'visitor',
                        mobileField: 'mobile',
                        timeField: 'timestamp',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Appointed Visitors',
                icon: Icons.event_available,
                color: Color(0xFF60A5FA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemedVisitorListPage(
                        collection: 'visitor',
                        title: 'Appointed Visitors',
                        icon: Icons.event_available,
                        color: Color(0xFF60A5FA),
                        nameField: 'v_name',
                        mobileField: 'v_contactno',
                        timeField: 'v_date',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 3,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/host_passes');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          } else if (index == 3) {
            // Already here
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Color(0x22005FFE),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(22),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF091016),
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitleForTitle(title),
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF005FFE), size: 28),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  String _subtitleForTitle(String title) {
    switch (title) {
      case 'Manual Registrations':
        return 'All walk-in visitors';
      case 'Kiosk Registrations':
        return 'Self-service check-ins';
      case 'Host Passes':
        return 'Invited by host';
      default:
        return '';
    }
  }
} 
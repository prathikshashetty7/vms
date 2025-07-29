import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manual_registrations.dart';
import 'dashboard.dart' show VisitorsPage;
import 'kiosk_qr_page.dart';

class ReceptionistReportsPage extends StatelessWidget {
  const ReceptionistReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Visitor Details', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
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
                color: Color(0xFF6CA4FE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualRegistrationsPage(
                        collection: 'manual_registrations',
                        title: 'Manual Registrations',
                        icon: Icons.edit_document,
                        color: Color(0xFF6CA4FE),
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
                color: Color(0xFF6CA4FE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KioskRegistrationsPage(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              _SectionCard(
                title: 'QR Code Registrations',
                icon: Icons.qr_code_2,
                color: Color(0xFF6CA4FE),
                subtitle: 'Visitors registered via QR code',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualRegistrationsPage(
                        collection: 'qr_code_registrations',
                        title: 'QR Code Registrations',
                        icon: Icons.qr_code_2,
                        color: Color(0xFF6CA4FE),
                        nameField: 'fullName',
                        mobileField: 'mobile',
                        timeField: 'timestamp',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _SectionCard(
                  title: 'Host Passes',
                  icon: Icons.person_outline,
                  color: Color(0xFF6CA4FE),
                  subtitle: 'Invited by host',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManualRegistrationsPage(
                          collection: 'passes',
                          title: 'Host Passes',
                          icon: Icons.person_outline,
                          color: Color(0xFF6CA4FE),
                          nameField: 'v_name',
                          mobileField: 'v_contactno',
                          timeField: 'created_at',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
            // Already here (Visitors)
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VisitorsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_rounded),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Add Visitor',
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
  final String? subtitle;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.onTap, this.subtitle, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white, // solid white background
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: color.withOpacity(0.13), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(icon, color: Colors.white, size: 38),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF091016),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 1.1,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      subtitle ?? _subtitleForTitle(title),
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 24),
              const SizedBox(width: 18),
            ],
          ),
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
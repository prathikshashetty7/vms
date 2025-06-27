import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/stat_card.dart';
import '../signin.dart';
import 'dart:ui';
import 'manual_entry_page.dart';
import 'receptionist_reports_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/signin');
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/host_passes');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/manual_entry');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/receptionist_reports');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Receptionist Dashboard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Color(0xFF6CA4FE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFD4E9FF),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              // Decorative Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x226CA4FE),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 60,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6CA4FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Receptionist',
                            style: TextStyle(
                              color: Color(0xFF091016),
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hope you have a wonderful day at work! 😊',
                            style: TextStyle(
                              color: Color(0xFF6CA4FE),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF6CA4FE),
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Activity List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x226CA4FE),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active, color: Color(0xFF6CA4FE)),
                          const SizedBox(width: 8),
                          Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF091016), fontFamily: 'Poppins')),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) => _AllActivityListSheet(),
                              );
                            },
                            child: Text('See more', style: TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      _ActivityListWidget(limit: 3),
                    ],
                  ),
                ),
              ),
              // Stat Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.85,
                    children: [
                      _StyledStatCard(
                        title: 'Current Visitors',
                        value: '12',
                        icon: Icons.people,
                      ),
                      _StyledStatCard(
                        title: 'Checked In',
                        value: '8',
                        icon: Icons.login,
                      ),
                      _StyledStatCard(
                        title: 'Checked Out',
                        value: '4',
                        icon: Icons.logout,
                      ),
                      _StyledStatCard(
                        title: 'Pending Approvals',
                        value: '2',
                        icon: Icons.pending_actions,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Optionally, add more creative widgets here
            ],
          ),
        ),
      ),
    );
  }
}

// Modern styled stat card widget
class _StyledStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StyledStatCard({
    required this.title,
    required this.value,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDF4FF), Color(0xFFD4E9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0x226CA4FE),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF6CA4FE).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Color(0xFF6CA4FE),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Add quick action button widget
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap, Key? key}) : super(key: key);
  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1.0);
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              // Glassmorphism effect
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      widget.icon,
                      color: Colors.black,
                      size: 30,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityListWidget extends StatelessWidget {
  final int limit;
  const _ActivityListWidget({this.limit = 3, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final manualStream = FirebaseFirestore.instance
        .collection('manual_registrations')
        .orderBy('timestamp', descending: true)
        .limit(15)
        .snapshots();
    final deptStream = FirebaseFirestore.instance
        .collection('visitor')
        .orderBy('v_date', descending: true)
        .limit(15)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: manualStream,
      builder: (context, manualSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: deptStream,
          builder: (context, deptSnapshot) {
            if (!manualSnapshot.hasData || !deptSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allDocs = [
              ...manualSnapshot.data!.docs.map((doc) => {'data': doc.data(), 'type': 'manual'}),
              ...deptSnapshot.data!.docs.map((doc) => {'data': doc.data(), 'type': 'dept'}),
            ];
            allDocs.sort((a, b) {
              final aTime = (a['data'] as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTime = (b['data'] as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
            final latest = allDocs.take(limit).toList();
            if (latest.isEmpty) {
              return const Text('No recent activity.', style: TextStyle(color: Color(0xFF6CA4FE)));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: latest.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
              itemBuilder: (context, index) {
                final entry = latest[index];
                final data = entry['data'] as Map<String, dynamic>;
                final type = entry['type'] as String;
                String name = 'Unknown';
                DateTime? time;
                if (type == 'manual') {
                  name = data['fullName'] ?? data['visitor'] ?? 'Unknown';
                  final ts = data['timestamp'] as Timestamp?;
                  time = ts != null ? ts.toDate() : null;
                } else if (type == 'dept') {
                  name = data['v_name'] ?? 'Unknown';
                  final ts = data['v_date'] as Timestamp?;
                  time = ts != null ? ts.toDate() : null;
                }
                String message = type == 'dept' ? 'Dept visitor added: $name' : 'New visitor added: $name';
                return ListTile(
                  leading: Icon(Icons.person, color: Color(0xFF6CA4FE)),
                  title: Text(message, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', fontSize: 14)),
                  subtitle: time != null ? Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}  ${time.day}/${time.month}/${time.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))) : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AllActivityListSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Color(0xFF6CA4FE)),
                const SizedBox(width: 8),
                Text('All Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), fontFamily: 'Poppins')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ActivityListWidget(limit: 30),
            ),
          ],
        ),
      ),
    );
  }
} 
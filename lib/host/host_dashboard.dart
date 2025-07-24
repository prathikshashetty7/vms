import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'view_visitors_page.dart';
import 'create_pass_page.dart';
import 'history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostMainScreen extends StatefulWidget {
  const HostMainScreen({Key? key}) : super(key: key);

  @override
  State<HostMainScreen> createState() => _HostMainScreenState();
}

class _HostMainScreenState extends State<HostMainScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = [
    'Host Dashboard',
    'View Visitors',
    'Create Pass',
    'History',
    'Logout',
  ];
  final List<Widget> _pages = [
    HostDashboardScreen(),
    ViewVisitorsPage(),
    CreatePassPage(),
    HistoryScreen(),
    SizedBox.shrink(), // Placeholder for logout
  ];

  void _onNavBarTap(int index) async {
    if (index == 4) {
      // Logout with confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
      if (shouldLogout == true) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Color(0xFF6CA4FE),
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: Image.asset(
            'assets/images/rdl.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.1, fontFamily: 'Poppins'),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1, fontFamily: 'Poppins'),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'View Visitors'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Create Pass'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: 'Logout'),
        ],
      ),
    );
  }
}

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen();
  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  String? hostName;
  String? hostEmail;
  String? hostDept;
  String? hostDeptId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHostDetails();
  }

  Future<void> _fetchHostDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('host').where('emp_email', isEqualTo: user.email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      String? deptName = data['department'];
      String? deptId = data['departmentId'];
      if ((deptName == null || deptName.isEmpty) && deptId != null && deptId.isNotEmpty) {
        // Fetch department name from department collection
        final deptSnap = await FirebaseFirestore.instance.collection('department').doc(deptId).get();
        if (deptSnap.exists) {
          deptName = deptSnap.data()?['d_name'] ?? deptId;
        } else {
          deptName = deptId;
        }
      }
      setState(() {
        hostName = data['emp_name'] ?? 'Host';
        hostEmail = data['emp_email'] ?? user.email;
        hostDept = deptName ?? '';
        hostDeptId = deptId;
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Host Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF6CA4FE),
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hostName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(hostEmail ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hostDept != null && hostDept!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.apartment, size: 18, color: Color(0xFF6CA4FE)),
                  const SizedBox(width: 8),
                  Text('Department: $hostDept', style: const TextStyle(fontSize: 15)),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD4E9FF),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: 32),
          // Welcome Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostName != null && hostName!.isNotEmpty
                            ? 'Welcome, $hostName!'
                            : 'Welcome, Host!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF091016),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hostDept != null && hostDept!.isNotEmpty)
                        Text(
                          'Department: $hostDept',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 30),
          // Stat Cards Grid
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 0, bottom: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile: 2x2 grid
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.85,
                    children: const [
                      _StyledStatCard(title: 'Visitors Today', value: '0', icon: Icons.groups),
                      _StyledStatCard(title: 'Upcoming Visitors', value: '0', icon: Icons.event),
                      _StyledStatCard(title: 'Total Passes', value: '0', icon: Icons.qr_code),
                      _StyledStatCard(title: 'Pending Checkouts', value: '0', icon: Icons.logout),
                    ],
                  );
                } else {
                  // Wide: 1 row of 4
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Expanded(child: _StyledStatCard(title: 'Visitors Today', value: '0', icon: Icons.groups)),
                      SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(title: 'Upcoming Visitors', value: '0', icon: Icons.event)),
                      SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(title: 'Total Passes', value: '0', icon: Icons.qr_code)),
                      SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(title: 'Pending Checkouts', value: '0', icon: Icons.logout)),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // Recent Activity Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x226CA4FE),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 6, left: 12, right: 12, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF6CA4FE)),
                      const SizedBox(width: 8),
                      Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF091016), fontFamily: 'Poppins')),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text('See more', style: TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _ActivityItem(
                    icon: Icons.person,
                    title: 'Visitor checked in',
                    subtitle: 'Amit, 9:00 AM',
                  ),
                  Divider(height: 18, color: Color(0xFFE0E0E0)),
                  const _ActivityItem(
                    icon: Icons.person,
                    title: 'Visitor checked out',
                    subtitle: 'Rahul, 7:30 AM',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final double cardFontSize;
  final double labelFontSize;
  const _StatCard({required this.title, required this.icon, required this.value, required this.cardFontSize, required this.labelFontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SystemTheme.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Reduce vertical padding
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: SystemTheme.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            // Reduce icon padding
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: SystemTheme.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF091016),
              fontSize: cardFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF091016),
              fontSize: labelFontSize,
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

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActivityItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SystemTheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

// Modern styled stat card widget for host, matching receptionist
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x226CA4FE),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Reduce vertical padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6CA4FE).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7), // Reduce icon padding
            child: Icon(
              icon,
              color: const Color(0xFF6CA4FE),
              size: 22, // Reduce icon size
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 18, // Reduce font size
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 11, // Reduce font size
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
import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'manage_roles.dart';
import 'manage_employees.dart';
import 'manage_visitors.dart';
import '../logout.dart';
import 'dept_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeptDashboard extends StatefulWidget {
  const DeptDashboard({Key? key}) : super(key: key);

  @override
  State<DeptDashboard> createState() => _DeptDashboardState();
}

class _DeptDashboardState extends State<DeptDashboard> {
  int _selectedIndex = 0;
  String? _currentDepartmentId;
  bool _loadingDeptId = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentDepartmentId();
  }

  Future<void> _fetchCurrentDepartmentId() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      setState(() { _loadingDeptId = false; });
      return;
    }
    final query = await FirebaseFirestore.instance
        .collection('department')
        .where('d_email', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      setState(() {
        _currentDepartmentId = query.docs.first.id;
        _loadingDeptId = false;
      });
    } else {
      setState(() { _loadingDeptId = false; });
    }
  }

  static const List<Widget> _pages = <Widget>[
    _DeptHomePage(),
    ManageEmployees(),
    ManageVisitors(),
    DeptReport(),
    SizedBox.shrink(), // Placeholder for Logout
  ];

  void _onItemTapped(int index) async {
    if (index == 4) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDeptId) {
      return const Scaffold(
        backgroundColor: Color(0xFFD4E9FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFD4E9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CA4FE),
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Department', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
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
            icon: Icon(Icons.people_alt),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Visitors',
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
      body: _selectedIndex == 0
          ? _DeptHomePage(currentDepartmentId: _currentDepartmentId)
          : _pages[_selectedIndex],
    );
  }
}

class _DeptHomePage extends StatelessWidget {
  final String? currentDepartmentId;
  const _DeptHomePage({this.currentDepartmentId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
          // Analytics Header
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
            child: _DeptAnalytics(currentDepartmentId: currentDepartmentId),
          ),
          // Dashboard Card
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/rdl.png', height: 64),
                    const SizedBox(height: 16),
                    const Text('Department Dashboard!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF091016)), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text('Manage your department roles, employees, and visitors efficiently.', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Color(0xFF091016)), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Chip(label: Text('Secure', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                        SizedBox(width: 8),
                        Chip(label: Text('Efficient', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                        SizedBox(width: 8),
                        Chip(label: Text('Professional', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptAnalytics extends StatelessWidget {
  final String? currentDepartmentId;
  const _DeptAnalytics({this.currentDepartmentId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AnalyticsTile(label: 'Roles', icon: Icons.security, collection: 'roles'),
        _AnalyticsTile(label: 'Receptionists', icon: Icons.person, collection: 'receptionist'),
        _AnalyticsTile(label: 'Hosts', icon: Icons.people_alt, collection: 'host', departmentId: currentDepartmentId),
        _AnalyticsTile(label: 'Visitors', icon: Icons.people, collection: 'visitor'),
      ],
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String collection;
  final String? departmentId;
  const _AnalyticsTile({required this.label, required this.icon, required this.collection, this.departmentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF6CA4FE), size: 32),
        const SizedBox(height: 8),
        StreamBuilder<int>(
          stream: _countStream(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('$count', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF091016)));
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Color(0xFF091016))),
      ],
    );
  }

  Stream<int> _countStream() {
    if (collection == 'host' && departmentId != null) {
      return FirebaseFirestore.instance
          .collection('host')
          .where('departmentId', isEqualTo: departmentId)
          .snapshots()
          .map((snap) => snap.docs.length);
    }
    return FirebaseFirestore.instance.collection(collection).snapshots().map((snap) => snap.docs.length);
  }
} 
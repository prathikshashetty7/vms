import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'manage_roles.dart';
import 'manage_employees.dart';
import 'manage_visitors.dart';
import '../logout.dart';
import 'dept_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/dept_theme.dart';

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
    // Pass currentDepartmentId to all subpages
    final List<Widget> _pages = <Widget>[
      _DeptHomePage(currentDepartmentId: _currentDepartmentId),
      ManageEmployees(currentDepartmentId: _currentDepartmentId),
      ManageVisitors(currentDepartmentId: _currentDepartmentId),
      DeptReport(currentDepartmentId: _currentDepartmentId),
      SizedBox.shrink(), // Placeholder for Logout
    ];
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
          // Analytics Header (remove white container)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
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
    return Center(
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: [
          DeptStatCard(
            title: 'Hosts',
            icon: Icons.people_alt,
            valueStream: _countStream('host', currentDepartmentId),
          ),
          DeptStatCard(
            title: 'Visitors',
            icon: Icons.people,
            valueStream: _countStream('visitor', currentDepartmentId),
          ),
        ],
      ),
    );
  }

  Stream<String> _countStream(String collection, String? departmentId) {
    if ((collection == 'host' || collection == 'visitor') && departmentId != null) {
      return FirebaseFirestore.instance
          .collection(collection)
          .where('departmentId', isEqualTo: departmentId)
          .snapshots()
          .map((snap) => snap.docs.length.toString());
    }
    return FirebaseFirestore.instance.collection(collection).snapshots().map((snap) => snap.docs.length.toString());
  }
}

class DeptStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<String> valueStream;

  const DeptStatCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.valueStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF4FF), Color(0xFFD4E9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x226CA4FE),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6CA4FE).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              color: const Color(0xFF6CA4FE),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<String>(
            stream: valueStream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? '0';
              return Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF091016),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 11,
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
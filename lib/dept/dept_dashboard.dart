import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'manage_roles.dart';
import 'manage_employees.dart';
import 'manage_visitors.dart';
import '../logout.dart';
import 'dept_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class DiagonalAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width - 50, size.height);
    path.lineTo(size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DeptDashboard extends StatefulWidget {
  const DeptDashboard({Key? key}) : super(key: key);

  @override
  State<DeptDashboard> createState() => _DeptDashboardState();
}

class _DeptDashboardState extends State<DeptDashboard> {
  int _selectedIndex = 0;
  String? _currentDepartmentId;
  String? _departmentName;
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
        _departmentName = query.docs.first.data()['d_name'] ?? '';
        _loadingDeptId = false;
      });
    } else {
      setState(() { _loadingDeptId = false; });
    }
  }

  void _onItemTapped(int index) async {
    if (index == 4) {
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
    if (_loadingDeptId) {
      return const Scaffold(
        backgroundColor: Color(0xFFD4E9FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Pass currentDepartmentId and departmentName to all subpages
    final List<Widget> _pages = <Widget>[
      _DeptHomePage(currentDepartmentId: _currentDepartmentId, departmentName: _departmentName),
      ManageEmployees(currentDepartmentId: _currentDepartmentId),
      ManageVisitors(currentDepartmentId: _currentDepartmentId),
      DeptReport(currentDepartmentId: _currentDepartmentId),
      SizedBox.shrink(), // Placeholder for Logout
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFD4E9FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + MediaQuery.of(context).padding.top + 20),
        child: Container(
          color: const Color(0xFF6CA4FE),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset('assets/images/rdl.png', height: 42),
                  const SizedBox(width: 12),
                  const Text('Department', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
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
          ? _DeptHomePage(currentDepartmentId: _currentDepartmentId, departmentName: _departmentName)
          : _pages[_selectedIndex],
    );
  }
}

class _DeptHomePage extends StatelessWidget {
  final String? currentDepartmentId;
  final String? departmentName;
  const _DeptHomePage({this.currentDepartmentId, this.departmentName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 88),
          // Dashboard Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/rdl.png', height: 64),
                    const SizedBox(height: 16),
                    Text(
                      departmentName != null && departmentName!.isNotEmpty
                          ? '${departmentName!} Department Dashboard!'
                          : 'Department Dashboard!',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF091016)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text('Manage your department roles, employees, and visitors efficiently.', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Color(0xFF091016)), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        Chip(label: Text('Secure', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                        Chip(label: Text('Efficient', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                        Chip(label: Text('Professional', style: TextStyle(color: Color(0xFF091016))), backgroundColor: Color(0xFF6CA4FE)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Stat Cards (Analytics) before the graph
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: _DeptAnalytics(currentDepartmentId: currentDepartmentId),
          ),
          // Appointments Line Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              color: Colors.white,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Appointments This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, 5),
                                FlSpot(1, 8),
                                FlSpot(2, 6),
                                FlSpot(3, 10),
                                FlSpot(4, 7),
                              ],
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                                  if (value % 1 == 0 && value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(days[value.toInt()]),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                interval: 1,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          minX: 0,
                          maxX: 4,
                          minY: 0,
                        ),
                      ),
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

Widget appointmentsLineChart() {
  final List<FlSpot> mockData = [
    FlSpot(0, 5),
    FlSpot(1, 8),
    FlSpot(2, 6),
    FlSpot(3, 10),
    FlSpot(4, 7),
  ];
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 4,
    color: Colors.white, // Set background to white
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Appointments This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: mockData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Only show label if value is an integer and in range
                        if (value.toInt() >= 0 && value.toInt() < days.length && value == value.toInt()) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()]),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                // Optionally set maxY if you want to control y-axis
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DeptAnalytics extends StatelessWidget {
  final String? currentDepartmentId;
  const _DeptAnalytics({this.currentDepartmentId});

  @override
  Widget build(BuildContext context) {
    final cardList = [
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
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        if (isWide) {
          // On wide screens, show in a row with equal spacing
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cardList
                .map((card) => Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0),
                      child: card,
                    )))
                .toList(),
          );
        } else {
          // On small screens, show in a horizontal scrollable row
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cardList
                  .map((card) => Container(
                        width: 180,
                        margin: const EdgeInsets.symmetric(horizontal: 9.0),
                        child: card,
                      ))
                  .toList(),
            ),
          );
        }
      },
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
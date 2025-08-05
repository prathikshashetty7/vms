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
          // Weekly Department Visitors Chart
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
                    const Text('Weekly Department Visitors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _WeeklyDepartmentVisitorsChart(currentDepartmentId: currentDepartmentId),
                    ),
                  ],
                              ),
                            ),
                          ),
          ),
          // Recent Department Visitors
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Visitors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: _RecentDepartmentVisitorsList(currentDepartmentId: currentDepartmentId),
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

class _WeeklyDepartmentVisitorsChart extends StatelessWidget {
  final String? currentDepartmentId;
  
  const _WeeklyDepartmentVisitorsChart({this.currentDepartmentId});

  @override
  Widget build(BuildContext context) {
    if (currentDepartmentId == null) {
      return const Center(child: Text('Department not found'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('passes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No visitor data available'));
        }

        final passes = snapshot.data!.docs;
        final List<FlSpot> weeklyData = [];
        final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        // Calculate current week's start (Monday)
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        
        // Generate data for each day of the week
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          int dayVisitors = 0;
          
          for (var pass in passes) {
            final data = pass.data() as Map<String, dynamic>;
            final passDepartmentId = data['departmentId'];
            
            // Only count visitors for this specific department
            if (passDepartmentId == currentDepartmentId) {
              final visitDate = data['v_date'];
              if (visitDate != null) {
                try {
                  DateTime parsedDate;
                  
                  if (visitDate is Timestamp) {
                    parsedDate = visitDate.toDate();
                  } else {
                    final dateStr = visitDate.toString();
                    if (dateStr.contains('at')) {
                      final datePart = dateStr.split('at')[0].trim();
                      parsedDate = DateTime.parse(datePart);
                    } else {
                      parsedDate = DateTime.parse(dateStr);
                    }
                  }
                  
                  // Check if it's the same day
                  if (parsedDate.year == day.year && 
                      parsedDate.month == day.month && 
                      parsedDate.day == day.day) {
                    dayVisitors++;
                  }
                } catch (e) {
                  // Skip invalid dates
                }
              }
            }
          }
          
          weeklyData.add(FlSpot(i.toDouble(), dayVisitors.toDouble()));
        }

        return LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                spots: weeklyData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.blue.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                  ),
                ],
                titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                  reservedSize: 32,
                ),
              ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[index],
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
                minX: 0,
            maxX: 6,
                minY: 0,
            maxY: weeklyData.isNotEmpty ? weeklyData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1.0 : 10.0,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blue.shade600,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '${days[barSpot.x.toInt()]}: ${barSpot.y.toInt()} visitors',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentDepartmentVisitorsList extends StatelessWidget {
  final String? currentDepartmentId;
  
  const _RecentDepartmentVisitorsList({this.currentDepartmentId});

  @override
  Widget build(BuildContext context) {
    if (currentDepartmentId == null) {
      return const Center(child: Text('Department not found'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('passes')
          .where('departmentId', isEqualTo: currentDepartmentId)
          .orderBy('v_date', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recent visitors',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final visitors = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: visitors.length,
          itemBuilder: (context, index) {
            final visitor = visitors[index];
            final data = visitor.data() as Map<String, dynamic>;
            final visitDate = data['v_date'];
            
            // Format the date and time properly
            String formattedDateTime = 'N/A';
            if (visitDate != null) {
              try {
                DateTime parsedDate;
                
                if (visitDate is Timestamp) {
                  parsedDate = visitDate.toDate();
                } else {
                  final dateStr = visitDate.toString();
                  if (dateStr.contains('at')) {
                    final datePart = dateStr.split('at')[0].trim();
                    parsedDate = DateTime.parse(datePart);
                  } else {
                    parsedDate = DateTime.parse(dateStr);
                  }
                }
                
                formattedDateTime = '${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}, ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')} ${parsedDate.hour >= 12 ? 'PM' : 'AM'}';
              } catch (e) {
                formattedDateTime = 'N/A';
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Visitor details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['v_name'] ?? 'Unknown Visitor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To meet: ${data['host_name'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Purpose: ${data['purpose'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
                  // Date and time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDateTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manage_departments.dart';
import '../logout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_management.dart';
import 'visitor_management.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'manage_receptionist.dart';
import '../theme/admin_theme.dart';
import '../signin.dart';

// Placeholder screens for other admin features
class AdminStatsDashboard extends StatelessWidget {
  final void Function(int) onCardTap;
  const AdminStatsDashboard({Key? key, required this.onCardTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4B006E), Color(0xFF0F2027), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFB2EBF2)),
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
                      width: 160,
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
                      width: 160,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            _ResponsiveAnalyticsCard(
                title: 'Overview',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: _VisitorTrendsChart(),
                  );
                },
              ),
            ),
          ],
          ),
        ),
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
  final double width;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: width,
        height: 180, // Fixed height for consistency
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
            CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    radius: 24,
                    child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
            Text(
                  value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
            Text(
                  title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                      textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
                ),
              ],
        ),
      ),
    );
  }
}

class _ResponsiveAnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ResponsiveAnalyticsCard({required this.title, required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Very light blue
        borderRadius: BorderRadius.circular(28), // More pronounced rounded corners
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28), // Extra padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _VisitorTrendsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 12)),
                  );
                },
                interval: 1,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 1),
                FlSpot(2, 4),
                FlSpot(3, 2),
                FlSpot(4, 5),
                FlSpot(5, 3),
                FlSpot(6, 4),
              ],
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people, size: 64, color: Colors.deepPurple),
          SizedBox(height: 16),
          Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Manage hosts and receptionists.', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}
class VisitorManagementScreen extends StatelessWidget {
  const VisitorManagementScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.badge, size: 64, color: Colors.deepPurple),
          SizedBox(height: 16),
          Text('Visitor Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Monitor and view all visitors.', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart, size: 64, color: Colors.deepPurple),
          SizedBox(height: 16),
          Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Generate and view reports.', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}

// Add Employee Management screen stub
class EmployeeManagementScreen extends StatelessWidget {
  const EmployeeManagementScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_alt, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Employee Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Manage all employees here.', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _titles = [
    'Admin Dashboard',
    'Manage Departments',
    'Manage Receptionists',
    'View Employees',
    'View Visitors',
    'Reports',
    'Settings'
  ];

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text('Welcome, Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text("Here's what's happening today", style: TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                  builder: (context, constraints) {
                  double cardSpacing = 16;
                  double cardWidth = 200; // Fixed width for each card
                  double cardHeight = 180; // Fixed height for consistency
                  
                  return SizedBox(
                    height: cardHeight + 32, // Add padding for the cards
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            SizedBox(
                            width: cardWidth,
                              child: StreamBuilder(
                              stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
                                builder: (context, AsyncSnapshot snapshot) {
                                  int total = 0;
                                  if (snapshot.hasData) {
                                    total = snapshot.data!.docs.length;
                                  }
                                return Padding(
                                  padding: EdgeInsets.only(right: cardSpacing),
                                  child: _StatCard(
                                    title: 'Visitors Today',
                                    value: total.toString(),
                                    icon: Icons.groups,
                                    color: Colors.deepPurple,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitorManagementPage()));
                                    },
                                    width: cardWidth,
                                  ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                            width: cardWidth,
                              child: StreamBuilder(
                              stream: FirebaseFirestore.instance.collection('visitor').where('status', isEqualTo: 'Checked In').snapshots(),
                              builder: (context, AsyncSnapshot snapshot) {
                                int checkedIn = 0;
                                if (snapshot.hasData) {
                                  checkedIn = snapshot.data!.docs.length;
                                      }
                                return Padding(
                                  padding: EdgeInsets.only(right: cardSpacing),
                                  child: _StatCard(
                                    title: 'Checked-in',
                                    value: checkedIn.toString(),
                                    icon: Icons.how_to_reg,
                                    color: Colors.green,
                                        onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitorManagementPage()));
                                        },
                                    width: cardWidth,
                                  ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(
                            width: cardWidth,
                            child: StreamBuilder(
                              stream: FirebaseFirestore.instance.collection('department').snapshots(),
                              builder: (context, AsyncSnapshot snapshot) {
                                int departments = 0;
                                if (snapshot.hasData) {
                                  departments = snapshot.data!.docs.length;
                                }
                                return Padding(
                                  padding: EdgeInsets.only(right: cardSpacing),
                                  child: _StatCard(
                                    title: 'Departments',
                                    value: departments.toString(),
                                    icon: Icons.apartment,
                                    color: Colors.orange,
                                  onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDepartments()));
                                  },
                                    width: cardWidth,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StreamBuilder(
                              stream: FirebaseFirestore.instance.collection('host').snapshots(),
                              builder: (context, AsyncSnapshot hostSnapshot) {
                                return StreamBuilder(
                                  stream: FirebaseFirestore.instance.collection('receptionist').snapshots(),
                                  builder: (context, AsyncSnapshot recSnapshot) {
                                    int total = 0;
                                    if (hostSnapshot.hasData) {
                                      total += (hostSnapshot.data!.docs.length as int);
                                    }
                                    if (recSnapshot.hasData) {
                                      total += (recSnapshot.data!.docs.length as int);
                                    }
                                    return _StatCard(
                                      title: 'Employees',
                                      value: total.toString(),
                                      icon: Icons.people_alt,
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeManagementPage()));
                                      },
                                      width: cardWidth,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                      );
                  },
              ),
              const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              _ResponsiveAnalyticsCard(
                title: 'Overview',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      child: _VisitorTrendsChart(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5), // Persistent gray color
        iconTheme: const IconThemeData(color: Color(0xFF081735)),
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF081735),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            onPressed: () => _showExitDialog(context),
            tooltip: 'Exit',
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Header section - fixed at top
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2C5364), // Solid blue color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset('assets/images/rdl.png'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('admin@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem(icon: Icons.dashboard, text: 'Admin Dashboard', selected: _selectedIndex == 0, onTap: () => _onSelect(0)),
                    _buildDrawerItem(
                      icon: Icons.business,
                      text: 'Manage Departments',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageDepartments()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.receipt_long,
                      text: 'Manage Receptionist',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageReceptionistPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_alt,
                      text: 'View Employees',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmployeeManagementPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.badge,
                      text: 'View Visitors',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VisitorManagementPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.bar_chart,
                      text: 'Reports',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportsPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      text: 'Settings',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(thickness: 1.2, color: Colors.deepPurple.shade100),
            ),
            const LogoutTile(),
            const SizedBox(height: 8),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AdminTheme.adminBackgroundGradient,
        ),
        child: _screens[_selectedIndex],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Exit'),
          content: const Text('Are you sure you want to exit the application?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required bool selected, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.deepPurple : Colors.black54, size: 20),
      title: Text(
        text, 
        style: TextStyle(
          fontWeight: FontWeight.w500, 
          color: selected ? Colors.deepPurple : Colors.black87,
          fontSize: 14,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.deepPurple.shade50,
      hoverColor: Colors.deepPurple.shade50,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }
} 
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
  String? hostDocId;
  bool loading = true;
  
  // Dashboard statistics
  int visitorsToday = 0;
  int upcomingVisitors = 0;
  int totalPasses = 0;
  int pendingCheckouts = 0;
  
  // Recent activity data
  List<Map<String, dynamic>> recentActivities = [];
  bool loadingActivities = true;

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
      final doc = snap.docs.first;
      final data = doc.data();
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
        hostDocId = doc.id;
        loading = false;
      });
      // Fetch dashboard statistics
      await _fetchDashboardStats(deptId, doc.id, data['emp_name']);
    } else {
      setState(() { loading = false; });
    }
  }

  Future<void> _fetchDashboardStats(String? deptId, String? hostDocId, String? hostName) async {
    if (deptId == null || hostDocId == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    try {
      // 1. Visitors Today for this host - Get all visitors assigned to this host and filter by date
      final allVisitors = await FirebaseFirestore.instance
          .collection('visitor')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .get();
      
      // Filter by today's date
      final todayVisitorsForHost = allVisitors.docs.where((doc) {
        final data = doc.data();
        final vDate = data['v_date'];
        if (vDate == null) return false;
        DateTime visitDate;
        if (vDate is Timestamp) {
          visitDate = vDate.toDate();
        } else if (vDate is DateTime) {
          visitDate = vDate;
        } else {
          return false;
        }
        return visitDate.year == today.year && 
               visitDate.month == today.month && 
               visitDate.day == today.day;
      }).toList();
      
      // 2. Upcoming Appointments (next 7 days) for this host - filter from the same query
      final upcomingVisitorsForHost = allVisitors.docs.where((doc) {
        final data = doc.data();
        final vDate = data['v_date'];
        if (vDate == null) return false;
        DateTime visitDate;
        if (vDate is Timestamp) {
          visitDate = vDate.toDate();
        } else if (vDate is DateTime) {
          visitDate = vDate;
        } else {
          return false;
        }
        return visitDate.isAfter(tomorrow) && visitDate.isBefore(today.add(const Duration(days: 8)));
      }).toList();
      
      // 3. Total Passes generated by this host in current month
      final totalPassesQuery = await FirebaseFirestore.instance
          .collection('passes')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .get();
      
      // Filter passes by current month
      final totalPassesForHost = totalPassesQuery.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['created_at'];
        if (createdAt == null) return false;
        DateTime createdDate;
        if (createdAt is Timestamp) {
          createdDate = createdAt.toDate();
        } else if (createdAt is DateTime) {
          createdDate = createdAt;
        } else {
          return false;
        }
        return createdDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
               createdDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
      
      // 4. Pending Checkouts for today (passes without checkout_code)
      final pendingCheckoutsQuery = await FirebaseFirestore.instance
          .collection('passes')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .get();
      
      // Filter pending checkouts by today's date and no checkout code
      final pendingCheckoutsForHost = pendingCheckoutsQuery.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['created_at'];
        if (createdAt == null) return false;
        DateTime createdDate;
        if (createdAt is Timestamp) {
          createdDate = createdAt.toDate();
        } else if (createdAt is DateTime) {
          createdDate = createdAt;
        } else {
          return false;
        }
        final isToday = createdDate.year == today.year && 
                       createdDate.month == today.month && 
                       createdDate.day == today.day;
        final hasNoCheckout = data['checkout_code'] == null || 
                             data['checkout_code'].toString().isEmpty;
        return isToday && hasNoCheckout;
      }).toList();
      
      final pendingCheckoutsCount = pendingCheckoutsForHost.length;
      
      setState(() {
        visitorsToday = todayVisitorsForHost.length;
        upcomingVisitors = upcomingVisitorsForHost.length;
        totalPasses = totalPassesForHost.length;
        pendingCheckouts = pendingCheckoutsCount;
      });
      
      // Debug logging
      print('DEBUG: Dashboard Stats for Host $hostName (ID: $hostDocId):');
      print('  - Total visitors found: ${allVisitors.docs.length}');
      print('  - Visitors Today for this host: $visitorsToday');
      print('  - Upcoming Visitors for this host: $upcomingVisitors');
      print('  - Total Passes This Month: $totalPasses');
      print('  - Pending Checkouts: $pendingCheckouts');
      
      // Debug: Show visitor details for troubleshooting
      if (allVisitors.docs.isNotEmpty) {
        print('DEBUG: Sample visitor data:');
        final sampleVisitor = allVisitors.docs.first.data();
        print('  - emp_id: ${sampleVisitor['emp_id']}');
        print('  - departmentId: ${sampleVisitor['departmentId']}');
        print('  - v_name: ${sampleVisitor['v_name']}');
        print('  - v_date: ${sampleVisitor['v_date']}');
      }
      
      // Debug: Show all visitors and their categorization
      print('DEBUG: All visitors for this host:');
      for (final doc in allVisitors.docs) {
        final data = doc.data();
        final vDate = data['v_date'];
        String dateStr = 'Unknown';
        DateTime? visitDate;
        if (vDate != null) {
          if (vDate is Timestamp) {
            visitDate = vDate.toDate();
            dateStr = visitDate.toString();
          } else if (vDate is DateTime) {
            visitDate = vDate;
            dateStr = vDate.toString();
          } else {
            dateStr = vDate.toString();
          }
        }
        
        // Determine category
        String category = 'Unknown';
        if (visitDate != null) {
          if (visitDate.year == today.year && 
              visitDate.month == today.month && 
              visitDate.day == today.day) {
            category = 'TODAY';
          } else if (visitDate.isAfter(tomorrow) && visitDate.isBefore(today.add(const Duration(days: 8)))) {
            category = 'UPCOMING';
          } else {
            category = 'OTHER';
          }
        }
        
        print('  - ${data['v_name']}: emp_id=${data['emp_id']}, v_date=$dateStr, category=$category');
      }
      
      // Debug: Show host information
      print('DEBUG: Host Information:');
      print('  - Host Name: $hostName');
      print('  - Host Document ID: $hostDocId');
      print('  - Department ID: $deptId');
      print('  - Today: $today');
      print('  - Tomorrow: $tomorrow');
      
      // Debug: Show filtered results
      print('DEBUG: Today\'s Visitors (Filtered):');
      for (final doc in todayVisitorsForHost) {
        final data = doc.data();
        final vDate = data['v_date'];
        String dateStr = 'Unknown';
        if (vDate != null) {
          if (vDate is Timestamp) {
            dateStr = vDate.toDate().toString();
          } else if (vDate is DateTime) {
            dateStr = vDate.toString();
          } else {
            dateStr = vDate.toString();
          }
        }
        print('  - TODAY: ${data['v_name']}: v_date=$dateStr');
      }
      
      print('DEBUG: Upcoming Visitors (Filtered):');
      for (final doc in upcomingVisitorsForHost) {
        final data = doc.data();
        final vDate = data['v_date'];
        String dateStr = 'Unknown';
        if (vDate != null) {
          if (vDate is Timestamp) {
            dateStr = vDate.toDate().toString();
          } else if (vDate is DateTime) {
            dateStr = vDate.toString();
          } else {
            dateStr = vDate.toString();
          }
        }
        print('  - UPCOMING: ${data['v_name']}: v_date=$dateStr');
      }
      
      // Fetch recent activities
      await _fetchRecentActivities(hostDocId, deptId);
      
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      // Set default values on error
      setState(() {
        visitorsToday = 0;
        upcomingVisitors = 0;
        totalPasses = 0;
        pendingCheckouts = 0;
      });
    }
  }

  Future<void> _fetchRecentActivities(String? hostDocId, String? deptId) async {
    if (hostDocId == null || deptId == null) {
      setState(() {
        loadingActivities = false;
        recentActivities = [];
      });
      return;
    }

    try {
      List<Map<String, dynamic>> activities = [];
      
      // 1. Fetch new visitor assignments (from visitor collection)
      final visitorQuery = await FirebaseFirestore.instance
          .collection('visitor')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('v_date', descending: true)
          .limit(10)
          .get();
      
      for (final doc in visitorQuery.docs) {
        final data = doc.data();
        final visitorName = data['v_name'] ?? 'Unknown Visitor';
        final visitDate = data['v_date'];
        final purpose = data['purpose'] ?? 'Meeting';
        final company = data['v_company_name'] ?? '';
        
        String timeStr = 'Unknown';
        if (visitDate != null) {
          if (visitDate is Timestamp) {
            final dt = visitDate.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (visitDate is DateTime) {
            timeStr = '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'visitor_assigned',
          'title': 'New visitor assigned',
          'subtitle': '$visitorName from $company - $purpose, $timeStr',
          'icon': Icons.person_add,
          'timestamp': visitDate,
          'visitorName': visitorName,
          'company': company,
          'purpose': purpose,
        });
      }
      
      // 2. Fetch manual registrations assigned to this host
      final manualRegQuery = await FirebaseFirestore.instance
          .collection('manual_registrations')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      for (final doc in manualRegQuery.docs) {
        final data = doc.data();
        final visitorName = data['fullName'] ?? 'Unknown Visitor';
        final timestamp = data['timestamp'];
        final purpose = data['purpose'] ?? 'Meeting';
        final company = data['company'] ?? '';
        
        String timeStr = 'Unknown';
        if (timestamp != null) {
          if (timestamp is Timestamp) {
            final dt = timestamp.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (timestamp is DateTime) {
            timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'manual_registration',
          'title': 'Manual visitor registration',
          'subtitle': '$visitorName from $company - $purpose, $timeStr',
          'icon': Icons.person_add_alt_1,
          'timestamp': timestamp,
          'visitorName': visitorName,
          'company': company,
          'purpose': purpose,
        });
      }
      
      // 3. Fetch recent check-ins and check-outs for this host's visitors
      final checkInOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .orderBy('created_at', descending: true)
          .limit(15)
          .get();
      
      for (final doc in checkInOutQuery.docs) {
        final data = doc.data();
        final visitorId = data['visitor_id'];
        
        if (visitorId != null) {
          // Get visitor details to check if they belong to this host
          final visitorDoc = await FirebaseFirestore.instance
              .collection('visitor')
              .doc(visitorId)
              .get();
          
          if (visitorDoc.exists) {
            final visitorData = visitorDoc.data()!;
            final visitorEmpId = visitorData['emp_id'];
            final visitorDeptId = visitorData['departmentId'];
            
            // Check if this visitor belongs to this host and department
            if (visitorEmpId == hostDocId && visitorDeptId == deptId) {
              final visitorName = visitorData['v_name'] ?? 'Unknown Visitor';
              final status = data['status'] ?? 'Unknown';
              final createdAt = data['created_at'];
              
              String timeStr = 'Unknown';
              if (createdAt != null) {
                if (createdAt is Timestamp) {
                  final dt = createdAt.toDate();
                  timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } else if (createdAt is DateTime) {
                  timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                }
              }
              
              String title = '';
              IconData icon = Icons.person;
              
              if (status.toLowerCase() == 'checked in') {
                title = 'Visitor checked in';
                icon = Icons.login;
              } else if (status.toLowerCase() == 'checked out') {
                title = 'Visitor checked out';
                icon = Icons.logout;
              }
              
              activities.add({
                'type': 'check_in_out',
                'title': title,
                'subtitle': '$visitorName, $timeStr',
                'icon': icon,
                'timestamp': createdAt,
                'visitorName': visitorName,
                'status': status,
              });
            }
          }
        }
      }
      
      // 4. Fetch recent pass creations by this host
      final passesQuery = await FirebaseFirestore.instance
          .collection('passes')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();
      
      for (final doc in passesQuery.docs) {
        final data = doc.data();
        final visitorId = data['visitorId'];
        final createdAt = data['created_at'];
        
        String visitorName = 'Unknown Visitor';
        if (visitorId != null) {
          final visitorDoc = await FirebaseFirestore.instance
              .collection('visitor')
              .doc(visitorId)
              .get();
          
          if (visitorDoc.exists) {
            visitorName = visitorDoc.data()?['v_name'] ?? 'Unknown Visitor';
          }
        }
        
        String timeStr = 'Unknown';
        if (createdAt != null) {
          if (createdAt is Timestamp) {
            final dt = createdAt.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (createdAt is DateTime) {
            timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'pass_created',
          'title': 'Pass created for visitor',
          'subtitle': '$visitorName, $timeStr',
          'icon': Icons.qr_code,
          'timestamp': createdAt,
          'visitorName': visitorName,
        });
      }
      
      // 5. Sort all activities by timestamp (most recent first)
      activities.sort((a, b) {
        final aTimestamp = a['timestamp'];
        final bTimestamp = b['timestamp'];
        
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        
        DateTime aTime, bTime;
        if (aTimestamp is Timestamp) {
          aTime = aTimestamp.toDate();
        } else if (aTimestamp is DateTime) {
          aTime = aTimestamp;
        } else {
          return 1;
        }
        
        if (bTimestamp is Timestamp) {
          bTime = bTimestamp.toDate();
        } else if (bTimestamp is DateTime) {
          bTime = bTimestamp;
        } else {
          return 1;
        }
        
        return bTime.compareTo(aTime); // Most recent first
      });
      
      // 6. Take only the most recent 5 activities for dashboard
      activities = activities.take(5).toList();
      
      setState(() {
        recentActivities = activities;
        loadingActivities = false;
      });
      
      print('DEBUG: Fetched ${activities.length} recent activities');
      for (final activity in activities) {
        print('  - ${activity['title']}: ${activity['subtitle']}');
      }
      
    } catch (e) {
      print('Error fetching recent activities: $e');
      setState(() {
        loadingActivities = false;
        recentActivities = [];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllActivities(String? hostDocId, String? deptId) async {
    if (hostDocId == null || deptId == null) {
      return [];
    }

    try {
      List<Map<String, dynamic>> activities = [];
      
      // 1. Fetch all visitor assignments
      final visitorQuery = await FirebaseFirestore.instance
          .collection('visitor')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('v_date', descending: true)
          .limit(50)
          .get();
      
      for (final doc in visitorQuery.docs) {
        final data = doc.data();
        final visitorName = data['v_name'] ?? 'Unknown Visitor';
        final visitDate = data['v_date'];
        final purpose = data['purpose'] ?? 'Meeting';
        final company = data['v_company_name'] ?? '';
        
        String timeStr = 'Unknown';
        if (visitDate != null) {
          if (visitDate is Timestamp) {
            final dt = visitDate.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (visitDate is DateTime) {
            timeStr = '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'visitor_assigned',
          'title': 'New visitor assigned',
          'subtitle': '$visitorName from $company - $purpose, $timeStr',
          'icon': Icons.person_add,
          'timestamp': visitDate,
          'visitorName': visitorName,
          'company': company,
          'purpose': purpose,
        });
      }
      
      // 2. Fetch all manual registrations
      final manualRegQuery = await FirebaseFirestore.instance
          .collection('manual_registrations')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      for (final doc in manualRegQuery.docs) {
        final data = doc.data();
        final visitorName = data['fullName'] ?? 'Unknown Visitor';
        final timestamp = data['timestamp'];
        final purpose = data['purpose'] ?? 'Meeting';
        final company = data['company'] ?? '';
        
        String timeStr = 'Unknown';
        if (timestamp != null) {
          if (timestamp is Timestamp) {
            final dt = timestamp.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (timestamp is DateTime) {
            timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'manual_registration',
          'title': 'Manual visitor registration',
          'subtitle': '$visitorName from $company - $purpose, $timeStr',
          'icon': Icons.person_add_alt_1,
          'timestamp': timestamp,
          'visitorName': visitorName,
          'company': company,
          'purpose': purpose,
        });
      }
      
      // 3. Fetch all check-ins and check-outs
      final checkInOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();
      
      for (final doc in checkInOutQuery.docs) {
        final data = doc.data();
        final visitorId = data['visitor_id'];
        
        if (visitorId != null) {
          final visitorDoc = await FirebaseFirestore.instance
              .collection('visitor')
              .doc(visitorId)
              .get();
          
          if (visitorDoc.exists) {
            final visitorData = visitorDoc.data()!;
            final visitorEmpId = visitorData['emp_id'];
            final visitorDeptId = visitorData['departmentId'];
            
            if (visitorEmpId == hostDocId && visitorDeptId == deptId) {
              final visitorName = visitorData['v_name'] ?? 'Unknown Visitor';
              final status = data['status'] ?? 'Unknown';
              final createdAt = data['created_at'];
              
              String timeStr = 'Unknown';
              if (createdAt != null) {
                if (createdAt is Timestamp) {
                  final dt = createdAt.toDate();
                  timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } else if (createdAt is DateTime) {
                  timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                }
              }
              
              String title = '';
              IconData icon = Icons.person;
              
              if (status.toLowerCase() == 'checked in') {
                title = 'Visitor checked in';
                icon = Icons.login;
              } else if (status.toLowerCase() == 'checked out') {
                title = 'Visitor checked out';
                icon = Icons.logout;
              }
              
              activities.add({
                'type': 'check_in_out',
                'title': title,
                'subtitle': '$visitorName, $timeStr',
                'icon': icon,
                'timestamp': createdAt,
                'visitorName': visitorName,
                'status': status,
              });
            }
          }
        }
      }
      
      // 4. Fetch all pass creations
      final passesQuery = await FirebaseFirestore.instance
          .collection('passes')
          .where('emp_id', isEqualTo: hostDocId)
          .where('departmentId', isEqualTo: deptId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();
      
      for (final doc in passesQuery.docs) {
        final data = doc.data();
        final visitorId = data['visitorId'];
        final createdAt = data['created_at'];
        
        String visitorName = 'Unknown Visitor';
        if (visitorId != null) {
          final visitorDoc = await FirebaseFirestore.instance
              .collection('visitor')
              .doc(visitorId)
              .get();
          
          if (visitorDoc.exists) {
            visitorName = visitorDoc.data()?['v_name'] ?? 'Unknown Visitor';
          }
        }
        
        String timeStr = 'Unknown';
        if (createdAt != null) {
          if (createdAt is Timestamp) {
            final dt = createdAt.toDate();
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } else if (createdAt is DateTime) {
            timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
          }
        }
        
        activities.add({
          'type': 'pass_created',
          'title': 'Pass created for visitor',
          'subtitle': '$visitorName, $timeStr',
          'icon': Icons.qr_code,
          'timestamp': createdAt,
          'visitorName': visitorName,
        });
      }
      
      // 5. Sort all activities by timestamp (most recent first)
      activities.sort((a, b) {
        final aTimestamp = a['timestamp'];
        final bTimestamp = b['timestamp'];
        
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        
        DateTime aTime, bTime;
        if (aTimestamp is Timestamp) {
          aTime = aTimestamp.toDate();
        } else if (aTimestamp is DateTime) {
          aTime = aTimestamp;
        } else {
          return 1;
        }
        
        if (bTimestamp is Timestamp) {
          bTime = bTimestamp.toDate();
        } else if (bTimestamp is DateTime) {
          bTime = bTimestamp;
        } else {
          return 1;
        }
        
        return bTime.compareTo(aTime);
      });
      
      return activities;
    } catch (e) {
      print('Error fetching all activities: $e');
      return [];
    }
  }

  void _showAllActivitiesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFF6CA4FE)),
                  const SizedBox(width: 8),
                  const Text(
                    'All Recent Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF091016),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAllActivities(hostDocId, hostDeptId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recent activity found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _ActivityItem(
                          icon: activity['icon'] ?? Icons.person,
                          title: activity['title'] ?? 'Activity',
                          subtitle: activity['subtitle'] ?? 'Unknown',
                        );
                      },
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
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() { loading = true; });
          await _fetchHostDetails();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          SizedBox(height: 32),
          // Welcome Card with Refresh Button
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
                    children: [
                      _StyledStatCard(
                        title: 'Visitors Today', 
                        value: loading ? '...' : visitorsToday.toString(), 
                        icon: Icons.groups,
                        isLoading: loading,
                      ),
                      _StyledStatCard(
                        title: 'Upcoming Appointments', 
                        value: loading ? '...' : upcomingVisitors.toString(), 
                        icon: Icons.event,
                        isLoading: loading,
                      ),
                      _StyledStatCard(
                        title: 'Passes This Month', 
                        value: loading ? '...' : totalPasses.toString(), 
                        icon: Icons.qr_code,
                        isLoading: loading,
                      ),
                      _StyledStatCard(
                        title: 'Pending Checkouts', 
                        value: loading ? '...' : pendingCheckouts.toString(), 
                        icon: Icons.logout,
                        isLoading: loading,
                      ),
                    ],
                  );
                } else {
                  // Wide: 1 row of 4
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _StyledStatCard(
                        title: 'Visitors Today', 
                        value: loading ? '...' : visitorsToday.toString(), 
                        icon: Icons.groups,
                        isLoading: loading,
                      )),
                      const SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(
                        title: 'Upcoming Appointments', 
                        value: loading ? '...' : upcomingVisitors.toString(), 
                        icon: Icons.event,
                        isLoading: loading,
                      )),
                      const SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(
                        title: 'Passes This Month', 
                        value: loading ? '...' : totalPasses.toString(), 
                        icon: Icons.qr_code,
                        isLoading: loading,
                      )),
                      const SizedBox(width: 18),
                      Expanded(child: _StyledStatCard(
                        title: 'Pending Checkouts', 
                        value: loading ? '...' : pendingCheckouts.toString(), 
                        icon: Icons.logout,
                        isLoading: loading,
                      )),
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
                         onPressed: () => _showAllActivitiesDialog(),
                         child: Text('See more', style: TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
                       ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (loadingActivities)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CA4FE)),
                        ),
                      ),
                    )
                  else if (recentActivities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No recent activity',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ...recentActivities.map((activity) {
                      return Column(
                        children: [
                          _ActivityItem(
                            icon: activity['icon'] ?? Icons.person,
                            title: activity['title'] ?? 'Activity',
                            subtitle: activity['subtitle'] ?? 'Unknown',
                          ),
                          if (activity != recentActivities.last)
                            const Divider(height: 18, color: Color(0xFFE0E0E0)),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
        ),
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
  final bool isLoading;

  const _StyledStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isLoading = false,
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
          isLoading 
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CA4FE)),
                ),
              )
            : Text(
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
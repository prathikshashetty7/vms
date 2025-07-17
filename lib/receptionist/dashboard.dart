import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/stat_card.dart';
import '../signin.dart';
import 'dart:ui';
import 'manual_entry_page.dart';
import 'receptionist_reports_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  int _selectedIndex = 0;
  String? receptionistName;
  bool _loadingReceptionist = true;

  @override
  void initState() {
    super.initState();
    _fetchReceptionistName();
  }

  Future<void> _fetchReceptionistName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingReceptionist = false;
      });
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('receptionist')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        receptionistName = data['name'] ?? user.email;
        _loadingReceptionist = false;
      });
    } else {
      setState(() {
        _loadingReceptionist = false;
      });
    }
  }

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
      Navigator.pushReplacementNamed(context, '/receptionist_reports');
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VisitorsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/manual_entry');
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
            icon: Icon(Icons.people_alt_rounded),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_rounded),
            label: 'Checked In',
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
                          _loadingReceptionist
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  'Welcome, ' + (receptionistName ?? 'Receptionist'),
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
              // Stat cards section moved here
              const SizedBox(height: 4), // Reduced space after header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _TodayVisitorsStatCard()),
                          const SizedBox(width: 18),
                          Expanded(child: _StyledStatCard(title: 'Checked In', value: '8', icon: Icons.login)),
                          const SizedBox(width: 18),
                          Expanded(child: _StyledStatCard(title: 'Checked Out', value: '4', icon: Icons.logout)),
                          const SizedBox(width: 18),
                          Expanded(child: _FrequentVisitorsStatCard()),
                        ],
                      );
                    } else {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.95,
                        children: [
                          _TodayVisitorsStatCard(),
                          _StyledStatCard(title: 'Checked In', value: '8', icon: Icons.login),
                          _StyledStatCard(title: 'Checked Out', value: '4', icon: Icons.logout),
                          _FrequentVisitorsStatCard(),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              // Activity List (now after stat cards)
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
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) => const _AllActivityListSheet(),
                              );
                            },
                            child: Text('See more', style: TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      _ActivityListWidget(limit: 3),
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
        color: Colors.white, // Changed from gradient to solid white
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
  final ScrollController? scrollController;
  const _ActivityListWidget({this.limit = 3, this.scrollController, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Fetch more items than needed, then limit in Dart
    final manualStream = FirebaseFirestore.instance
        .collection('manual_registrations')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots();
    final deptStream = FirebaseFirestore.instance
        .collection('visitor')
        .orderBy('v_date', descending: true)
        .limit(30)
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
            final latest = limit > 0 ? allDocs.take(limit).toList() : allDocs;
            if (latest.isEmpty) {
              return const Text('No recent activity.', style: TextStyle(color: Color(0xFF6CA4FE)));
            }
            if (scrollController != null) {
              return ListView.separated(
                controller: scrollController,
                itemCount: latest.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
                itemBuilder: (context, i) => _ActivityListTile(entry: latest[i]),
              );
            } else {
              // For dashboard, use Column for tight fit
              return Column(
                children: [
                  for (int i = 0; i < latest.length; i++) ...[
                    if (i != 0)
                      const Divider(height: 1, color: Color(0xFFD4E9FF)),
                    _ActivityListTile(entry: latest[i]),
                  ]
                ],
              );
            }
          },
        );
      },
    );
  }
}

class _AllActivityListSheet extends StatelessWidget {
  const _AllActivityListSheet({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                child: _ActivityListWidget(limit: 30, scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper widget for activity list tile
class _ActivityListTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _ActivityListTile({required this.entry, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.person, color: Color(0xFF6CA4FE)),
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', fontSize: 14)),
      subtitle: time != null ? Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}  ${time.day}/${time.month}/${time.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))) : null,
    );
  }
}

// Widget for real-time count of today's visitors
class _TodayVisitorsStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final manualStream = FirebaseFirestore.instance
        .collection('manual_registrations')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .snapshots();
    final deptStream = FirebaseFirestore.instance
        .collection('visitor')
        .where('v_date', isGreaterThanOrEqualTo: startOfDay)
        .where('v_date', isLessThan: endOfDay)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: manualStream,
      builder: (context, manualSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: deptStream,
          builder: (context, deptSnapshot) {
            int manualCount = manualSnapshot.hasData ? manualSnapshot.data!.docs.length : 0;
            int deptCount = deptSnapshot.hasData ? deptSnapshot.data!.docs.length : 0;
            int total = manualCount + deptCount;
            return _StyledStatCard(
              title: 'Total Visitors Today',
              value: total.toString(),
              icon: Icons.people,
            );
          },
        );
      },
    );
  }
}

// Widget for real-time count of frequent visitors this week
class _FrequentVisitorsStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final manualStream = FirebaseFirestore.instance
        .collection('manual_registrations')
        .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
        .where('timestamp', isLessThan: endOfWeek)
        .snapshots();
    final deptStream = FirebaseFirestore.instance
        .collection('visitor')
        .where('v_date', isGreaterThanOrEqualTo: startOfWeek)
        .where('v_date', isLessThan: endOfWeek)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: manualStream,
      builder: (context, manualSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: deptStream,
          builder: (context, deptSnapshot) {
            final Map<String, int> visitorCounts = {};
            if (manualSnapshot.hasData) {
              for (var doc in manualSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['fullName'] ?? data['visitor'] ?? '';
                if (name.isNotEmpty) {
                  visitorCounts[name] = (visitorCounts[name] ?? 0) + 1;
                }
              }
            }
            if (deptSnapshot.hasData) {
              for (var doc in deptSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['v_name'] ?? '';
                if (name.isNotEmpty) {
                  visitorCounts[name] = (visitorCounts[name] ?? 0) + 1;
                }
              }
            }
            final frequentCount = visitorCounts.values.where((count) => count > 1).length;
            return _StyledStatCard(
              title: 'Frequent Visitors',
              value: frequentCount.toString(),
              icon: Icons.repeat,
            );
          },
        );
      },
    );
  }
}

class VisitorsPage extends StatelessWidget {
  const VisitorsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Visitors'),
        backgroundColor: Color(0xFF6CA4FE),
      ),
      backgroundColor: Color(0xFFD4E9FF),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('visitor').orderBy('v_date', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No visitors found.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['v_name'] ?? 'Unknown';
              final status = data['checked_out'] == true ? 'Checked Out' : 'Checked In';
              final date = data['v_date'] is Timestamp ? (data['v_date'] as Timestamp).toDate() : null;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    status == 'Checked In' ? Icons.login : Icons.logout,
                    color: status == 'Checked In' ? Colors.green : Colors.red,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : ''),
                  trailing: Text(status, style: TextStyle(color: status == 'Checked In' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 2,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/receptionist_reports');
          } else if (index == 2) {
            // Already here (Checked In)
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
            label: 'Checked In',
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
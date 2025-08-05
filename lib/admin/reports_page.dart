import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _range = 'Weekly';
  final List<String> _ranges = ['Weekly', 'Monthly', 'Yearly'];
  int? _selectedStatIndex = 0; // Default to show Visitors Over Time graph

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF081735)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 40),
            const SizedBox(width: 10),
            const Text('Reports', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Comprehensive visitor insights and analytics',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 24),
              _buildStatisticsCards(isWide),
              if (_selectedStatIndex != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedStatIndex == 2 ? 'Average Visit Duration' : 'Visitors Over Time',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (!(_selectedStatIndex == 0))
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedStatIndex = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _TrendsChart(range: _range, startWithMonday: true),
                      ),
                    ],
                  ),
                ),
              ],


              const SizedBox(height: 24),

              const SizedBox(height: 24),
              _ReportCard(
                title: 'Recent Visitors',
                subtitle: '',
                child: _RecentVisitorsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No visitor data available',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        final visitors = snapshot.data!.docs;
        print('Total visitors found: ${visitors.length}');
        
        // Debug: Print first visitor data structure
        if (visitors.isNotEmpty) {
          final firstVisitor = visitors.first.data() as Map<String, dynamic>;
          print('First visitor data: $firstVisitor');
        }
        
        final totalVisitors = visitors.length;
        // Calculate today's visitors
        int todayVisitors = 0;
        final today = DateTime.now();
        print('Today\'s date: ${today.day}/${today.month}/${today.year}');
        
        for (var doc in visitors) {
          final data = doc.data() as Map<String, dynamic>;
          final visitDate = data['v_date'];
          
          if (visitDate != null) {
            print('Processing visit date: $visitDate (type: ${visitDate.runtimeType})');
            try {
              DateTime parsedDate;
              
              if (visitDate is Timestamp) {
                parsedDate = visitDate.toDate();
                print('Parsed Timestamp: ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}');
              } else {
                final dateStr = visitDate.toString();
                print('Processing date string: $dateStr');
                
                if (dateStr.contains('at')) {
                  final datePart = dateStr.split('at')[0].trim();
                  print('Date part after "at": $datePart');
                  parsedDate = DateFormat('d MMMM yyyy').parse(datePart);
                } else if (dateStr.contains('Timestamp')) {
                  // Handle string representation of timestamp
                  final timestampMatch = RegExp(r'Timestamp\(seconds=(\d+), nanoseconds=(\d+)\)').firstMatch(dateStr);
                  if (timestampMatch != null) {
                    final seconds = int.parse(timestampMatch.group(1)!);
                    parsedDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                    print('Parsed timestamp string: ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}');
                  } else {
                    print('Could not parse timestamp string: $dateStr');
                    continue;
                  }
                } else {
                  // Try different date formats
                  try {
                    parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
                  } catch (e) {
                    try {
                      parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
                    } catch (e2) {
                      try {
                        parsedDate = DateFormat('dd/MM/yyyy').parse(dateStr);
                      } catch (e3) {
                        print('Could not parse date string: $dateStr');
                        continue;
                      }
                    }
                  }
                }
                print('Parsed date: ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}');
              }
              
              // Check if it's today
              if (parsedDate.year == today.year && 
                  parsedDate.month == today.month && 
                  parsedDate.day == today.day) {
                todayVisitors++;
                print('Found today\'s visitor! Total today: $todayVisitors');
              }
            } catch (e) {
              print('Error parsing date: $e for date: $visitDate');
            }
          } else {
            print('Visit date is null for document: ${doc.id}');
          }
        }
        
        print('Final today\'s visitors count: $todayVisitors');

        final cards = [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatIndex = 0;
              });
            },
            child: _StatCard(
              title: 'Total Visitors',
              value: totalVisitors.toString(),
              icon: Icons.people,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatIndex = 1;
              });
            },
            child: _StatCard(
              title: "Today's Visitors",
              value: todayVisitors.toString(),
              icon: Icons.today,
              color: Colors.white,
            ),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 24),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 24),
                  SizedBox(width: 220, child: cards[i]),
                ],
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _range,
          isDense: true,
          items: _ranges.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _range = newValue;
              });
            }
          },
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: const TextStyle(color: Colors.black),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              Icon(icon, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              trailing: action,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendsChart extends StatelessWidget {
  final String range;
  final bool startWithMonday;

  const _TrendsChart({required this.range, required this.startWithMonday});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading data: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final visitors = snapshot.data!.docs;
        List<FlSpot> spots = [];
        int interval = 1;

        String bottomTitleLogic(double value) {
          DateTime date;
          if (range == 'Weekly') {
            int weekdayIndex = value.toInt();
            if (startWithMonday) {
              const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return weekDays[weekdayIndex % 7];
            } else {
              date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
              return DateFormat('EEE').format(date);
            }
          } else if (range == 'Monthly') {
            return 'W${value.toInt() + 1}';
          } else {
            date = DateTime(DateTime.now().year, value.toInt() + 1, 1);
            return DateFormat('MMM').format(date);
          }
        }

        // Calculate real data based on range
        if (range == 'Weekly') {
          final now = DateTime.now();
          final weekStart = startWithMonday 
              ? now.subtract(Duration(days: now.weekday - 1))
              : now.subtract(Duration(days: now.weekday));
          
          spots = List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            int dayVisitors = 0;
            
            for (var doc in visitors) {
              final data = doc.data() as Map<String, dynamic>;
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
                      parsedDate = DateFormat('d MMMM yyyy').parse(datePart);
                    } else {
                      parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
                    }
                  }
                  
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
            
            return FlSpot(index.toDouble(), dayVisitors.toDouble());
          });
          interval = 1;
        } else if (range == 'Monthly') {
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final weeksInMonth = ((monthStart.add(Duration(days: 32)).day - 1) / 7).ceil();
          
          spots = List.generate(weeksInMonth, (index) {
            final weekStart = monthStart.add(Duration(days: index * 7));
            final weekEnd = weekStart.add(const Duration(days: 6));
            int weekVisitors = 0;
            
            for (var doc in visitors) {
              final data = doc.data() as Map<String, dynamic>;
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
                      parsedDate = DateFormat('d MMMM yyyy').parse(datePart);
                    } else {
                      parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
                    }
                  }
                  
                  if (parsedDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                      parsedDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
                    weekVisitors++;
                  }
                } catch (e) {
                  // Skip invalid dates
                }
              }
            }
            
            return FlSpot(index.toDouble(), weekVisitors.toDouble());
          });
          interval = 1;
        } else if (range == 'Yearly') {
          spots = List.generate(12, (index) {
            final month = index + 1;
            int monthVisitors = 0;
            
            for (var doc in visitors) {
              final data = doc.data() as Map<String, dynamic>;
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
                      parsedDate = DateFormat('d MMMM yyyy').parse(datePart);
                    } else {
                      parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
                    }
                  }
                  
                  if (parsedDate.year == DateTime.now().year && parsedDate.month == month) {
                    monthVisitors++;
                  }
                } catch (e) {
                  // Skip invalid dates
                }
              }
            }
            
            return FlSpot(index.toDouble(), monthVisitors.toDouble());
          });
          interval = 1;
        }

        if (spots.isEmpty) {
          return const Center(child: Text('No data available for selected range'));
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: interval.toDouble(),
              verticalInterval: 1.0,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        bottomTitleLogic(value),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.black, width: 1),
            ),
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: 0,
                         maxY: spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1.0 : 10.0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue.shade600,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400.withOpacity(0.3),
                      Colors.blue.shade600.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blue.shade600,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '${bottomTitleLogic(barSpot.x)}: ${barSpot.y.toInt()} visitors',
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

class _AverageDurationPieChart extends StatelessWidget {
  const _AverageDurationPieChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final visitors = snapshot.data!.docs;
            final Map<String, List<int>> deptDurations = {};
        for (var visitor in visitors) {
          final data = visitor.data() as Map<String, dynamic>;
          final dept = data['departmentId'] ?? 'Unknown';
          // Since we don't have check-in/check-out times, we'll use a default duration
          final duration = 60; // Default 60 minutes per visit
          if (!deptDurations.containsKey(dept)) {
            deptDurations[dept] = [];
          }
          deptDurations[dept]!.add(duration);
        }

    final Map<String, double> avgDeptDurations = {};
    deptDurations.forEach((dept, durations) {
      avgDeptDurations[dept] = durations.reduce((a, b) => a + b) / durations.length;
    });

    final pieChartSections = avgDeptDurations.entries.map((entry) {
      final color = Colors.primaries[avgDeptDurations.keys.toList().indexOf(entry.key) % Colors.primaries.length];
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n${entry.value.round()} min',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartSections,
        sectionsSpace: 4,
        centerSpaceRadius: 40,
      ),
        );
      },
    );
  }
}

class _AxisLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    // X axis line
    canvas.drawLine(
      Offset(18, size.height - 8),
      Offset(size.width, size.height - 8),
      paint,
    );
    // Y axis line
    canvas.drawLine(
      Offset(18, size.height - 8),
      Offset(18, 0),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}





class _RecentVisitorsList extends StatelessWidget {
  const _RecentVisitorsList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('passes').orderBy('v_date', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final visitors = snapshot.data!.docs;
        return FutureBuilder<List<QuerySnapshot>>(
          future: Future.wait([
            FirebaseFirestore.instance.collection('department').get(),
            FirebaseFirestore.instance.collection('host').get(),
          ]),
          builder: (context, collectionsSnapshot) {
            if (collectionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<String, String> deptNames = {};
            final Map<String, String> hostNames = {};

                         if (collectionsSnapshot.hasData && collectionsSnapshot.data!.length >= 2) {
               // Process department names
              print('Processing departments...');
               for (var doc in collectionsSnapshot.data![0].docs) {
                 final data = doc.data() as Map<String, dynamic>;
                print('Department doc ID: ${doc.id}, data: $data');
                 final deptName = data['name'] ?? 
                                 data['department_name'] ?? 
                                 data['dept_name'] ?? 
                                 data['title'] ?? 
                                 data['departmentName'] ??
                                data['deptName'] ??
                                 'Unknown';
                 deptNames[doc.id] = deptName;
                print('Added department: ${doc.id} -> $deptName');
               }
              print('Total departments loaded: ${deptNames.length}');
              
               // Process host names
              print('Processing hosts...');
               for (var doc in collectionsSnapshot.data![1].docs) {
                 final data = doc.data() as Map<String, dynamic>;
                print('Host doc ID: ${doc.id}, data: $data');
                 final hostName = data['name'] ?? 
                                 data['host_name'] ?? 
                                 data['employee_name'] ?? 
                                 data['emp_name'] ?? 
                                 data['title'] ?? 
                                 data['hostName'] ??
                                 data['employeeName'] ??
                                 'Unknown';
                 hostNames[doc.id] = hostName;
                print('Added host: ${doc.id} -> $hostName');
               }
              print('Total hosts loaded: ${hostNames.length}');
             }

        return SizedBox(
              height: 260,
          child: ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              final data = visitor.data() as Map<String, dynamic>;
              final visitDate = data['v_date'];
              final visitTime = data['v_time'];
              
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
                      parsedDate = DateFormat('d MMMM yyyy').parse(datePart);
                    } else {
                      parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);
                    }
                  }
                  
                  // Format time if available
                  String timeStr = 'N/A';
                  if (visitTime != null) {
                    if (visitTime is Timestamp) {
                      timeStr = DateFormat('h:mm a').format(visitTime.toDate());
                    } else {
                      timeStr = visitTime.toString();
                    }
                  }
                  
                  final cleanDate = DateFormat('d MMM yyyy').format(parsedDate);
                  formattedDateTime = '$cleanDate, $timeStr';
                } catch (e) {
                  formattedDateTime = 'N/A';
                }
              }

                  // Get department and employee IDs from passes collection
              final deptId = data['departmentId'];
              final empId = data['emp_id'];
                  
                  // Debug logging
                  print('=== Passes Collection Debug Info ===');
                  print('Visitor name: ${data['v_name']}');
                  print('Department: ${data['department']}');
                  print('Host name: ${data['host_name']}');
                  print('Purpose: ${data['purpose']}');
                  print('Pass number: ${data['pass_no']}');
                  print('All passes data keys: ${data.keys.toList()}');
                  print('========================');
              
              return _VisitorListItem(
                visitor: {
                  'name': data['v_name'] ?? 'N/A',
                      'department': data['department'] ?? 'N/A', // Use department name directly from passes
                      'host_name': data['host_name'] ?? 'N/A', // Use host name directly from passes
                  'time_in': visitDate,
                  'time_out': null,
                  'purpose': data['purpose'] ?? 'N/A',
                  'phone': data['v_contactno'] ?? 'N/A',
                  'formatted_time': formattedDateTime,
                },
              );
            },
          ),
        );
          },
        );
      },
    );
  }
}

class _VisitorListItem extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const _VisitorListItem({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final formattedTime = visitor['formatted_time'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(visitor['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To meet: ${visitor['host_name']}'),
            Text('Department: ${visitor['department']}'),
            Text('Purpose: ${visitor['purpose']}'),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
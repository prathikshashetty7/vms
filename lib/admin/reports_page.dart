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

  final List<Map<String, dynamic>> _dummyVisitors = [
    {
      'name': 'Amit Sharma',
      'department': 'IT',
      'host_name': 'Priya Singh',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'purpose': 'Meeting',
      'phone': '+919876543210',
    },
    {
      'name': 'Sneha Patel',
      'department': 'HR',
      'host_name': 'Rahul Verma',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'purpose': 'Interview',
      'phone': '+919876543211',
    },
    {
      'name': 'Rohit Kumar',
      'department': 'Marketing',
      'host_name': 'Anjali Mehta',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
      'purpose': 'Presentation',
      'phone': '+919876543212',
    },
    {
      'name': 'Lakshmi Nair',
      'department': 'Finance',
      'host_name': 'Vikram Joshi',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 8))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
      'purpose': 'Budget Review',
      'phone': '+919876543213',
    },
    {
      'name': 'Arjun Reddy',
      'department': 'IT',
      'host_name': 'Priya Singh',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 10))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 8))),
      'purpose': 'System Demo',
      'phone': '+919876543214',
    },
    {
      'name': 'Meera Desai',
      'department': 'Operations',
      'host_name': 'Suresh Menon',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 10))),
      'purpose': 'Process Review',
      'phone': '+919876543215',
    },
    {
      'name': 'Vikas Gupta',
      'department': 'Marketing',
      'host_name': 'Anjali Mehta',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 14))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
      'purpose': 'Campaign Planning',
      'phone': '+919876543216',
    },
    {
      'name': 'Pooja Iyer',
      'department': 'HR',
      'host_name': 'Rahul Verma',
      'time_in': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 16))),
      'time_out': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 14))),
      'purpose': 'Training Session',
      'phone': '+919876543217',
    },
  ];

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
                        child: _selectedStatIndex == 2
                          ? _AverageDurationPieChart(dummyData: _dummyVisitors)
                          : _TrendsChart(range: _range, startWithMonday: true),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Department-wise Visits',
                subtitle: 'Total visitors per department',
                child: _DepartmentVisitorBarChart(dummyData: _dummyVisitors),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Host-wise Visitor Stats',
                subtitle: 'Total number of visitors per host',
                child: _HostVisitorBarChart(dummyData: _dummyVisitors),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Average Visit Duration',
                subtitle: 'Average time spent by department',
                child: _AverageDurationPieChart(dummyData: _dummyVisitors),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Recent Visitors',
                subtitle: 'Latest visitor entries',
                child: _RecentVisitorsList(dummyData: _dummyVisitors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(bool isWide) {
    final totalVisitors = _dummyVisitors.length;
    final today = DateTime.now();
    final todayVisitorsList = _dummyVisitors.where((v) {
      final visitDate = (v['time_in'] as Timestamp).toDate();
      return visitDate.year == today.year && visitDate.month == today.month && visitDate.day == today.day;
    }).toList();
    final todayVisitors = todayVisitorsList.length;
    final avgTodayDuration = todayVisitorsList.isNotEmpty
        ? todayVisitorsList.fold(0.0, (sum, v) {
              final timeIn = (v['time_in'] as Timestamp).toDate();
              final timeOut = (v['time_out'] as Timestamp).toDate();
              return sum + timeOut.difference(timeIn).inMinutes;
            }) /
            todayVisitorsList.length
        : 0.0;

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
      GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatIndex = 2;
          });
        },
        child: _StatCard(
          title: 'Average Visit Duration',
          value: '${avgTodayDuration.round()} min',
          icon: Icons.access_time,
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

  const _TrendsChart({required this.range, this.startWithMonday = false});

  @override
  Widget build(BuildContext context) {
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

    if (range == 'Weekly') {
      if (startWithMonday) {
        spots = [
          const FlSpot(0, 6),
          const FlSpot(1, 3),
          const FlSpot(2, 5),
          const FlSpot(3, 4),
          const FlSpot(4, 6),
          const FlSpot(5, 5),
          const FlSpot(6, 7),
        ];
      } else {
        spots = [
          const FlSpot(0, 3), const FlSpot(1, 5), const FlSpot(2, 4), const FlSpot(3, 6),
          const FlSpot(4, 5), const FlSpot(5, 7), const FlSpot(6, 6),
        ];
      }
      interval = 1;
    } else if (range == 'Monthly') {
      spots = [
        const FlSpot(0, 15), const FlSpot(1, 25), const FlSpot(2, 20), const FlSpot(3, 30),
      ];
      interval = 1;
    } else if (range == 'Yearly') {
      spots = [
        const FlSpot(0, 150), const FlSpot(1, 200), const FlSpot(2, 180),
        const FlSpot(3, 250), const FlSpot(4, 230), const FlSpot(5, 280),
        const FlSpot(6, 260), const FlSpot(7, 300), const FlSpot(8, 290),
        const FlSpot(9, 320), const FlSpot(10, 310), const FlSpot(11, 340),
      ];
      interval = 1;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval.toDouble(),
              getTitlesWidget: (value, meta) {
                return Text(bottomTitleLogic(value));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Color(0xFF78909C),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  touchedSpot.y.toInt().toString(),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _AverageDurationPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> dummyData;

  const _AverageDurationPieChart({required this.dummyData});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<int>> deptDurations = {};
    for (var visitor in dummyData) {
      final dept = visitor['department'] ?? 'Unknown';
      final timeIn = (visitor['time_in'] as Timestamp).toDate();
      final timeOut = (visitor['time_out'] as Timestamp).toDate();
      final duration = timeOut.difference(timeIn).inMinutes;
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

class _DepartmentVisitorBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dummyData;
  const _DepartmentVisitorBarChart({required this.dummyData});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> deptCounts = {};
    for (var visitor in dummyData) {
      final dept = visitor['department'] ?? 'Unknown';
      deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
    }

    if (deptCounts.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final depts = deptCounts.keys.toList();
    final counts = deptCounts.values.toList();

    final List<Color> barColors = [
      Colors.lightBlue.shade300,
      Colors.blue.shade700,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.pink.shade300,
    ];

    // Minimum width: 90px per bar, at least screen width
    final minChartWidth = (depts.length * 90.0).clamp(MediaQuery.of(context).size.width, double.infinity);
    final labelFontSize = MediaQuery.of(context).size.width < 400 ? 12.0 : 14.0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minChartWidth,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Color(0xFF78909C),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${depts[groupIndex]}\n${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < depts.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: SizedBox(
                                  width: 90,
                                  child: Text(
                                    depts[index],
                                    style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    softWrap: true,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 56,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black, width: 1),
                        bottom: BorderSide(color: Colors.black, width: 1),
                        right: BorderSide(color: Colors.transparent, width: 0),
                        top: BorderSide(color: Colors.transparent, width: 0),
                      ),
                    ),
                    barGroups: List.generate(
                      depts.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            color: barColors[i % barColors.length],
                            width: 40,
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                            backDrawRodData: BackgroundBarChartRodData(show: false),
                          )
                        ],
                        barsSpace: 8,
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1)),
                    alignment: BarChartAlignment.spaceEvenly,
                    groupsSpace: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HostVisitorBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dummyData;
  const _HostVisitorBarChart({required this.dummyData});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> hostCounts = {};
    for (var visitor in dummyData) {
      final host = visitor['host_name'] ?? 'Unknown';
      hostCounts[host] = (hostCounts[host] ?? 0) + 1;
    }

    if (hostCounts.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final hosts = hostCounts.keys.toList();
    final counts = hostCounts.values.toList();

    final List<Color> barColors = [
      Colors.deepPurple.shade300,
      Colors.indigo.shade400,
      Colors.cyan.shade400,
      Colors.amber.shade400,
      Colors.red.shade300,
    ];

    // Minimum width: 90px per bar, at least screen width
    final minChartWidth = (hosts.length * 90.0).clamp(MediaQuery.of(context).size.width, double.infinity);
    final labelFontSize = MediaQuery.of(context).size.width < 400 ? 12.0 : 14.0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minChartWidth,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Color(0xFF78909C),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${hosts[groupIndex]}\n${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < hosts.length) {
                              final firstName = hosts[index].split(' ').first;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: SizedBox(
                                  width: 90,
                                  child: Text(
                                    firstName,
                                    style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    softWrap: true,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 56,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black, width: 1),
                        bottom: BorderSide(color: Colors.black, width: 1),
                        right: BorderSide(color: Colors.transparent, width: 0),
                        top: BorderSide(color: Colors.transparent, width: 0),
                      ),
                    ),
                    barGroups: List.generate(
                      hosts.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            color: barColors[i % barColors.length],
                            width: 40,
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                            backDrawRodData: BackgroundBarChartRodData(show: false),
                          )
                        ],
                        barsSpace: 8,
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1)),
                    alignment: BarChartAlignment.spaceEvenly,
                    groupsSpace: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentVisitorsList extends StatelessWidget {
  final List<Map<String, dynamic>> dummyData;

  const _RecentVisitorsList({required this.dummyData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260, // Adjust as needed
      child: ListView.builder(
        itemCount: dummyData.length,
        itemBuilder: (context, index) {
          final visitor = dummyData[index];
          return _VisitorListItem(visitor: visitor);
        },
      ),
    );
  }
}

class _VisitorListItem extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const _VisitorListItem({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final timeIn = (visitor['time_in'] as Timestamp).toDate();
    final formattedTime = DateFormat('d MMM, h:mm a').format(timeIn);

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
            Text('To meet: ${visitor['host_name']} (${visitor['department']})'),
            Text('Purpose: ${visitor['purpose']}'),
          ],
        ),
        trailing: Text(
          formattedTime,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
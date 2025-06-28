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
  String _range = 'Daily';
  final List<String> _ranges = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
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
            Image.asset('assets/images/rdl.png', height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reports',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF081735), fontSize: 16),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple, size: 20),
            ),
          ),
        ],
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
              const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Department-wise Visitor Count',
                child: _DepartmentVisitorChart(),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Host-wise Visit Frequency',
                child: _HostVisitChart(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Visitor Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _range,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      dropdownColor: Colors.white,
                      items: _ranges.map((r) => DropdownMenuItem<String>(
                        value: r,
                        child: Text(r, style: const TextStyle(color: Colors.deepPurple)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _range = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReportCard(
                title: '',
                child: _TrendsChart(range: _range),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Visit Duration Averages (minutes)',
                child: _VisitDurationChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveBarChart extends StatelessWidget {
  // Dummy data for last 7 days
  final List<String> days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  final List<int> visitors = [12, 18, 7, 15, 22, 9, 14];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
        return Center(
          child: Container(
            width: chartWidth,
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (visitors.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.deepPurple.shade100,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${days[group.x.toInt()]}\n',
                        const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} visitors',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.black87, fontSize: 12));
                    }),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        return idx >= 0 && idx < days.length
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[idx], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                barGroups: [
                  for (int i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: visitors[i].toDouble(),
                          color: Colors.deepPurple,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ReportCard({required this.title, required this.child, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _DepartmentVisitorChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final Map<String, int> deptCounts = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final dept = data['department'] ?? 'Unknown';
          deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
        }
        final depts = deptCounts.keys.toList();
        final counts = deptCounts.values.toList();
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (int i = 0; i < depts.length; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i].toDouble(), color: Colors.deepPurple)], showingTooltipIndicators: [0]),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < depts.length) {
                      return Text(depts[value.toInt()], style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
          ),
        );
      },
    );
  }
}

class _HostVisitChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final Map<String, int> hostCounts = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final host = data['host_name'] ?? 'Unknown';
          hostCounts[host] = (hostCounts[host] ?? 0) + 1;
        }
        final hosts = hostCounts.keys.toList();
        final counts = hostCounts.values.toList();
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (int i = 0; i < hosts.length; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i].toDouble(), color: Colors.orange)], showingTooltipIndicators: [0]),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < hosts.length) {
                      return Text(hosts[value.toInt()], style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
          ),
        );
      },
    );
  }
}

class _TrendsChart extends StatelessWidget {
  final String range;
  const _TrendsChart({required this.range, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Dummy data based on range
    List<String> labels = [];
    List<double> values = [];
    
    if (range == 'Daily') {
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      values = [15, 22, 18, 25, 30, 12, 8];
    } else if (range == 'Weekly') {
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      values = [85, 120, 95, 110];
    } else { // Monthly
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      values = [320, 280, 350, 420, 380, 450];
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                return idx >= 0 && idx < labels.length
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          labels[idx],
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 4,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 6,
                color: Colors.blueAccent,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.deepPurple.shade100,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final idx = touchedSpot.x.toInt();
                return LineTooltipItem(
                  '${labels[idx]}\n',
                  const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${touchedSpot.y.toInt()} visitors',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: values.reduce((a, b) => a > b ? a : b) + 10,
      ),
    );
  }
}

class _VisitDurationChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final Map<String, List<int>> deptDurations = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final dept = data['department'] ?? 'Unknown';
          final timeIn = (data['time_in'] as Timestamp?)?.toDate();
          final timeOut = (data['time_out'] as Timestamp?)?.toDate();
          if (timeIn != null && timeOut != null) {
            final duration = timeOut.difference(timeIn).inMinutes;
            deptDurations.putIfAbsent(dept, () => []).add(duration);
          }
        }
        final depts = deptDurations.keys.toList();
        final averages = depts.map((d) {
          final list = deptDurations[d]!;
          return list.isNotEmpty ? list.reduce((a, b) => a + b) / list.length : 0.0;
        }).toList();
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (int i = 0; i < depts.length; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: averages[i], color: Colors.green)], showingTooltipIndicators: [0]),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < depts.length) {
                      return Text(depts[value.toInt()], style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
          ),
        );
      },
    );
  }
} 
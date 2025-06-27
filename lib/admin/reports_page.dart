import 'package:flutter/material.dart';
import 'admin_theme.dart';
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
              Row(
                children: [
                  const Text('Select Range:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _range,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: _ranges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _range = val ?? 'Daily';
                      });
                    },
                  ),
                ],
              ),
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
              _ReportCard(
                title: '$_range Visitor Trends',
                child: _TrendsChart(range: _range),
              ),
              const SizedBox(height: 24),
              _ReportCard(
                title: 'Visit Duration Averages',
                child: _VisitDurationChart(),
              ),
            ],
          ),
        ),
      ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final Map<String, int> trends = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final Timestamp? ts = data['time_in'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          String key = '';
          if (range == 'Daily') {
            key = DateFormat('yyyy-MM-dd').format(date);
          } else if (range == 'Weekly') {
            final week = DateFormat('yyyy-ww').format(date);
            key = 'W$week';
          } else {
            key = DateFormat('yyyy-MM').format(date);
          }
          trends[key] = (trends[key] ?? 0) + 1;
        }
        final keys = trends.keys.toList()..sort();
        final values = keys.map((k) => trends[k]!.toDouble()).toList();
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < keys.length) {
                      return Text(keys[value.toInt()], style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
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
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
              ),
            ],
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            minY: 0,
            maxY: values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) + 2 : 6,
          ),
        );
      },
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
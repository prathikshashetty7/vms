import 'package:flutter/material.dart';
import 'admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VisitorManagementPage extends StatefulWidget {
  const VisitorManagementPage({Key? key}) : super(key: key);

  @override
  State<VisitorManagementPage> createState() => _VisitorManagementPageState();
}

class _VisitorManagementPageState extends State<VisitorManagementPage> {
  DateTime? _selectedDate;
  String _selectedHost = 'All';
  String _selectedDepartment = 'All';
  String _selectedType = 'All';
  List<String> _hosts = ['All'];
  List<String> _departments = ['All'];
  List<String> _types = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    final hostSnap = await FirebaseFirestore.instance.collection('host').get();
    final deptSnap = await FirebaseFirestore.instance.collection('department').get();
    final visitorSnap = await FirebaseFirestore.instance.collection('visitor').get();
    setState(() {
      _hosts = ['All', ...hostSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['name']?.toString() ?? data['host_name']?.toString() ?? 'Unknown Host';
      }).toSet()];
      _departments = ['All', ...deptSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['d_name']?.toString() ?? data['name']?.toString() ?? 'Unknown Department';
      }).toSet()];
      _types = ['All', ...visitorSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['type']?.toString() ?? '';
      }).where((t) => t.isNotEmpty).toSet()];
    });
  }

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
                'View Visitors',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                    icon: const Icon(Icons.date_range),
                    label: Text(_selectedDate == null ? 'Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedHost,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: _hosts.map((host) {
                      return DropdownMenuItem<String>(
                        value: host,
                        child: Text(host),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedHost = val ?? 'All';
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedDepartment,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDepartment = val ?? 'All';
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedType,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: _types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val ?? 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _VisitorListView(
                date: _selectedDate,
                host: _selectedHost,
                department: _selectedDepartment,
                type: _selectedType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorListView extends StatelessWidget {
  final DateTime? date;
  final String host;
  final String department;
  final String type;
  const _VisitorListView({this.date, required this.host, required this.department, required this.type, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No visitors found.', style: TextStyle(color: Colors.white70)));
        }
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          if (date != null) {
            final Timestamp? ts = data['time_in'] as Timestamp?;
            if (ts == null) return false;
            final d = ts.toDate();
            if (!(d.year == date!.year && d.month == date!.month && d.day == date!.day)) return false;
          }
          if (host != 'All' && (data['host_name'] ?? '') != host) return false;
          if (department != 'All' && (data['department'] ?? '') != department) return false;
          if (type != 'All' && (data['type'] ?? '') != type) return false;
          return true;
        }).toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('Visitor Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Host Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Department', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Time In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Time Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Duration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final visitorName = data['visitor_name'] ?? '';
              final hostName = data['host_name'] ?? '';
              final dept = data['department'] ?? '';
              final timeIn = (data['time_in'] as Timestamp?)?.toDate();
              final timeOut = (data['time_out'] as Timestamp?)?.toDate();
              final duration = (timeIn != null && timeOut != null)
                  ? _formatDuration(timeIn, timeOut)
                  : '-';
              final status = data['status'] ?? 'In';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(visitorName, style: const TextStyle(color: Colors.black))),
                      Expanded(flex: 2, child: Text(hostName, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(dept, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(timeIn != null ? DateFormat('HH:mm').format(timeIn) : '-', style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(timeOut != null ? DateFormat('HH:mm').format(timeOut) : '-', style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(duration, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(status, style: TextStyle(color: status == 'In' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _formatDuration(DateTime inTime, DateTime outTime) {
    final diff = outTime.difference(inTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
} 
import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VisitorManagementPage extends StatefulWidget {
  const VisitorManagementPage({Key? key}) : super(key: key);

  @override
  State<VisitorManagementPage> createState() => _VisitorManagementPageState();
}

class _VisitorManagementPageState extends State<VisitorManagementPage> {
  DateTime? _selectedDate;
  String _selectedDepartment = 'Departments';
  List<String> _departments = ['Departments'];

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    final deptSnap = await FirebaseFirestore.instance.collection('department').get();
    setState(() {
      _departments = ['Departments', ...deptSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['d_name']?.toString() ?? data['name']?.toString() ?? 'Unknown Department';
      }).toSet()];
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
            Image.asset('assets/images/rdl.png', height: 40),
            const SizedBox(width: 10),
            const Text('Visitor Management', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    label: Text(_selectedDate == null ? 'Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!), style: TextStyle(color: Colors.black)),
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
                  SizedBox(
                    width: 180, // Adjust width as needed
                    height: 40, // Adjust height as needed
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // The white selected value
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 36),
                              child: Text(
                                _selectedDepartment,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        // The dropdown icon on the right
                        Positioned(
                          right: 8,
                          child: Icon(Icons.arrow_drop_down, color: Colors.black),
                        ),
                        // The transparent DropdownButton overlays the text and handles interaction
                        DropdownButton<String>(
                          value: _selectedDepartment,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.white),
                          items: _departments.map((dept) {
                            return DropdownMenuItem<String>(
                              value: dept,
                              child: Text(dept, style: const TextStyle(color: Colors.black)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartment = val ?? 'Departments';
                            });
                          },
                          icon: const SizedBox.shrink(), // Hide default icon
                          underline: Container(height: 2, color: Colors.transparent),
                          isExpanded: true,
                          selectedItemBuilder: (context) => _departments.map((dept) => const SizedBox.shrink()).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _VisitorListView(
                date: _selectedDate,
                department: _selectedDepartment,
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
  final String department;
  const _VisitorListView({this.date, required this.department, Key? key}) : super(key: key);

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
          if (department != 'Departments' && (data['department'] ?? '') != department) return false;
          return true;
        }).toList();
        // Manual grouping by date
        Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final vDateRaw = data['v_date'];
          String vDate = '';
          if (vDateRaw != null) {
            if (vDateRaw is String) {
              vDate = vDateRaw.split(' ')[0];
            } else if (vDateRaw is Timestamp) {
              vDate = DateFormat('yyyy-MM-dd').format(vDateRaw.toDate());
            }
          }
          grouped.putIfAbsent(vDate, () => []).add(doc);
        }
        // Sort groups: today first, then yesterday, then older
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            if (a == today) return -1;
            if (b == today) return 1;
            if (a == yesterday) return -1;
            if (b == yesterday) return 1;
            return b.compareTo(a); // newest first
          });
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            for (final key in sortedKeys) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key == today
                          ? 'Today'
                          : key == yesterday
                              ? 'Yesterday'
                              : key,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ),
              ...grouped[key]!.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final visitorName = data['v_name'] ?? '';
                final vDateRaw = data['v_date'];
                String vDate = '-';
                if (vDateRaw != null) {
                  if (vDateRaw is String) {
                    vDate = vDateRaw.split(' ')[0];
                  } else if (vDateRaw is Timestamp) {
                    vDate = DateFormat('yyyy-MM-dd').format(vDateRaw.toDate());
                  }
                }
                final vTime = data['v_time'] ?? '-';
                final vTimeOut = data['v_time_out'] ?? '-';
                final vEmail = data['v_email'] ?? '-';
                final vCompany = data['v_company_name'] ?? '-';
                final vDesignation = data['v_designation'] ?? '-';
                final vContact = data['v_contactno'] ?? '-';
                final department = data['department'] ?? '-';
                final host = data['host_name'] ?? data['emp_name'] ?? '-';
                final empId = data['emp_id'] ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                visitorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: Colors.deepPurple),
                              tooltip: 'View Details',
                              onPressed: () async {
                                String hostName = host;
                                if (hostName == '-' && empId.isNotEmpty) {
                                  try {
                                    final hostSnap = await FirebaseFirestore.instance.collection('host').doc(empId).get();
                                    final hostData = hostSnap.data() as Map<String, dynamic>?;
                                    if (hostData != null) {
                                      hostName = hostData['emp_name'] ?? hostData['name'] ?? '-';
                                    }
                                  } catch (_) {}
                                }
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Visitor Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _visitorDetailRow('Name', visitorName),
                                          _visitorDetailRow('Host', hostName),
                                          _visitorDetailRow('Company', vCompany),
                                          _visitorDetailRow('Designation', vDesignation),
                                          _visitorDetailRow('Email', vEmail),
                                          _visitorDetailRow('Contact', vContact),
                                          _visitorDetailRow('Date', vDate),
                                          _visitorDetailRow('Time', vTime),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Visitor',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Visitor'),
                                    content: const Text("Are you sure you want to delete this visitor's record?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.delete();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey, size: 18),
                            const SizedBox(width: 4),
                            Text('$vTime - $vTimeOut', style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.apartment, color: Colors.grey, size: 18),
                            const SizedBox(width: 4),
                            Text('Department: $department', style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: Colors.grey, size: 18),
                            const SizedBox(width: 4),
                            Text('Host: $host', style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
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

  Widget _visitorDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? Colors.black87))),
        ],
      ),
    );
  }
} 
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
  String _selectedDepartmentId = '';
  List<Map<String, String>> _departments = [{'id': '', 'name': 'Departments'}];

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    final deptSnap = await FirebaseFirestore.instance.collection('department').get();
    setState(() {
      _departments = [
        {'id': '', 'name': 'Departments'},
        ...deptSnap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {
            'id': doc.id,
            'name': data['d_name']?.toString() ?? data['name']?.toString() ?? 'Unknown Department',
          };
        })
      ];
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
            tooltip: 'Select Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                // Do NOT setState _selectedDate here, just use picked for dialog
                // setState(() {
                //   _selectedDate = picked;
                // });
                // Fetch visitors for the selected date
                final visitorSnap = await FirebaseFirestore.instance.collection('visitor').get();
                final visitors = visitorSnap.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  // Prefer v_date, fallback to time_in
                  dynamic vDateRaw = data['v_date'] ?? data['time_in'];
                  DateTime? vDate;
                  if (vDateRaw is Timestamp) {
                    vDate = vDateRaw.toDate();
                  } else if (vDateRaw is String) {
                    try {
                      vDate = DateTime.parse(vDateRaw);
                    } catch (_) {
                      // Try to extract date part if string is not ISO
                      final parts = vDateRaw.split(' ');
                      if (parts.length >= 4) {
                        // e.g. July 24, 2025 at 2:06:18 PM UTC+5:30
                        final dateStr = parts.take(3).join(' ');
                        try {
                          vDate = DateTime.parse(DateFormat('MMMM d, yyyy').parse(dateStr).toIso8601String());
                        } catch (_) {}
                      }
                    }
                  }
                  if (vDate == null) return false;
                  return vDate.year == picked.year && vDate.month == picked.month && vDate.day == picked.day;
                }).toList();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Visitors on ${DateFormat('dd/MM/yyyy').format(picked)}'),
                      content: SizedBox(
                        width: 320,
                        child: visitors.isEmpty
                            ? const Text('No visitors found for this date.')
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    for (final visitorDoc in visitors) ...[
                                      Builder(
                                        builder: (context) {
                                          final data = visitorDoc.data() as Map<String, dynamic>? ?? {};
                                          Future<String> getDeptName() async {
                                            String deptName = data['department']?.toString() ?? data['dept_name']?.toString() ?? '';
                                            if ((deptName.isEmpty || deptName == '-') && (data['departmentId'] ?? '').toString().isNotEmpty) {
                                              try {
                                                final deptSnap = await FirebaseFirestore.instance.collection('department').doc(data['departmentId']).get();
                                                if (deptSnap.exists) {
                                                  deptName = deptSnap.data()?['d_name']?.toString() ?? deptSnap.data()?['name']?.toString() ?? '-';
                                                }
                                              } catch (_) {
                                                deptName = '-';
                                              }
                                            }
                                            if (deptName.isEmpty) deptName = '-';
                                            return deptName;
                                          }
                                          return FutureBuilder<String>(
                                            future: getDeptName(),
                                            builder: (context, snapshot) {
                                              final deptName = snapshot.data ?? '-';
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 16),
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF8F9FB),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Name: ${data['v_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    const SizedBox(height: 4),
                                                    Text('Email: ${data['v_email'] ?? '-'}'),
                                                    Text('Company: ${data['v_company_name'] ?? '-'}'),
                                                    Text('Department: $deptName'),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
              }
            },
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
                  SizedBox(
                    width: 180, // Adjust width as needed
                    height: 40, // Adjust height as needed
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDepartmentId,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          alignment: Alignment.center,
                          selectedItemBuilder: (context) => _departments.map((dept) => Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.business, color: Color(0xFF7C3AED), size: 22),
                                const SizedBox(width: 8),
                                Text(dept['name']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16)),
                              ],
                            ),
                          )).toList(),
                          items: _departments.map((dept) {
                            return DropdownMenuItem<String>(
                              value: dept['id'],
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Icon(Icons.business, color: Color(0xFF7C3AED), size: 22),
                                  const SizedBox(width: 8),
                                  Text(dept['name']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartmentId = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _VisitorListView(
                date: _selectedDate,
                departmentId: _selectedDepartmentId,
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
  final String departmentId;
  const _VisitorListView({this.date, required this.departmentId, Key? key}) : super(key: key);

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
          if (departmentId.isNotEmpty && (data['departmentId'] ?? '') != departmentId) return false;
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
                final visitorName = data['v_name'] ?? '-';
                final vCompany = data['v_company_name'] ?? '-';
                final departmentId = data['departmentId'] ?? '';
                final department = data['department'] ?? data['dept_name'] ?? '';
                final purpose = data['purpose'] ?? '-';
                final empId = data['emp_id'] ?? '';
                final vTime = data['v_time'] ?? '-';
                final vTimeOut = data['v_time_out'] ?? '';
                // Host name logic
                return FutureBuilder<List<String>>(
                  future: (() async {
                    // [0]: host, [1]: department
                    String hostResult = '-';
                    String deptResult = department;
                    // Host
                    if ((data['host_name'] ?? '').toString().isNotEmpty) {
                      hostResult = data['host_name'].toString();
                    } else if (empId.toString().isNotEmpty) {
                      try {
                        final hostSnap = await FirebaseFirestore.instance.collection('host').doc(empId).get();
                        final hostData = hostSnap.data() as Map<String, dynamic>?;
                        if (hostData != null) {
                          hostResult = (hostData['emp_name'] ?? hostData['name'] ?? '-').toString();
                        }
                      } catch (_) {}
                    }
                    // Department
                    if ((deptResult == null || deptResult.isEmpty || deptResult == '-') && departmentId.toString().isNotEmpty) {
                      try {
                        final deptSnap = await FirebaseFirestore.instance.collection('department').doc(departmentId).get();
                        final deptData = deptSnap.data() as Map<String, dynamic>?;
                        if (deptData != null) {
                          deptResult = (deptData['d_name'] ?? deptData['name'] ?? '-').toString();
                        }
                      } catch (_) {}
                    }
                    return [hostResult, deptResult];
                  })(),
                  builder: (context, snapshot) {
                    final host = (snapshot.data != null && snapshot.data!.isNotEmpty) ? snapshot.data![0] : '-';
                    final dept = (snapshot.data != null && snapshot.data!.length > 1) ? snapshot.data![1] : '-';
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
                                    // Fetch the latest visitor data from Firestore
                                    final docRef = FirebaseFirestore.instance.collection('visitor').doc(doc.id);
                                    final freshSnap = await docRef.get();
                                    final freshData = freshSnap.data() as Map<String, dynamic>? ?? {};
                                    // Fetch host name if emp_id is present
                                    String hostName = '-';
                                    if ((freshData['emp_id'] ?? '').toString().isNotEmpty) {
                                      try {
                                        final hostSnap = await FirebaseFirestore.instance.collection('host').doc(freshData['emp_id']).get();
                                        if (hostSnap.exists) {
                                          hostName = hostSnap.data()?['emp_name'] ?? 'Unknown Host';
                                        }
                                      } catch (_) {}
                                    } else {
                                      hostName = freshData['host']?.toString() ?? freshData['host_name']?.toString() ?? '-';
                                    }
                                    // Format date as dd/MM/yyyy
                                    String formattedDate = '-';
                                    if (freshData['v_date'] != null) {
                                      DateTime? date;
                                      if (freshData['v_date'] is Timestamp) {
                                        date = (freshData['v_date'] as Timestamp).toDate();
                                      } else if (freshData['v_date'] is String) {
                                        try {
                                          date = DateTime.parse(freshData['v_date']);
                                        } catch (_) {}
                                      }
                                      if (date != null) {
                                        formattedDate = DateFormat('dd/MM/yyyy').format(date);
                                      }
                                    }
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Column(
                                            children: [
                                              const CircleAvatar(
                                                radius: 32,
                                                backgroundColor: Color(0xFFE3F0FF),
                                                child: Icon(Icons.person, size: 40, color: Color(0xFF2196F3)),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text('Visitor Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                            ],
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  margin: const EdgeInsets.only(bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8F9FB),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _visitorDetailRow('Name', freshData['v_name']?.toString() ?? '-'),
                                                      _visitorDetailRow('Email', freshData['v_email']?.toString() ?? '-'),
                                                      _visitorDetailRow('Designation', freshData['v_designation']?.toString() ?? '-'),
                                                      _visitorDetailRow('Contact No', freshData['v_contactno']?.toString() ?? '-'),
                                                      _visitorDetailRow('Company', freshData['v_company_name']?.toString() ?? '-'),
                                                      _visitorDetailRow('Purpose', freshData['purpose']?.toString() ?? '-'),
                                                    ],
                                                  ),
                                                ),
                                                const Divider(height: 1, thickness: 1),
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8F9FB),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _visitorDetailRow('Total Visitors', freshData['v_totalno']?.toString() ?? '-'),
                                                      _visitorDetailRow('Host', hostName),
                                                      _visitorDetailRow('Date', formattedDate),
                                                      _visitorDetailRow('Time', freshData['v_time']?.toString() ?? '-'),
                                                      _visitorDetailRow('Pass Generated By', freshData['pass_generated_by']?.toString() ?? '-'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                const Icon(Icons.business, color: Colors.grey, size: 18),
                                const SizedBox(width: 4),
                                Text('Company: $vCompany', style: const TextStyle(color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.apartment, color: Colors.grey, size: 18),
                                const SizedBox(width: 4),
                                Text('Department: $dept', style: const TextStyle(color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.flag, color: Colors.grey, size: 18),
                                const SizedBox(width: 4),
                                Text('Purpose: $purpose', style: const TextStyle(color: Colors.black87)),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.grey, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  vTimeOut != null && vTimeOut.toString().trim().isNotEmpty && vTimeOut != '-'
                                    ? 'Time: $vTime - $vTimeOut'
                                    : 'Time: $vTime',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
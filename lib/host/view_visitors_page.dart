import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/system_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ViewVisitorsPage extends StatefulWidget {
  const ViewVisitorsPage({Key? key}) : super(key: key);

  @override
  State<ViewVisitorsPage> createState() => _ViewVisitorsPageState();
}

class _ViewVisitorsPageState extends State<ViewVisitorsPage> {
  String _search = '';
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';
  String? hostDocId;
  String? departmentId;
  bool loading = true;

  final List<String> _statusOptions = [
    'All',
    'Checked In',
    'Not Checked In',
    'Checked Out',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHostInfo();
  }

  Future<void> _fetchHostInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('host').where('emp_email', isEqualTo: user.email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final data = doc.data();
      setState(() {
        hostDocId = doc.id;
        departmentId = data['departmentId'] ?? '';
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD4E9FF),
      ),
      child: loading || hostDocId == null || departmentId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filters Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or email',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(() => _search = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Filter
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            // Show dialog with visitors for the selected date
                            final visitors = await FirebaseFirestore.instance
                                .collection('visitor')
                                .where('emp_id', isEqualTo: hostDocId)
                                .where('departmentId', isEqualTo: departmentId)
                                .get();
                            final filtered = visitors.docs.where((doc) {
                              final data = doc.data();
                              final vDate = data['v_date'];
                              if (vDate == null) return false;
                              DateTime d;
                              if (vDate is Timestamp) {
                                d = vDate.toDate();
                              } else if (vDate is DateTime) {
                                d = vDate;
                              } else {
                                return false;
                              }
                              return d.year == picked.year && d.month == picked.month && d.day == picked.day;
                            }).toList();
                            String dialogDate = picked != null ? _formatDate(picked) : '';
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Visitors for $dialogDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: filtered.isEmpty
                                              ? const Center(child: Text('No visitors found for this date.'))
                                              : ListView.separated(
                                                  itemCount: filtered.length,
                                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                                  itemBuilder: (context, idx) {
                                                    final v = filtered[idx].data();
                                                    return Card(
                                                      color: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      elevation: 2,
                                                      margin: EdgeInsets.zero,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(v['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                            if ((v['v_company_name'] ?? '').toString().isNotEmpty)
                                                              Text('Company: ${v['v_company_name']}', style: const TextStyle(fontSize: 13)),
                                                            if ((v['v_email'] ?? '').toString().isNotEmpty)
                                                              Text('Email: ${v['v_email']}', style: const TextStyle(fontSize: 13)),
                                                            if ((v['v_time'] ?? '').toString().isNotEmpty)
                                                              Text('Time: ${v['v_time']}', style: const TextStyle(fontSize: 13)),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Close'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6CA4FE).withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6CA4FE)),
                              const SizedBox(width: 6),
                              Text(DateFormat('dd MMM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Visitor Cards List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('visitor')
                          .where('emp_id', isEqualTo: hostDocId)
                          .where('departmentId', isEqualTo: departmentId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No visitors found.'));
                        }
                        final allVisitors = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['docId'] = doc.id;
                          return data;
                        }).toList();
                        
                        if (allVisitors.isEmpty) {
                          return const Center(child: Text('No visitors found.'));
                        }
                        
                        // Group by date (formatted as dd/MM/yyyy)
                        final Map<String, List<Map<String, dynamic>>> grouped = {};
                        for (final v in allVisitors) {
                          String dateStr = '';
                          if (v['v_date'] != null) {
                            if (v['v_date'] is Timestamp) {
                              dateStr = DateFormat('dd/MM/yyyy').format((v['v_date'] as Timestamp).toDate());
                            } else if (v['v_date'] is String) {
                              try {
                                dateStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(v['v_date']));
                              } catch (_) {
                                dateStr = v['v_date'].toString().split(' ').first;
                              }
                            }
                          }
                          if (dateStr.isEmpty) dateStr = 'Unknown Date';
                          grouped.putIfAbsent(dateStr, () => []).add(v);
                        }
                        final sortedDates = grouped.keys.toList()
                          ..sort((a, b) {
                            // Parse dates properly for chronological sorting
                            try {
                              DateTime dateA = DateFormat('dd/MM/yyyy').parse(a);
                              DateTime dateB = DateFormat('dd/MM/yyyy').parse(b);
                              return dateA.compareTo(dateB); // oldest first
                            } catch (e) {
                              // Fallback to string comparison if parsing fails
                              return b.compareTo(a);
                            }
                          });
                        
                        // Sort visitors within each date group by time (descending - latest time first)
                        for (final date in sortedDates) {
                          grouped[date]!.sort((a, b) {
                            String timeA = (a['v_time'] ?? '').toString();
                            String timeB = (b['v_time'] ?? '').toString();
                            
                            // If times are empty, put them at the end
                            if (timeA.isEmpty && timeB.isEmpty) return 0;
                            if (timeA.isEmpty) return 1;
                            if (timeB.isEmpty) return -1;
                            
                            // Compare times (assuming format like "14:30" or "2:30 PM")
                            try {
                              // Try to parse as 24-hour format first
                              List<int> timeAParts = timeA.split(':').map((e) => int.parse(e)).toList();
                              List<int> timeBParts = timeB.split(':').map((e) => int.parse(e)).toList();
                              
                              int timeAValue = timeAParts[0] * 60 + (timeAParts.length > 1 ? timeAParts[1] : 0);
                              int timeBValue = timeBParts[0] * 60 + (timeBParts.length > 1 ? timeBParts[1] : 0);
                              
                              return timeBValue.compareTo(timeAValue); // descending order
                            } catch (e) {
                              // If parsing fails, do string comparison
                              return timeB.compareTo(timeA);
                            }
                          });
                        }
                        
                        return ListView(
                          children: [
                            for (final date in sortedDates) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                                child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              ),
                              ...grouped[date]!.map((v) => _VisitorCard(visitor: v)).toList(),
                            ]
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VisitorCard extends StatefulWidget {
  final Map<String, dynamic> visitor;
  const _VisitorCard({required this.visitor});

  @override
  State<_VisitorCard> createState() => _VisitorCardState();
}

class _VisitorCardState extends State<_VisitorCard> {
  String? photoBase64;
  bool isLoadingPass = true;
  bool isCheckedIn = false;
  bool isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _fetchPassData();
    _checkVisitorStatus();
  }

  Future<void> _checkVisitorStatus() async {
    try {
      final visitorId = widget.visitor['docId'];
      if (visitorId == null) {
        setState(() => isLoadingStatus = false);
        return;
      }
      
      final checkedInOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .where('status', isEqualTo: 'Checked In')
          .limit(1)
          .get();
      
      setState(() {
        isCheckedIn = checkedInOutQuery.docs.isNotEmpty;
        isLoadingStatus = false;
      });
    } catch (e) {
      setState(() => isLoadingStatus = false);
    }
  }

  Future<void> _fetchPassData() async {
    try {
      final docId = widget.visitor['docId'];
      if (docId == null) {
        setState(() => isLoadingPass = false);
        return;
      }
      
      final passesQuery = await FirebaseFirestore.instance
          .collection('passes')
          .where('visitorId', isEqualTo: docId)
          .limit(1)
          .get();
      
      if (passesQuery.docs.isNotEmpty) {
        final passData = passesQuery.docs.first.data();
        // Check if pass was generated by host
        if (passData['source'] == 'host' && passData['photoBase64'] != null) {
          setState(() {
            photoBase64 = passData['photoBase64'];
            isLoadingPass = false;
          });
        } else {
          setState(() => isLoadingPass = false);
        }
      } else {
        setState(() => isLoadingPass = false);
      }
    } catch (e) {
      setState(() => isLoadingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Always show default icon in list view
                    const Icon(Icons.person, size: 28, color: Colors.black),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.visitor['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF091016))),
                          if ((widget.visitor['v_email'] ?? '').toString().isNotEmpty)
                            Text('Email: ${widget.visitor['v_email']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          if ((widget.visitor['v_company_name'] ?? '').toString().isNotEmpty)
                            Text('Company: ${widget.visitor['v_company_name']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          if ((widget.visitor['purpose'] ?? '').toString().isNotEmpty)
                            Text('Purpose: ${widget.visitor['purpose']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          if ((widget.visitor['v_time'] ?? '').toString().isNotEmpty)
                            Text('Time: ${widget.visitor['v_time']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6CA4FE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final docId = widget.visitor['docId'];
                        if (docId == null) return;
                        // Only check passes collection for checkout_code
                        final passesQuery = await FirebaseFirestore.instance.collection('passes').where('visitorId', isEqualTo: docId).limit(1).get();
                        if (passesQuery.docs.isNotEmpty) {
                          final passData = passesQuery.docs.first.data();
                          if (passData['checkout_code'] != null && passData['checkout_code'].toString().isNotEmpty) {
                            // Already generated, show the same code
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Checkout Code'),
                                content: Text('Your checkout code is: ${passData['checkout_code']}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                        }
                        // Generate unique 4-digit code
                        final code = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                        final now = DateTime.now();
                        // Add/update in passes collection only
                        if (passesQuery.docs.isNotEmpty) {
                          // Update existing pass
                          await FirebaseFirestore.instance.collection('passes').doc(passesQuery.docs.first.id).update({
                            'checkout_code': code,
                          });
                        } else {
                          // Create new pass entry with minimal info
                          await FirebaseFirestore.instance.collection('passes').add({
                            'visitorId': docId,
                            'checkout_code': code,
                          });
                        }
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Checkout Code'),
                            content: Text('Your checkout code is: $code'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Checkout Code'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6CA4FE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showVisitorDetailsDialog(context, widget.visitor),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Checked In Status Button positioned at top right
          if (!isLoadingStatus)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCheckedIn ? Colors.green : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn ? Icons.check_circle : Icons.schedule,
                      size: 16,
                      color: isCheckedIn ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCheckedIn ? 'Checked In' : 'Not Checked In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isCheckedIn ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showVisitorDetailsDialog(BuildContext context, Map<String, dynamic> visitor) {
  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder<String?>(
        future: _getVisitorImage(visitor['docId']),
        builder: (context, snapshot) {
          Widget avatarWidget;
          if (snapshot.connectionState == ConnectionState.waiting) {
            avatarWidget = CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: const CircularProgressIndicator(color: Colors.blue),
            );
          } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            avatarWidget = CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6CA4FE).withOpacity(0.15),
              backgroundImage: MemoryImage(base64Decode(snapshot.data!)),
            );
          } else {
            avatarWidget = CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, size: 48, color: Colors.blue),
            );
          }
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              avatarWidget,
                              const SizedBox(height: 10),
                              const Text(
                                'Visitor Details',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Card(
                          color: Colors.grey[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow('Name', visitor['v_name'] ?? ''),
                                _detailRow('Email', visitor['v_email'] ?? ''),
                                _detailRow('Designation', visitor['v_designation'] ?? ''),
                                _detailRow('Contact No', visitor['v_contactno'] ?? ''),
                                _detailRow('Company', visitor['v_company_name'] ?? ''),
                                _detailRow('Purpose', (visitor['purpose'] ?? 'N/A').toString().trim().isEmpty ? 'N/A' : visitor['purpose'].toString().trim()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(),
                        Card(
                          color: Colors.grey[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow('Total Visitors', visitor['v_totalno']?.toString() ?? ''),
                                _detailRow('Date', _formatDate(visitor['v_date'])),
                                _detailRow('Time', visitor['v_time'] ?? ''),
                                // No Pass Generated By
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text('Close', style: TextStyle(fontSize: 16, color: Colors.black87)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );
}

String _formatDate(dynamic date) {
  if (date == null) return '';
  if (date is Timestamp) {
    final d = date.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  if (date is DateTime) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  return date.toString();
}

Future<String?> _getVisitorImage(String? visitorId) async {
  if (visitorId == null) return null;
  
  try {
    final passesQuery = await FirebaseFirestore.instance
        .collection('passes')
        .where('visitorId', isEqualTo: visitorId)
        .limit(1)
        .get();
    
    if (passesQuery.docs.isNotEmpty) {
      final passData = passesQuery.docs.first.data();
      // Check if pass was generated by host
      if (passData['source'] == 'host' && passData['photoBase64'] != null) {
        return passData['photoBase64'];
      }
    }
    return null;
  } catch (e) {
    return null;
  }
} 
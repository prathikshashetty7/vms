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
                  // Status Filter Buttons
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      itemBuilder: (context, index) {
                        final status = _statusOptions[index];
                        final isSelected = _statusFilter == status;
                        return Container(
                          margin: EdgeInsets.only(right: 12),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = status;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? const Color(0xFF6CA4FE) : Colors.white,
                              foregroundColor: isSelected ? Colors.white : const Color(0xFF6CA4FE),
                              elevation: isSelected ? 2 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF6CA4FE) : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              ...grouped[date]!.map((v) => _VisitorCard(
                                visitor: v,
                                statusFilter: _statusFilter,
                              )).toList(),
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
  final String statusFilter;
  const _VisitorCard({required this.visitor, required this.statusFilter});

  @override
  State<_VisitorCard> createState() => _VisitorCardState();
}

class _VisitorCardState extends State<_VisitorCard> {
  String? photoBase64;
  bool isLoadingPass = true;
  String visitorStatus = 'Not Checked In';
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
      
      // Check for Checked Out status first
      final checkedOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .where('status', isEqualTo: 'Checked Out')
          .limit(1)
          .get();
      
      // Check for Checked In status
      final checkedInQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .where('status', isEqualTo: 'Checked In')
          .limit(1)
          .get();
      
      String status;
      if (checkedOutQuery.docs.isNotEmpty) {
        status = 'Checked Out';
      } else if (checkedInQuery.docs.isNotEmpty) {
        status = 'Checked In';
      } else {
        status = 'Not Checked In';
      }
      
      setState(() {
        visitorStatus = status;
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
    // Apply status filter - hide visitors that don't match the selected filter
    if (widget.statusFilter != 'All' && visitorStatus.toLowerCase() != widget.statusFilter.toLowerCase()) {
      return SizedBox.shrink(); // Hide this item
    }
    
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
                        
                        // Check checked_in_out collection for existing checkout code
                        final checkInOutQuery = await FirebaseFirestore.instance
                            .collection('checked_in_out')
                            .where('visitor_id', isEqualTo: docId)
                            .get();
                            
                        if (checkInOutQuery.docs.isNotEmpty) {
                          // Sort by created_at to get the most recent record
                          final sortedDocs = checkInOutQuery.docs.toList()
                            ..sort((a, b) {
                              final aCreated = a.data()['created_at'] as Timestamp?;
                              final bCreated = b.data()['created_at'] as Timestamp?;
                              if (aCreated == null && bCreated == null) return 0;
                              if (aCreated == null) return 1;
                              if (bCreated == null) return -1;
                              return bCreated.compareTo(aCreated); // Most recent first
                            });
                          
                          final checkInOutData = sortedDocs.first.data();
                          if (checkInOutData['checkout_code'] != null && checkInOutData['checkout_code'].toString().isNotEmpty) {
                            // Already generated, show the same code
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Checkout Code'),
                                content: Text('Your checkout code is: ${checkInOutData['checkout_code']}'),
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
                        
                        // Store checkout code in checked_in_out collection
                        if (checkInOutQuery.docs.isNotEmpty) {
                          // Update the most recent check-in/out record
                          final sortedDocs = checkInOutQuery.docs.toList()
                            ..sort((a, b) {
                              final aCreated = a.data()['created_at'] as Timestamp?;
                              final bCreated = b.data()['created_at'] as Timestamp?;
                              if (aCreated == null && bCreated == null) return 0;
                              if (aCreated == null) return 1;
                              if (bCreated == null) return -1;
                              return bCreated.compareTo(aCreated); // Most recent first
                            });
                          
                          await FirebaseFirestore.instance
                              .collection('checked_in_out')
                              .doc(sortedDocs.first.id)
                              .update({
                            'checkout_code': code,
                          });
                        } else {
                          // Create new check-in/out record with checkout code
                          await FirebaseFirestore.instance.collection('checked_in_out').add({
                            'visitor_id': docId,
                            'checkout_code': code,
                            'created_at': FieldValue.serverTimestamp(),
                            'status': 'Checked In', // Assuming visitor is checked in when generating checkout code
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
          // Status Button positioned at top right
          if (!isLoadingStatus)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(visitorStatus),
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
                      _getStatusIcon(visitorStatus),
                      size: 16,
                      color: (visitorStatus == 'Checked In' || visitorStatus == 'Checked Out') ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      visitorStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (visitorStatus == 'Checked In' || visitorStatus == 'Checked Out') ? Colors.white : Colors.grey.shade600,
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
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        Flexible(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
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

Future<Map<String, dynamic>> _getVisitorWithCheckInOutDetails(Map<String, dynamic> visitorDoc) async {
  try {
    // Get the visitor_id from visitor table - use docId as fallback
    final visitorId = visitorDoc['visitor_id'] ?? visitorDoc['id'] ?? visitorDoc['docId'];
    if (visitorId == null) return {};
    
    // First, try to fetch visitor details from manual_registrations collection
    Map<String, dynamic> visitorDetails = {};
    bool isFromManualRegistrations = false;
    try {
      final manualRegQuery = await FirebaseFirestore.instance
          .collection('manual_registrations')
          .where('visitor_id', isEqualTo: visitorId)
          .get();
      
      if (manualRegQuery.docs.isNotEmpty) {
        // Sort by timestamp to get the most recent record
        final sortedDocs = manualRegQuery.docs.toList()
          ..sort((a, b) {
            final aTimestamp = a.data()['timestamp'] as Timestamp?;
            final bTimestamp = b.data()['timestamp'] as Timestamp?;
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            return bTimestamp.compareTo(aTimestamp); // Most recent first
          });
        
        visitorDetails = sortedDocs.first.data();
        isFromManualRegistrations = true;
        print('Found manual_registrations data for visitor_id: $visitorId');
      } else {
        print('No manual_registrations found for visitor_id: $visitorId');
      }
    } catch (e) {
      print('Error fetching from manual_registrations: $e');
    }
    
    // If not found in manual_registrations, use visitor collection data
    if (visitorDetails.isEmpty) {
      visitorDetails = visitorDoc;
      isFromManualRegistrations = false;
      print('Using visitor collection data for visitor_id: $visitorId');
    }
    
    // Fetch host name using emp_id
    String hostName = visitorDetails['host_name'] ?? visitorDetails['host'] ?? '';
    if (hostName.isEmpty && (visitorDetails['emp_id'] ?? '').toString().isNotEmpty) {
      try {
        final hostDoc = await FirebaseFirestore.instance
            .collection('host')
            .doc(visitorDetails['emp_id'])
            .get();
        
        if (hostDoc.exists) {
          final hostData = hostDoc.data() as Map<String, dynamic>?;
          hostName = hostData?['emp_name'] ?? hostData?['name'] ?? '';
        }
      } catch (e) {
        print('Error fetching host details: $e');
      }
    }
    
    // Fetch department name using departmentId
    String departmentName = visitorDetails['department'] ?? visitorDetails['dept_name'] ?? '';
    if (departmentName.isEmpty && (visitorDetails['departmentId'] ?? '').toString().isNotEmpty) {
      try {
        final deptDoc = await FirebaseFirestore.instance
            .collection('department')
            .doc(visitorDetails['departmentId'])
            .get();
        
        if (deptDoc.exists) {
          final deptData = deptDoc.data() as Map<String, dynamic>?;
          departmentName = deptData?['d_name'] ?? deptData?['name'] ?? '';
        }
      } catch (e) {
        print('Error fetching department details: $e');
      }
    }
    
    // Update visitor details with fetched host and department names
    visitorDetails['host_name'] = hostName;
    visitorDetails['department'] = departmentName;
    
    // Query checked_in_out collection for this visitor using visitor_id
    final checkInOutQuery = await FirebaseFirestore.instance
        .collection('checked_in_out')
        .where('visitor_id', isEqualTo: visitorId)
        .get();
    
    if (checkInOutQuery.docs.isNotEmpty) {
      // Sort by created_at to get the most recent record
      final sortedDocs = checkInOutQuery.docs.toList()
        ..sort((a, b) {
          final aCreated = a.data()['created_at'] as Timestamp?;
          final bCreated = b.data()['created_at'] as Timestamp?;
          if (aCreated == null && bCreated == null) return 0;
          if (aCreated == null) return 1;
          if (bCreated == null) return -1;
          return bCreated.compareTo(aCreated); // Most recent first
        });
      
      final checkInOutData = sortedDocs.first.data();
      
      // Check visitor status (Checked In, Checked Out, or Not Checked In)
      final checkedInQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .where('status', isEqualTo: 'Checked In')
          .limit(1)
          .get();
      
      final checkedOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .where('status', isEqualTo: 'Checked Out')
          .limit(1)
          .get();
      
      String status;
      if (checkedOutQuery.docs.isNotEmpty) {
        status = 'Checked Out';
      } else if (checkedInQuery.docs.isNotEmpty) {
        status = 'Checked In';
      } else {
        status = 'Not Checked In';
      }
      
      return {
        'check_in_time': _formatTimestamp(checkInOutData['check_in_time']),
        'check_out_time': _formatTimestamp(checkInOutData['check_out_time']),
        'status': status,
        'check_in_date': checkInOutData['check_in_date'],
        'visitor_details': visitorDetails, // Include the fetched visitor details
        'is_from_manual_registrations': isFromManualRegistrations, // Flag to indicate data source
      };
    }
    
    return {
      'visitor_details': visitorDetails, // Return visitor details even if no check-in/out data
      'is_from_manual_registrations': isFromManualRegistrations, // Flag to indicate data source
    };
  } catch (e) {
    print('Error fetching check-in/out details: $e');
    return {};
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return 'N/A';
  if (timestamp is Timestamp) {
    // Convert to Indian Standard Time (IST) - UTC+5:30
    final utcDateTime = timestamp.toDate();
    final istDateTime = utcDateTime.add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istDateTime);
  } else if (timestamp is DateTime) {
    // Convert to Indian Standard Time (IST) - UTC+5:30
    final istDateTime = timestamp.add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istDateTime);
  }
  return timestamp.toString();
}

String _formatVisitDate(dynamic visitDate) {
  if (visitDate == null) return 'N/A';
  if (visitDate is Timestamp) {
    final dt = visitDate.toDate();
    return DateFormat('dd/MM/yyyy').format(dt);
  } else if (visitDate is DateTime) {
    return DateFormat('dd/MM/yyyy').format(visitDate);
  } else if (visitDate is String) {
    // If it's already a formatted string, return as is
    return visitDate;
  }
  return visitDate.toString();
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'checked in':
      return Colors.green;
    case 'checked out':
      return Colors.orange;
    case 'not checked in':
      return Colors.grey.shade300;
    default:
      return Colors.grey.shade300;
  }
}

IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'checked in':
      return Icons.check_circle;
    case 'checked out':
      return Icons.logout;
    case 'not checked in':
      return Icons.schedule;
    default:
      return Icons.schedule;
  }
}
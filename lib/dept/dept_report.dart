import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class DeptReport extends StatefulWidget {
  final String? currentDepartmentId;
  const DeptReport({Key? key, this.currentDepartmentId}) : super(key: key);

  @override
  _DeptReportState createState() => _DeptReportState();
}

class _DeptReportState extends State<DeptReport> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      decoration: SystemTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E9FF),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: widget.currentDepartmentId == null
                      ? null
                      : FirebaseFirestore.instance
                          .collection('manual_registrations')
                          .where('department', isEqualTo: widget.currentDepartmentId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No visitors found for this department',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index].data() as Map<String, dynamic>;
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getVisitorWithCheckInOutDetails(doc),
                          builder: (context, checkInOutSnapshot) {
                            final visitorData = checkInOutSnapshot.data ?? {};
                            final name = doc['fullName'] ?? doc['v_name'] ?? '';
                            final hostName = doc['host'] ?? '';
                            final vDate = doc['timestamp'];
                            final checkin = visitorData['check_in_time'] ?? 'N/A';
                            final checkout = visitorData['check_out_time'] ?? 'N/A';
                            final status = visitorData['status'] ?? 'Not Checked In';
                            
                            String dateStr = 'N/A';
                            if (vDate != null) {
                              if (vDate is Timestamp) {
                                final dt = vDate.toDate();
                                dateStr = DateFormat('dd/MM/yyyy').format(dt);
                              } else if (vDate is DateTime) {
                                dateStr = DateFormat('dd/MM/yyyy').format(vDate);
                              } else {
                                dateStr = vDate.toString();
                              }
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(status),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  name, 
                                  style: SystemTheme.heading.copyWith(fontSize: 16, color: Colors.black)
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Host Name: $hostName'),
                                    Text('Date: $dateStr'),
                                    Text('Check-in Time: $checkin'),
                                    Text('Check-out Time: $checkout'),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Status: $status',
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.black),
                                  onPressed: () => _showVisitorDetailsDialog(context, doc, visitorData),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getVisitorWithCheckInOutDetails(Map<String, dynamic> visitorDoc) async {
    try {
      final visitorId = visitorDoc['visitor_id'] ?? visitorDoc['id'];
      if (visitorId == null) return {};
      
      // Query checked_in_out collection for this visitor
      final checkInOutQuery = await FirebaseFirestore.instance
          .collection('checked_in_out')
          .where('visitor_id', isEqualTo: visitorId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      
      if (checkInOutQuery.docs.isNotEmpty) {
        final checkInOutData = checkInOutQuery.docs.first.data();
        return {
          'check_in_time': _formatTimestamp(checkInOutData['check_in_time']),
          'check_out_time': _formatTimestamp(checkInOutData['check_out_time']),
          'status': checkInOutData['status'] ?? 'Unknown',
          'check_in_date': checkInOutData['check_in_date'],
        };
      }
      
      return {};
    } catch (e) {
      print('Error fetching check-in/out details: $e');
      return {};
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('HH:mm').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('HH:mm').format(timestamp);
    }
    return timestamp.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'checked in':
        return Colors.green;
      case 'checked out':
        return Colors.orange;
      case 'not checked in':
        return Colors.grey;
      default:
        return Colors.blue;
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
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showVisitorDetailsDialog(BuildContext context, Map<String, dynamic> doc, Map<String, dynamic> checkInOutData) {
    showDialog(
      context: context,
      builder: (context) {
        final String? photoBase64 = doc['photo'] as String?;
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
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: (photoBase64 != null && photoBase64.isNotEmpty)
                                  ? MemoryImage(base64Decode(photoBase64))
                                  : null,
                              child: (photoBase64 == null || photoBase64.isEmpty)
                                  ? const Icon(Icons.person, size: 44, color: Colors.blue)
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
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
                              _detailRow('Full Name', doc['fullName'] ?? doc['v_name'] ?? ''),
                              _detailRow('Email', doc['email'] ?? ''),
                              _detailRow('Mobile Number', doc['mobile'] ?? ''),
                              _detailRow('Designation', doc['designation'] ?? ''),
                              _detailRow('Company Name', doc['company'] ?? ''),
                              _detailRow('Purpose of Visit', doc['purpose'] ?? ''),
                              _detailRow('Do you have appointment?', doc['appointment'] ?? ''),
                              _detailRow('Host Name', doc['host'] ?? ''),
                              _detailRow('Department', doc['department'] ?? ''),
                              _detailRow('Accompanied by others?', doc['accompanying'] ?? ''),
                              if ((doc['accompanying'] ?? '').toString().toLowerCase() == 'yes')
                                _detailRow('Number of Accompanied', doc['accompanyingCount'] ?? ''),
                              _detailRow('Carrying Laptop?', doc['laptop'] ?? ''),
                              if ((doc['laptop'] ?? '').toString().toLowerCase() == 'yes' && (doc['laptopDetails'] ?? '').toString().isNotEmpty)
                                _detailRow('Laptop Details', doc['laptopDetails']),
                              _detailRow('Pass Number', doc['pass_no']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.grey[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-in/Out Details',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              _detailRow('Status', checkInOutData['status'] ?? 'Not Checked In'),
                              _detailRow('Check-in Date', checkInOutData['check_in_date'] ?? 'N/A'),
                              _detailRow('Check-in Time', checkInOutData['check_in_time'] ?? 'N/A'),
                              _detailRow('Check-out Time', checkInOutData['check_out_time'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          child: Text('Close', style: TextStyle(fontSize: 16, color: Colors.black87)),
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
} 
import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? hostDocId;
  String? departmentId;
  String? hostName;
  bool loading = true;

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
        hostName = data['emp_name'] ?? '';
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
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

  Future<Map<String, dynamic>> _getVisitorDetails(String visitorId) async {
    try {
      // First, try to fetch visitor details from manual_registrations collection
      Map<String, dynamic> visitorDetails = {};
      try {
        final manualRegQuery = await FirebaseFirestore.instance
            .collection('manual_registrations')
            .where('visitor_id', isEqualTo: visitorId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        if (manualRegQuery.docs.isNotEmpty) {
          visitorDetails = manualRegQuery.docs.first.data();
        }
      } catch (e) {
        print('Error fetching from manual_registrations: $e');
      }
      
      // If not found in manual_registrations, fetch from visitor collection
      if (visitorDetails.isEmpty) {
        final visitorDoc = await FirebaseFirestore.instance
            .collection('visitor')
            .doc(visitorId)
            .get();
        
        if (visitorDoc.exists) {
          visitorDetails = visitorDoc.data() ?? {};
        }
      }
      
      return visitorDetails;
    } catch (e) {
      print('Error fetching visitor details: $e');
      return {};
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return DateFormat('h:mm a').format(dt);
    }
    if (timestamp is DateTime) {
      return DateFormat('h:mm a').format(timestamp);
    }
    if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp);
        return DateFormat('h:mm a').format(dt);
      } catch (e) {
        return timestamp;
      }
    }
    return timestamp.toString();
  }

  // Add this function to show details dialog
  void _showVisitorDetailsDialog(BuildContext context, Map<String, dynamic> doc) async {
    // Fetch visitor details using the same logic as the list
    Map<String, dynamic> visitorData = {};
    if (doc['visitor_id'] != null) {
      visitorData = await _getVisitorDetails(doc['visitor_id']);
    }
    showDialog(
      context: context,
      builder: (context) {
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
                              child: const Icon(Icons.person, size: 44, color: Colors.blue),
                            ),
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
                              _detailRow('Full Name', visitorData['fullName'] ?? visitorData['v_name'] ?? ''),
                              _detailRow('Email', visitorData['email'] ?? visitorData['v_email'] ?? ''),
                              _detailRow('Mobile Number', visitorData['mobile'] ?? visitorData['v_contactno'] ?? ''),
                              _detailRow('Designation', visitorData['designation'] ?? visitorData['v_designation'] ?? ''),
                              _detailRow('Company Name', visitorData['company'] ?? visitorData['v_company_name'] ?? ''),
                              _detailRow('Purpose of Visit', visitorData['purpose'] ?? ''),
                              _detailRow('Do you have appointment?', visitorData['appointment'] ?? ''),
                              _detailRow('Host Name', visitorData['host'] ?? visitorData['host_name'] ?? ''),
                              _detailRow('Check-in Time', doc['check_in_time'] != null ? _formatTimestamp(doc['check_in_time']) : 'N/A'),
                              _detailRow('Check-out Time', doc['check_out_time'] != null ? _formatTimestamp(doc['check_out_time']) : 'N/A'),
                              _detailRow('Department', visitorData['department'] ?? ''),
                              _detailRow('Accompanied by others?', visitorData['accompanying'] ?? ''),
                              if ((visitorData['accompanying'] ?? '').toString().toLowerCase() == 'yes')
                                _detailRow('Number of Accompanied', visitorData['accompanyingCount'] ?? ''),
                              _detailRow('Carrying Laptop?', visitorData['laptop'] ?? ''),
                              if ((visitorData['laptop'] ?? '').toString().toLowerCase() == 'yes' && (visitorData['laptopDetails'] ?? '').toString().isNotEmpty)
                                _detailRow('Laptop Details', visitorData['laptopDetails']),
                              _detailRow('Pass Number', visitorData['pass_no']?.toString() ?? ''),
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
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD4E9FF),
      ),
      child: loading || hostDocId == null || departmentId == null || hostName == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('checked_in_out')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No history yet.', style: TextStyle(color: Color(0xFF091016), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)));
                }
                // Show all checked out visitors
                final visitors = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).where((v) => v['checkout_code'] != null && v['checkout_code'].toString().isNotEmpty).toList();
                if (visitors.isEmpty) {
                  return const Center(child: Text('No history yet.', style: TextStyle(color: Color(0xFF091016), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, idx) {
                    final v = visitors[idx];
                    final visitorId = v['visitor_id'] ?? '';
                    
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getVisitorDetails(visitorId),
                      builder: (context, visitorSnapshot) {
                        if (!visitorSnapshot.hasData) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Loading...'),
                            ),
                          );
                        }
                        
                        final visitorData = visitorSnapshot.data ?? {};
                        final name = visitorData['fullName'] ?? visitorData['v_name'] ?? '';
                        final hostNameValue = visitorData['host'] ?? visitorData['host_name'] ?? hostName ?? '';
                        final vDate = visitorData['v_date'] ?? visitorData['visitDate'];
                        
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
                        
                        // Get check-in and check-out times from the checked_in_out collection
                        final checkin = v['check_in_time'] != null ? _formatTimestamp(v['check_in_time']) : 'N/A';
                        final checkout = v['check_out_time'] != null ? _formatTimestamp(v['check_out_time']) : 'N/A';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.black),
                            title: Text(name, style: SystemTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Host Name: $hostNameValue'),
                                Text('Date: $dateStr'),
                                Text('Check-in Time: $checkin'),
                                Text('Check-out Time: $checkout'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.black),
                              onPressed: () => _showVisitorDetailsDialog(context, v),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
} 
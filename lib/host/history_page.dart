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
      
      // If not found in manual_registrations, fetch from visitor collection
      if (visitorDetails.isEmpty) {
        final visitorDoc = await FirebaseFirestore.instance
            .collection('visitor')
            .doc(visitorId)
            .get();
        
        if (visitorDoc.exists) {
          visitorDetails = visitorDoc.data() ?? {};
        }
        isFromManualRegistrations = false;
        print('Using visitor collection data for visitor_id: $visitorId');
      }
      
      // Add flag to indicate data source
      visitorDetails['is_from_manual_registrations'] = isFromManualRegistrations;
      
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
    final bool isFromManualRegistrations = visitorData['is_from_manual_registrations'] ?? false;
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
                              child: const Icon(Icons.person, color: Colors.black, size: 42, shadows: [Shadow(color: Colors.blueAccent, blurRadius: 16)]),
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
                              // Show different details based on data source
                              if (isFromManualRegistrations) ...[
                                // Full details for manual_registrations data
                                _detailRow('Full Name', visitorData['fullName'] ?? visitorData['v_name'] ?? ''),
                                _detailRow('Email', visitorData['email'] ?? visitorData['v_email'] ?? ''),
                                _detailRow('Mobile Number', visitorData['mobile'] ?? visitorData['v_contactno'] ?? ''),
                                _detailRow('Designation', visitorData['designation'] ?? visitorData['v_designation'] ?? ''),
                                _detailRow('Company Name', visitorData['company'] ?? visitorData['v_company_name'] ?? ''),
                                _detailRow('Purpose of Visit', visitorData['purpose'] ?? ''),
                                _detailRow('Host Name', visitorData['host'] ?? visitorData['host_name'] ?? ''),
                                _detailRow('Department Name', visitorData['department'] ?? visitorData['dept_name'] ?? ''),
                                _detailRow('Do you have appointment?', visitorData['appointment'] ?? ''),
                                _detailRow('Accompanied by others?', visitorData['accompanying'] ?? ''),
                                if ((visitorData['accompanying'] ?? '').toString().toLowerCase() == 'yes')
                                  _detailRow('Number of accompanying', visitorData['accompanyingCount'] ?? ''),
                                _detailRow('Do you have laptop?', visitorData['laptop'] ?? ''),
                                if ((visitorData['laptop'] ?? '').toString().toLowerCase() == 'yes' && (visitorData['laptopDetails'] ?? '').toString().isNotEmpty)
                                  _detailRow('Laptop number', visitorData['laptopDetails']),
                              ] else ...[
                                // Basic details for visitor collection data
                                _detailRow('Full Name', visitorData['fullName'] ?? visitorData['v_name'] ?? ''),
                                _detailRow('Email', visitorData['email'] ?? visitorData['v_email'] ?? ''),
                                _detailRow('Mobile Number', visitorData['mobile'] ?? visitorData['v_contactno'] ?? ''),
                                _detailRow('Designation', visitorData['designation'] ?? visitorData['v_designation'] ?? ''),
                                _detailRow('Company Name', visitorData['company'] ?? visitorData['v_company_name'] ?? ''),
                                _detailRow('Purpose of Visit', visitorData['purpose'] ?? ''),
                                _detailRow('Host Name', visitorData['host'] ?? visitorData['host_name'] ?? ''),
                                _detailRow('Department Name', visitorData['department'] ?? visitorData['dept_name'] ?? ''),
                              ],
                              // Check-in/out details (always shown)
                              _detailRow('Check-in Date', doc['check_in_date'] != null ? _formatDate(doc['check_in_date']) : 'N/A'),
                              _detailRow('Check-in Time', doc['check_in_time'] != null ? _formatTimestamp(doc['check_in_time']) : 'N/A'),
                              _detailRow('Check-out Time', doc['check_out_time'] != null ? _formatTimestamp(doc['check_out_time']) : 'N/A'),
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
                         
                         // Get date from checked_in_out collection
                         String dateStr = 'N/A';
                         final checkInDate = v['check_in_date'];
                         if (checkInDate != null) {
                           if (checkInDate is Timestamp) {
                             final dt = checkInDate.toDate();
                             dateStr = DateFormat('dd/MM/yyyy').format(dt);
                           } else if (checkInDate is DateTime) {
                             dateStr = DateFormat('dd/MM/yyyy').format(checkInDate);
                           } else if (checkInDate is String) {
                             dateStr = checkInDate;
                           } else {
                             dateStr = checkInDate.toString();
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
                            leading: const Icon(Icons.person, color: Colors.black, size: 36, shadows: [Shadow(color: Colors.blueAccent, blurRadius: 16)]),
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
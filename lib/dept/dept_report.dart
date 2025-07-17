import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final List<Map<String, dynamic>> mockVisitors = [
      {
        'v_name': 'John Doe',
        'v_email': 'john@example.com',
        'v_contactno': '9876543210',
        'v_company_name': 'Acme Corp',
        'purpose': 'Business Meeting',
        'appointment': 'Yes',
        'host_name': 'Jane Smith',
        'checkin_time': '10:00 AM',
        'checkout_time': '11:00 AM',
        'carrying_laptop': 'No',
        'photo_url': 'https://example.com/photo.jpg',
        'accomplished_visitors': 2,
      },
      {
        'v_name': 'Alice Brown',
        'v_email': 'alice@example.com',
        'v_contactno': '9123456789',
        'v_company_name': 'Globex',
        'purpose': 'Interview',
        'appointment': 'No',
        'host_name': 'Bob White',
        'checkin_time': '09:30 AM',
        'checkout_time': '10:15 AM',
        'carrying_laptop': 'Yes',
        'photo_url': '',
        'accomplished_visitors': 1,
      },
    ];
    return Container(
      decoration: ReceptionistTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E9FF),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: mockVisitors.length,
                  itemBuilder: (context, index) {
                    final doc = mockVisitors[index];
                    final name = doc['v_name'] ?? '';
                    final checkin = doc['checkin_time'] ?? '';
                    final checkout = doc['checkout_time'] ?? '';
                    final hostName = doc['host_name'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.black),
                        title: Text(name, style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Host Name: $hostName'),
                            Text('Check-in Time: $checkin'),
                            Text('Check-out Time: $checkout'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.black),
                          onPressed: () => _showVisitorDetailsDialog(context, doc),
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showVisitorDetailsDialog(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) {
        final String? photoUrl = doc['photo_url'] as String?;
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
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
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
                              _detailRow('Full Name', doc['v_name'] ?? ''),
                              _detailRow('Email', doc['v_email'] ?? ''),
                              _detailRow('Mobile Number', doc['v_contactno'] ?? ''),
                              _detailRow('Company Name', doc['v_company_name'] ?? ''),
                              _detailRow('Purpose of Visit', doc['purpose'] ?? ''),
                              _detailRow('Do you have appointment?', doc['appointment'] ?? ''),
                              _detailRow('Host Name', doc['host_name'] ?? ''),
                              _detailRow('Check-in Time', doc['checkin_time'] ?? ''),
                              _detailRow('Check-out Time', doc['checkout_time'] ?? ''),
                              _detailRow('Carrying Laptop?', doc['carrying_laptop'] ?? ''),
                              _detailRow('Accomplished No of visitors', doc['accomplished_visitors']?.toString() ?? ''),
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
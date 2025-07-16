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
    return Container(
      decoration: ReceptionistTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E9FF),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: widget.currentDepartmentId == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('visitor')
                            .where('departmentId', isEqualTo: widget.currentDepartmentId)
                            // .orderBy('v_date', descending: true) // Removed to avoid needing an index
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: \n${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('No visitor reports found.', style: ReceptionistTheme.body));
                          }
                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final name = doc['v_name'] ?? '';
                              final email = doc['v_email'] ?? '';
                              final date = (doc['v_date'] as Timestamp?)?.toDate();
                              final total = doc['v_totalno']?.toString() ?? '1';
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
                                      Text('Email: $email'),
                                      Text('Date: ${date != null ? _formatDate(date) : 'N/A'}'),
                                      Text('Total Visitors: $total'),
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('host').doc(doc['emp_id']).get(),
                                        builder: (context, hostSnapshot) {
                                          if (hostSnapshot.connectionState == ConnectionState.waiting) {
                                            return const Text('Host: Loading...');
                                          }
                                          if (!hostSnapshot.hasData || !hostSnapshot.data!.exists) {
                                            return const Text('Host: N/A');
                                          }
                                          final hostName = hostSnapshot.data!['emp_name'] ?? 'N/A';
                                          return Text('Host: $hostName');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 
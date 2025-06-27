import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeptReport extends StatelessWidget {
  const DeptReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeptTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Color(0xFFD4E9FF),
        appBar: AppBar(
          title: const Text('Department Report', style: DeptTheme.appBarTitle),
          backgroundColor: Color(0xFF6CA4FE),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: DeptTheme.deptLight.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visitor Visit Reports', style: DeptTheme.heading.copyWith(fontSize: 22)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('visitor').orderBy('v_date', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No visitor reports found.', style: DeptTheme.body));
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
                                gradient: DeptTheme.deptGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: DeptTheme.deptPrimary.withOpacity(0.10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Colors.white),
                                title: Text(name, style: DeptTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                                subtitle: Text(
                                  'Email: $email\nDate: ${date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A'}\nTotal Visitors: $total',
                                  style: DeptTheme.body.copyWith(color: Colors.white70),
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
        ),
      ),
    );
  }
} 
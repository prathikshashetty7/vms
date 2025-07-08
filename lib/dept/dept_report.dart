import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeptReport extends StatelessWidget {
  const DeptReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ReceptionistTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E9FF),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('visitor').orderBy('v_date', descending: true).snapshots(),
                  builder: (context, snapshot) {
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
                          color: Colors.white,
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.black),
                            title: Text(name, style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                            subtitle: Text(
                              'Email: $email\nDate: ${date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A'}\nTotal Visitors: $total',
                              style: ReceptionistTheme.body.copyWith(color: Colors.black54),
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
} 
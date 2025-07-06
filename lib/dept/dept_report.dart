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
              _customHeader(),
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
                          decoration: BoxDecoration(
                            gradient: ReceptionistTheme.deptGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: ReceptionistTheme.primary.withOpacity(0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(name, style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                            subtitle: Text(
                              'Email: $email\nDate: ${date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A'}\nTotal Visitors: $total',
                              style: ReceptionistTheme.body.copyWith(color: Colors.white70),
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

  Widget _customHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF6CA4FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/rdl.png', height: 32),
          const SizedBox(width: 12),
          const Text('Department Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
} 
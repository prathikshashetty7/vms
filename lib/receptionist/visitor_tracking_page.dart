import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'widgets/visitor_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorTrackingPage extends StatelessWidget {
  const VisitorTrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: const Text('Visitor Tracking'),
        backgroundColor: SystemTheme.accent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitor')
            .where('printed_at', isGreaterThan: null)
            .orderBy('printed_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No checked in visitors (printed) yet.'));
          }
          final visitors = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final data = visitors[index].data() as Map<String, dynamic>;
              final name = data['v_name'] ?? data['fullName'] ?? 'Unknown';
              final printedAt = data['printed_at'];
              String printInfo = '';
              if (printedAt != null) {
                final dt = printedAt is Timestamp ? printedAt.toDate() : DateTime.tryParse(printedAt.toString());
                if (dt != null) {
                  printInfo = 'Printed: '
                    '${dt.day.toString().padLeft(2, '0')}/'
                    '${dt.month.toString().padLeft(2, '0')}/'
                    '${dt.year} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }
              }
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SystemTheme.accent,
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF6CA4FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Checked In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  subtitle: printInfo.isNotEmpty ? Text(printInfo, style: const TextStyle(color: SystemTheme.accent)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
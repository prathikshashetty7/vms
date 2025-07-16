import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

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
                  .collection('passes')
                  // .where('host_name', isEqualTo: hostName)
                  // .where('departmentId', isEqualTo: departmentId)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No history yet.', style: TextStyle(color: Color(0xFF091016), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)));
                }
                // TEMP: Show all passes for debugging
                final visitors = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                if (visitors.isEmpty) {
                  return const Center(child: Text('No history yet.', style: TextStyle(color: Color(0xFF091016), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, idx) {
                    final v = visitors[idx];
                    Widget avatar;
                    final photoBase64 = v['photoBase64'];
                    if (photoBase64 != null && photoBase64 != '') {
                      final bytes = base64Decode(photoBase64);
                      avatar = CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF6CA4FE).withOpacity(0.15),
                        backgroundImage: MemoryImage(bytes),
                      );
                    } else {
                      avatar = const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF6CA4FE),
                        child: Icon(Icons.person, size: 32, color: Color(0xFF6CA4FE)),
                      );
                    }
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                avatar,
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016))),
                                      const SizedBox(height: 4),
                                      Text('Host: ', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
                                      Text('Company: ${v['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6CA4FE)),
                                const SizedBox(width: 4),
                                Text('Date: ${_formatDate(v['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 16, color: Color(0xFF6CA4FE)),
                                const SizedBox(width: 4),
                                Text('Time: ${v['v_time'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 
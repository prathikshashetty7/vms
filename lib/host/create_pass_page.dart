import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePassPage extends StatefulWidget {
  const CreatePassPage({Key? key}) : super(key: key);

  @override
  State<CreatePassPage> createState() => _CreatePassPageState();
}

class _CreatePassPageState extends State<CreatePassPage> {
  String? hostName;
  String? hostDocId;
  String? departmentId;
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
        hostName = data['emp_name'] ?? '';
        hostDocId = doc.id;
        departmentId = data['departmentId'] ?? '';
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD4E9FF),
      ),
      child: loading || hostName == null || hostDocId == null || departmentId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('visitor')
                  .where('emp_id', isEqualTo: hostDocId)
                  .where('departmentId', isEqualTo: departmentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No visitors found.'));
                }
                final visitors = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, idx) {
                    final v = visitors[idx];
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
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Color(0xFF6CA4FE).withOpacity(0.15),
                                  child: const Icon(Icons.person, size: 32, color: Color(0xFF6CA4FE)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016))),
                                      const SizedBox(height: 4),
                                      Text('Host: $hostName', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
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
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF898AC4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                                icon: const Icon(Icons.qr_code, size: 18, color: Colors.white),
                                label: const Text('Generate Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                onPressed: () async {
                                  final visitorId = snapshot.data!.docs[idx].id;
                                  await FirebaseFirestore.instance.collection('visitor').doc(visitorId).update({'pass_generated': true});
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: _VisitorPassCard(
                                        visitor: v,
                                        hostName: hostName ?? '',
                                        passNo: idx + 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
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

class _VisitorPassCard extends StatelessWidget {
  final Map<String, dynamic> visitor;
  final String hostName;
  final int passNo;
  const _VisitorPassCard({required this.visitor, required this.hostName, required this.passNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/rdl.png',
                        width: 60,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(visitor['v_company_name'] ?? '', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(0xFF6CA4FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pass No      : $passNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF091016))),
                    Text('Visitor Name : ${visitor['v_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF091016))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From     : ${visitor['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                  Text('Host     : $hostName', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                  Text('Date     : ${_formatDate(visitor['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                  Text('Time     : ${visitor['v_time'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
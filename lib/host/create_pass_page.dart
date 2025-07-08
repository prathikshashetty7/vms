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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHostName();
  }

  Future<void> _fetchHostName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('host').where('emp_email', isEqualTo: user.email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        hostName = data['emp_name'] ?? '';
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
      child: loading || hostName == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('visitor').where('emp_id', isEqualTo: hostName).snapshots(),
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
                                Text('Date: ${v['v_date'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
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
                                  // Mark pass as generated in Firestore
                                  final visitorId = snapshot.data!.docs[idx].id;
                                  await FirebaseFirestore.instance.collection('visitor').doc(visitorId).update({'pass_generated': true});
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: _VisitorPassCard(
                                        visitor: v,
                                        hostName: hostName ?? '',
                                        passNo: idx + 1, // auto-incremental pass number
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF6CA4FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(visitor['v_company_name'] ?? 'Company', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 2),
                  Text(visitor['v_company_name'] ?? '', style: const TextStyle(fontSize: 10)),
                ],
              ),
              const Spacer(),
              const Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18)),
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
                    Text('Pass No      : $passNo', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
                    Text('Visitor Name : ${visitor['v_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
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
                  Text('Date     : ${visitor['v_date'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
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
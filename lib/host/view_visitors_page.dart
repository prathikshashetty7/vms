import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/receptionist_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewVisitorsPage extends StatefulWidget {
  const ViewVisitorsPage({Key? key}) : super(key: key);

  @override
  State<ViewVisitorsPage> createState() => _ViewVisitorsPageState();
}

class _ViewVisitorsPageState extends State<ViewVisitorsPage> {
  String _search = '';
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';
  String? hostDocId;
  String? departmentId;
  bool loading = true;

  final List<String> _statusOptions = [
    'All',
    'Checked In',
    'Not Checked In',
    'Checked Out',
  ];

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
      child: loading || hostDocId == null || departmentId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filters Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or email',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(() => _search = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Filter
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6CA4FE).withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6CA4FE)),
                              const SizedBox(width: 6),
                              Text(DateFormat('dd MMM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Filter
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6CA4FE).withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _statusFilter = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Visitor Cards List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('visitor')
                          .where('pass_generated', isEqualTo: true)
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
                        if (visitors.isEmpty) {
                          return const Center(child: Text('No visitors with generated pass.'));
                        }
                        return ListView.builder(
                          itemCount: visitors.length,
                          itemBuilder: (context, idx) {
                            final v = visitors[idx];
                            return _VisitorCard(visitor: v);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final Map<String, dynamic> visitor;
  const _VisitorCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF6CA4FE).withOpacity(0.15),
                  child: const Icon(Icons.person, size: 32, color: Color(0xFF6CA4FE)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visitor['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF091016))),
                      const SizedBox(height: 2),
                      Text('Host: ${visitor['host_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                      const SizedBox(height: 2),
                      Text('Check-in: ${visitor['check_in_time'] ?? 'Not checked in'}', style: const TextStyle(fontSize: 13, color: Color(0xFF22C55E))),
                      const SizedBox(height: 2),
                      Text('Check-out: ${visitor['check_out_time'] ?? 'Not checked out'}', style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
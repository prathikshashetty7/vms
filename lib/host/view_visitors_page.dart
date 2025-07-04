import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/receptionist_theme.dart';

class ViewVisitorsPage extends StatefulWidget {
  const ViewVisitorsPage({Key? key}) : super(key: key);

  @override
  State<ViewVisitorsPage> createState() => _ViewVisitorsPageState();
}

class _ViewVisitorsPageState extends State<ViewVisitorsPage> {
  String _search = '';
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';

  final List<String> _statusOptions = [
    'All',
    'Checked In',
    'Not Checked In',
    'Checked Out',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD4E9FF),
      ),
      child: Padding(
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
                stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No visitors found.'));
                  }
                  final visitors = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                  // Filter visitors based on search and status
                  final filteredVisitors = visitors.where((v) {
                    final matchesSearch = (v['v_name'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
                        (v['v_email'] ?? '').toLowerCase().contains(_search.toLowerCase());
                    final matchesStatus = _statusFilter == 'All' || (v['status'] ?? '') == _statusFilter;
                    return matchesSearch && matchesStatus;
                  }).toList();
                  if (filteredVisitors.isEmpty) {
                    return const Center(child: Text('No visitors match your filters.'));
                  }
                  return ListView.builder(
                    itemCount: filteredVisitors.length,
                    itemBuilder: (context, idx) {
                      final v = filteredVisitors[idx];
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Checked In':
        return Color(0xFF22C55E);
      case 'Checked Out':
        return Color(0xFFEF4444);
      case 'Not Checked In':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFFBDBDBD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF6CA4FE).withOpacity(0.15),
              backgroundImage: visitor['photo'],
              child: visitor['photo'] == null ? const Icon(Icons.person, size: 32, color: Color(0xFF6CA4FE)) : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(visitor['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF091016))),
                  const SizedBox(height: 2),
                  Text(visitor['department'], style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                  const SizedBox(height: 2),
                  Text(visitor['time'], style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                  const SizedBox(height: 2),
                  Text(visitor['email'], style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(visitor['status']).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            visitor['status'],
                            style: TextStyle(
                              color: _statusColor(visitor['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View button
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.remove_red_eye, size: 18, color: Color(0xFF6CA4FE)),
                          label: const Text('View', style: TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF6CA4FE),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Checkout button
                        if (visitor['status'] == 'Checked In')
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E)),
                            label: const Text('Checkout', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF22C55E),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
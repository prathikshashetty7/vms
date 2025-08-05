import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'dart:math';
import 'dashboard.dart' show VisitorsPage;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth

class ManualRegistrationsPage extends StatefulWidget {
  final String collection;
  final String title;
  final IconData icon;
  final Color color;
  final String nameField;
  final String mobileField;
  final String timeField;
  const ManualRegistrationsPage({
    required this.collection,
    required this.title,
    required this.icon,
    required this.color,
    required this.nameField,
    required this.mobileField,
    required this.timeField,
    Key? key,
  }) : super(key: key);

  @override
  State<ManualRegistrationsPage> createState() => _ManualRegistrationsPageState();
}

class _ManualRegistrationsPageState extends State<ManualRegistrationsPage> {
  int _selectedIndex = 1; // Set to 1 for Visitors tab

  void _onItemTapped(int index) async {
    if (index == 4) {
      // Show logout confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
      if (shouldLogout == true) {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/receptionist_reports');
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VisitorsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/manual_entry');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _fetchDepartmentMap(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFD4E9FF),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final departmentMap = snapshot.data!;
        // Only show tabs for manual_registrations
        if (widget.collection == 'manual_registrations') {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Image.asset('assets/images/rdl.png', height: 36),
                    const SizedBox(width: 12),
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: const Color(0xFF6CA4FE),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'Visitors'),
                    Tab(text: 'Generated Passes'),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFFD4E9FF),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: Color(0xFF6CA4FE), // blue for selected
                unselectedItemColor: Color(0xFF091016), // black for unselected
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_alt_rounded),
                    label: 'Visitors',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.check_circle_rounded),
                    label: 'Status',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_add_alt_1_rounded),
                    label: 'Add Visitor',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.logout_rounded),
                    label: 'Logout',
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  // Tab 1: Manual Registrations
                  _buildVisitorList(context),
                  // Tab 2: Generated Passes
                  _buildGeneratedPassesList(context, departmentMap: departmentMap),
                ],
              ),
            ),
          );

        } else {
          // For other collections, show only a single list, no tabs, no pass generation
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Image.asset('assets/images/rdl.png', height: 36),
                  const SizedBox(width: 12),
                  Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF6CA4FE),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              automaticallyImplyLeading: false,
            ),
            backgroundColor: const Color(0xFFD4E9FF),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF6CA4FE), // blue for selected
              unselectedItemColor: Color(0xFF091016), // black for unselected
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_rounded),
                  label: 'Visitors',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_rounded),
                  label: 'Status',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_add_alt_1_rounded),
                  label: 'Add Visitor',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout_rounded),
                  label: 'Logout',
                ),
              ],
            ),
            body: _buildVisitorList(context, showPassButton: false),
          );
        }
      },
    );
  }

  Future<Map<String, String>> _fetchDepartmentMap() async {
    final snapshot = await FirebaseFirestore.instance.collection('department').get();
    return {
      for (var doc in snapshot.docs) doc.id: doc.data()['d_name'] ?? doc.id
    };
  }

  // Add this function to generate a unique 4-digit pass number
  Future<int> _generateUniquePassNo() async {
    final random = Random();
    int passNo;
    bool exists = true;
    final passesRef = FirebaseFirestore.instance.collection('passes');
    do {
      passNo = 1000 + random.nextInt(9000); // 4-digit number
      final query = await passesRef.where('pass_no', isEqualTo: passNo).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return passNo;
  }

  // Function to update existing records with source field
  Future<void> _updateExistingRecords() async {
    try {
      // Update records that don't have source field
      final snapshot = await FirebaseFirestore.instance
          .collection(widget.collection)
          .where('source', isNull: true)
          .limit(20)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'source': 'manual'});
      }
      
      // Also update records that have empty source field
      final snapshot2 = await FirebaseFirestore.instance
          .collection(widget.collection)
          .where('source', isEqualTo: '')
          .limit(20)
          .get();
      
      for (var doc in snapshot2.docs) {
        await doc.reference.update({'source': 'manual'});
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
      print('Error updating existing records: $e');
    }
  }

  // Helper to build the visitor list (for manual registrations and other types)
  Widget _buildVisitorList(BuildContext context, {bool showPassButton = true, String? passGeneratedByFilter}) {
    // Update existing records to have source field if missing
    _updateExistingRecords();
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collection)
            .orderBy(widget.timeField, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No visitors found.', style: TextStyle(color: widget.color)));
          }
          final docs = snapshot.data!.docs;
          // Filter docs based on pass_generated_by if filter is provided
          var filteredDocs = passGeneratedByFilter != null 
              ? docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['pass_generated_by'] == passGeneratedByFilter;
                }).toList()
              : docs;
          
          // For manual_registrations collection, filter for manual source only
          if (widget.collection == 'manual_registrations') {
            filteredDocs = filteredDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Show only records that have source: 'manual'
              return data['source'] == 'manual';
            }).toList();
          }
          return ListView.separated(
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;
              final docId = filteredDocs[index].id;
              final name = data[widget.nameField] ?? 'Unknown';
              final time = (data[widget.timeField] as Timestamp?)?.toDate();
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22005FFE),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.color.withOpacity(0.13),
                            radius: 26,
                            child: data['photo'] != null && data['photo'].toString().isNotEmpty
                                ? ClipOval(
                                    child: Image.memory(
                                      const Base64Decoder().convert(data['photo']),
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                    ),
                                  )
                                : Icon(Icons.person, color: Colors.black, size: 32),
                          ),
                          const SizedBox(width: 16),
                          // Name and date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016), fontSize: 17), softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1),
                                if (time != null)
                                  Text(
                                    '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE)),
                                    softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          ),
                          // Action buttons
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 60),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  color: Colors.white, // Set dropdown menu color to white
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditVisitorSheet(context, data, docId);
                                    } else if (value == 'delete') {
                                      _confirmDeleteVisitor(context, docId);
                                    } else if (value == 'view') {
                                      if (widget.collection == 'visitor' || widget.collection == 'visitors') {
                                        String hostName = '';
                                        if (data['emp_id'] != null && data['emp_id'].toString().isNotEmpty) {
                                          final hostDoc = await FirebaseFirestore.instance.collection('host').doc(data['emp_id']).get();
                                          if (hostDoc.exists) {
                                            hostName = hostDoc.data()?['emp_name'] ?? '';
                                          }
                                        }
                                        showDialog(
                                          context: context,
                                          builder: (context) => _AppointedVisitorDetailsDialog(
                                            data: data,
                                          ),
                                        );
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) => _VisitorDetailsDialog(
                                            data: data,
                                            color: widget.color,
                                            icon: widget.icon,
                                            name: name,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: const [Icon(Icons.edit, color: Colors.black), SizedBox(width: 8), Text('Edit')],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: const [Icon(Icons.remove_red_eye, color: Colors.blue), SizedBox(width: 8), Text('View')],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper to build the generated passes list (only for manual registrations)
  Widget _buildGeneratedPassesList(BuildContext context, {required Map<String, String> departmentMap}) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('passes') // Always use 'passes' collection
            .where('group', isEqualTo: 'manual')  // Filter for manual passes only
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No generated passes found.'));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No generated passes found.'));
          }
          
          // Sort the documents in memory by generated_at
          final sortedDocs = docs.toList();
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aGeneratedAt = aData['generated_at'] as Timestamp?;
            final bGeneratedAt = bData['generated_at'] as Timestamp?;
            
            if (aGeneratedAt == null && bGeneratedAt == null) return 0;
            if (aGeneratedAt == null) return 1;
            if (bGeneratedAt == null) return -1;
            
            return bGeneratedAt.compareTo(aGeneratedAt); // descending order
          });
          
          String searchQuery = '';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, company, or host',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    searchQuery = value.toLowerCase();
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['fullName']?.toString().toLowerCase().contains(searchQuery) == true ||
                            data['company']?.toString().toLowerCase().contains(searchQuery) == true ||
                            data['host']?.toString().toLowerCase().contains(searchQuery) == true);
                  }).length,
                  itemBuilder: (context, index) {
                    final filteredDocs = sortedDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['fullName']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['company']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['host']?.toString().toLowerCase().contains(searchQuery) == true);
                    }).toList();
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    Widget avatar;
                    Uint8List? imageBytes;
                    final photo = data['photo'];
                    if (photo != null && photo is String && photo.isNotEmpty) {
                      try {
                        imageBytes = const Base64Decoder().convert(photo);
                      } catch (_) {
                        imageBytes = null;
                      }
                    }
                    if (imageBytes != null) {
                      avatar = CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF6CA4FE).withOpacity(0.15),
                        backgroundImage: MemoryImage(imageBytes),
                      );
                    } else {
                      avatar = const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF6CA4FE),
                        child: Icon(Icons.person, size: 32, color: Colors.white),
                      );
                    }

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              avatar,
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['visitorName'] ?? data['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    const SizedBox(height: 4),
                                    Text('Company: ${data['company'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    if (data['department'] != null && data['department'].toString().isNotEmpty)
                                      Text('Department: ${data['department']}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6CA4FE)),
                                        const SizedBox(width: 4),
                                        Text('Date: ${data['generated_at'] != null && data['generated_at'] is Timestamp ? _formatDateOnly((data['generated_at'] as Timestamp).toDate()) : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.print),
                                          tooltip: 'Print',
                                          onPressed: () async {
                                            // Show pass dialog
                                            showGeneralDialog(
                                              context: context,
                                              barrierColor: Colors.white,
                                              barrierDismissible: true,
                                              barrierLabel: 'Pass',
                                              pageBuilder: (context, anim1, anim2) {
                                                return LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final double cardWidth = constraints.maxWidth > 360 ? 340 : (constraints.maxWidth - 20).clamp(200.0, 340.0);
                                                    return SingleChildScrollView(
                                                      child: ConstrainedBox(
                                                        constraints: BoxConstraints(
                                                          minHeight: constraints.maxHeight,
                                                        ),
                                                        child: IntrinsicHeight(
                                                          child: Align(
                                                            alignment: Alignment.center,
                                                            child: _ManualPassDetailDialog(pass: data, cardWidth: cardWidth),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            await FirebaseFirestore.instance.collection('passes').doc(filteredDocs[index].id).delete();
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pass deleted.')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditVisitorSheet(BuildContext context, Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditVisitorForm(data: data, docId: docId, collection: widget.collection),
    );
  }

  void _confirmDeleteVisitor(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this visitor? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection(widget.collection).doc(docId).delete();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VisitorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String name;
  const _VisitorDetailsDialog({required this.data, required this.color, required this.icon, required this.name, Key? key}) : super(key: key);

  // Add this function to generate a unique 4-digit pass number
  Future<int> _generateUniquePassNo() async {
    final random = Random();
    int passNo;
    bool exists = true;
    final passesRef = FirebaseFirestore.instance.collection('passes');
    do {
      passNo = 1000 + random.nextInt(9000); // 4-digit number
      final query = await passesRef.where('pass_no', isEqualTo: passNo).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return passNo;
  }

  @override
  Widget build(BuildContext context) {
    final photo = data['photo'];
    Uint8List? imageBytes;
    if (photo != null && photo is String && photo.isNotEmpty) {
      try {
        imageBytes = const Base64Decoder().convert(photo);
      } catch (_) {
        imageBytes = null;
      }
    }
    Widget avatar;
    if (imageBytes != null) {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover),
        ),
      );
    } else {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 48),
      );
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    data['photo'] != null && data['photo'].toString().isNotEmpty
                        ? CircleAvatar(
                            radius: 36,
                            backgroundImage: MemoryImage(const Base64Decoder().convert(data['photo'])),
                          )
                        : CircleAvatar(
                            radius: 36,
                            backgroundColor: color.withOpacity(0.13),
                            child: Icon(Icons.person, color: Colors.black, size: 36),
                          ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF091016),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Registration form order:
                // 1. Full Name (already shown as name at top)
                // 2. Mobile
                _buildDetailRow(Icons.phone, 'Mobile', data['mobile']),
                // 3. Email
                _buildDetailRow(Icons.email, 'Email', data['email']),
                _buildDetailRow(Icons.badge, 'Designation', data['designation']),
                // 4. Company
                _buildDetailRow(Icons.business, 'Company', data['company']),
                // 5. Purpose
                _buildDetailRow(Icons.info_outline, 'Purpose', data['purpose']),
                // 6. Other Purpose
                _buildDetailRow(Icons.edit, 'Other Purpose', data['purposeOther']),
                // 7. Appointment
                _buildDetailRow(Icons.event_available, 'Appointment', data['appointment']),
                // 8. Department
                _buildDetailRow(Icons.apartment, 'Department', data['department']),
                // 9. Host
                _buildDetailRow(Icons.person_outline, 'Host', data['host']),
                // 10. Accompanying
                _buildDetailRow(Icons.group, 'Accompanying', data['accompanying']),
                                // 11. Accompanying Count
                _buildDetailRow(Icons.format_list_numbered, 'Accompanying Count', data['accompanyingCount']),
                // 12. Laptop
                _buildDetailRow(Icons.laptop, 'Laptop', data['laptop']),
                // 13. Laptop Details
                _buildDetailRow(Icons.laptop_mac, 'Laptop Details', data['laptopDetails']),
                // 14. Registered At
                if (data['timestamp'] != null)
                  _buildDetailRow(
                    Icons.access_time,
                    'Registered At',
                    (data['timestamp'] is Timestamp)
                        ? _formatDateOnly((data['timestamp'] as Timestamp).toDate())
                        : _formatDateOnly(data['timestamp']),
                  ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.qr_code, size: 18, color: Colors.white),
                    label: const Text('Generate Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () async {
                      // Only allow for manual_registrations
                      if (data.containsKey('fullName')) {
                        // Generate unique pass number
                        final passNo = await _generateUniquePassNo();
                        final passData = {
                          'passNo': passNo,
                          'visitorName': data['fullName'] ?? '',
                          'company': data['company'] ?? '',
                          'department': data['department'] ?? '',
                          'designation': data['designation'] ?? '',
                          'purpose': data['purpose'] ?? '',
                          'accompanyingVisitors': data['accompanyingCount'] ?? '',
                          'host': data['host'] ?? '',
                          'photo': data['photo'] ?? '', // Add photo field
                          'date': _formatDateOnly(DateTime.now()),
                          'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          'generated_at': FieldValue.serverTimestamp(),
                          'group': 'manual',
                        };
                        await FirebaseFirestore.instance.collection('passes').add(passData);
                        // Show success message and close dialog
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pass generated successfully for ${data['fullName']}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                                              } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pass generation is only available for manual registrations.')),
                            );
                          }
                        }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF6CA4FE), size: 22),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016)),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(color: Colors.black87),
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualPassDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pass;
  final double cardWidth;
  const _ManualPassDetailDialog({required this.pass, required this.cardWidth, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photo = pass['photo'] ?? pass['photoBase64'];
    Uint8List? imageBytes;
    if (photo != null && photo is String && photo.isNotEmpty) {
      try {
        imageBytes = const Base64Decoder().convert(photo);
      } catch (_) {
        imageBytes = null;
      }
    }
    Widget avatar;
    if (imageBytes != null) {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover),
        ),
      );
    } else {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 48),
      );
    }
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/rdl.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'RDL Technologies Pvt Ltd',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black, decoration: TextDecoration.none),
                    textAlign: TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 20, decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Pass No      : ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                            TextSpan(text: '${pass['passNo'] ?? pass['pass_no'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Visitor Name  : ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                            TextSpan(text: '${pass['visitorName'] ?? pass['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      if (pass['company'] != null && pass['company'].toString().isNotEmpty)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'Company      : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                              TextSpan(text: '${pass['company']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                            ],
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      if (pass['designation'] != null && pass['designation'].toString().isNotEmpty)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'Designation   : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                              TextSpan(text: '${pass['designation']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                            ],
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pass['accompanyingVisitors'] != null && pass['accompanyingVisitors'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Accompanying Count    : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['accompanyingVisitors']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['purpose'] != null && pass['purpose'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Purpose       : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['purpose']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['purposeOther'] != null && pass['purposeOther'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Other Purpose    : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['purposeOther']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['department'] != null && pass['department'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Department   : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['department']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['host'] != null && pass['host'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Host          : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['host']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['date'] != null)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Date     : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['date']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['time'] != null)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Time     : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['time']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  onPressed: () async {
                    final now = Timestamp.now();
                    try {
                      print('Attempting to update printed_at for pass: ${pass['id']}');
                      if (pass['id'] != null) {
                        await FirebaseFirestore.instance.collection('passes').doc(pass['id']).update({
                          'printed_at': now,
                        });
                        print('printed_at updated!');
                      }
                    } catch (e) {
                      print('Error updating printed_at: ${e.toString()}');
                    }
                    
                    // Save to Checked In/Out collection for status page
                    try {
                      print('Debug: pass data - ${pass.toString()}');
                      print('Debug: pass_id = ${pass['id']}');
                      print('Debug: visitor_name = ${pass['visitorName'] ?? pass['fullName'] ?? pass['v_name']}');
                      print('Debug: visitorId field = ${pass['visitorId']}');
                      print('Debug: visitor_id field = ${pass['visitor_id']}');
                      print('Debug: All pass keys = ${pass.keys.toList()}');
                      
                      // Check if visitor already exists in checked_in_out collection
                      // Use visitor_name as primary check since pass_id might be empty
                      final visitorName = pass['visitorName'] ?? pass['fullName'] ?? pass['v_name'] ?? '';
                      final passId = pass['id'] ?? '';
                      
                      // Try multiple possible field names for visitor_id
                      final visitorId = pass['visitorId']?.toString().isNotEmpty == true 
                          ? pass['visitorId'] 
                          : pass['visitor_id']?.toString().isNotEmpty == true
                              ? pass['visitor_id']
                              : pass['id'] ?? '';
                      
                      print('Debug: Final visitor_id = $visitorId');
                      
                      // If visitor_id is still empty, try to fetch it from manual_registrations collection
                      String finalVisitorId = visitorId;
                      if (finalVisitorId.isEmpty) {
                        try {
                          print('Debug: Trying to fetch visitor_id from manual_registrations collection for visitor: $visitorName');
                          final manualRegDocs = await FirebaseFirestore.instance
                              .collection('manual_registrations')
                              .where('fullName', isEqualTo: visitorName)
                              .limit(1)
                              .get();
                          
                          if (manualRegDocs.docs.isNotEmpty) {
                            final manualRegData = manualRegDocs.docs.first.data();
                            finalVisitorId = manualRegData['visitor_id'] ?? '';
                            print('Debug: Found visitor_id from manual_registrations: $finalVisitorId');
                          } else {
                            print('Debug: No manual registration found for visitor: $visitorName');
                          }
                        } catch (e) {
                          print('Debug: Error fetching visitor_id from manual_registrations: $e');
                        }
                      }
                      
                      print('Debug: Using final visitor_id = $finalVisitorId');
                      
                      Query existingQuery;
                      if (passId.isNotEmpty) {
                        existingQuery = FirebaseFirestore.instance
                            .collection('checked_in_out')
                            .where('pass_id', isEqualTo: passId);
                      } else {
                        existingQuery = FirebaseFirestore.instance
                            .collection('checked_in_out')
                            .where('visitor_name', isEqualTo: visitorName)
                            .where('status', isEqualTo: 'Checked In');
                      }
                      
                      final existingDocs = await existingQuery.get();
                      
                      if (existingDocs.docs.isEmpty) {
                        // Only add if visitor doesn't already exist
                      await FirebaseFirestore.instance.collection('checked_in_out').add({
                          'visitor_id': finalVisitorId,
                          'visitor_name': visitorName,
                        'check_in_time': FieldValue.serverTimestamp(),
                        'check_in_date': _formatDateOnly(now.toDate()),
                        'status': 'Checked In',
                          'pass_id': passId,
                        'created_at': FieldValue.serverTimestamp(),
                      });
                        print('Successfully saved to checked_in_out collection with visitor_id: $finalVisitorId');
                      } else {
                        print('Visitor already exists in checked_in_out collection');
                      }
                    } catch (e) {
                      print('Error saving to checked_in_out collection: ${e.toString()}');
                    }
                    
                    final logoBytes = await DefaultAssetBundle.of(context).load('assets/images/rdl.png');
                    final logoUint8List = logoBytes.buffer.asUint8List();
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async {
                        final pdf = pw.Document();
                        pdf.addPage(
                          pw.Page(
                            pageFormat: format,
                            build: (pw.Context context) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.all(18),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColor.fromInt(0xFF000000), width: 1),
                                  borderRadius: pw.BorderRadius.circular(12),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Container(
                                          width: 40,
                                          height: 40,
                                          child: pw.Image(pw.MemoryImage(logoUint8List)),
                                        ),
                                        pw.SizedBox(width: 12),
                                        pw.Text('RDL Technologies Pvt Ltd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Center(
                                      child: pw.Text('Visitor Pass', style: pw.TextStyle(color: PdfColor.fromInt(0xFFEF4444), fontWeight: pw.FontWeight.bold, fontSize: 18)),
                                    ),
                                    pw.SizedBox(height: 12),
                                    pw.Row(
                                      children: [
                                        if (imageBytes != null)
                                          pw.Container(
                                            width: 70,
                                            height: 70,
                                            decoration: pw.BoxDecoration(
                                              color: PdfColor.fromInt(0xFF6CA4FE),
                                              borderRadius: pw.BorderRadius.circular(4),
                                              image: pw.DecorationImage(
                                                image: pw.MemoryImage(imageBytes),
                                                fit: pw.BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        else
                                        pw.Container(
                                          width: 70,
                                          height: 70,
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFF6CA4FE),
                                            borderRadius: pw.BorderRadius.circular(4),
                                          ),
                                          child: pw.Icon(pw.IconData(0xe491), size: 48, color: PdfColor.fromInt(0xFFFFFFFF)),
                                        ),
                                        pw.SizedBox(width: 16),
                                        pw.Expanded(
                                          child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text('Pass No      : ${pass['passNo'] ?? pass['pass_no'] ?? 0}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                              pw.Text('Visitor Name : ${pass['visitorName'] ?? pass['fullName'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                              if (pass['company'] != null && pass['company'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Company      : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['company']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              if (pass['designation'] != null && pass['designation'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Designation   : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['designation']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 10),
                                    if (pass['accompanyingVisitors'] != null && pass['accompanyingVisitors'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Accompanying Count    : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['accompanyingVisitors']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['purpose'] != null && pass['purpose'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Purpose       : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['purpose']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['purposeOther'] != null && pass['purposeOther'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Other Purpose    : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['purposeOther']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['department'] != null && pass['department'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Department   : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['department']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['host'] != null && pass['host'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Host          : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['host']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['date'] != null)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Date     : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['date']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['time'] != null)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Time     : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['time']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                        return pdf.save();
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 

String _formatDateOnly(dynamic date) {
  if (date == null) return '';
  if (date is Timestamp) {
    final d = date.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  if (date is DateTime) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  try {
    final d = DateTime.parse(date.toString());
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return date.toString();
  }
}

class _AppointedVisitorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AppointedVisitorDetailsDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visitor Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Name: ${data['visitorName'] ?? data['fullName'] ?? 'N/A'}'),
            Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
            Text('Email: ${data['email'] ?? 'N/A'}'),
            Text('Company: ${data['company'] ?? 'N/A'}'),
            Text('Host: ${data['host'] ?? 'N/A'}'),
            Text('Purpose: ${data['purpose'] ?? 'N/A'}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditVisitorForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String collection;

  const _EditVisitorForm({
    required this.data,
    required this.docId,
    required this.collection,
    Key? key,
  }) : super(key: key);

  @override
  State<_EditVisitorForm> createState() => _EditVisitorFormState();
}

class _EditVisitorFormState extends State<_EditVisitorForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late TextEditingController designationController;
  late TextEditingController companyController;
  late TextEditingController hostController;
  late TextEditingController purposeController;
  late TextEditingController purposeOtherController;
  late TextEditingController appointmentController;
  late TextEditingController departmentController;
  late TextEditingController accompanyingController;
  late TextEditingController accompanyingCountController;
  late TextEditingController laptopController;
  late TextEditingController laptopDetailsController;

  String selectedAppointment = 'Yes';
  String selectedDepartment = 'Select Dept';
  String selectedAccompanying = 'No';
  String selectedLaptop = 'No';
  final List<String> yesNo = ['Yes', 'No'];
  final List<String> departments = [
    'Select Dept', 'HR', 'Admin', 'IT', 'Security', 'Stock', 'Finance', 'Marketing', 
    'Sales', 'Operations', 'Legal', 'Research', 'Development', 'Quality Assurance', 
    'Customer Support', 'Logistics', 'Procurement', 'Facilities', 'Training', 'Compliance'
  ];
  List<String> dropdownDepartments = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data
    fullNameController = TextEditingController(text: widget.data['fullName'] ?? '');
    mobileController = TextEditingController(text: widget.data['mobile'] ?? '');
    emailController = TextEditingController(text: widget.data['email'] ?? '');
    designationController = TextEditingController(text: widget.data['designation'] ?? '');
    companyController = TextEditingController(text: widget.data['company'] ?? '');
    hostController = TextEditingController(text: widget.data['host'] ?? '');
    purposeController = TextEditingController(text: widget.data['purpose'] ?? '');
    purposeOtherController = TextEditingController(text: widget.data['purposeOther'] ?? '');
    appointmentController = TextEditingController(text: widget.data['appointment'] ?? '');
    departmentController = TextEditingController(text: widget.data['department'] ?? '');
    accompanyingController = TextEditingController(text: widget.data['accompanying'] ?? '');
    accompanyingCountController = TextEditingController(text: widget.data['accompanyingCount']?.toString() ?? '');
    laptopController = TextEditingController(text: widget.data['laptop'] ?? '');
    laptopDetailsController = TextEditingController(text: widget.data['laptopDetails'] ?? '');

    // Set initial dropdown values
    selectedAppointment = appointmentController.text.isNotEmpty ? appointmentController.text : 'Yes';
    selectedDepartment = departmentController.text.isNotEmpty ? departmentController.text : 'Select Dept';
    selectedAccompanying = accompanyingController.text.isNotEmpty ? accompanyingController.text : 'No';
    selectedLaptop = laptopController.text.isNotEmpty ? laptopController.text : 'No';
    // Build the dropdown list
    dropdownDepartments = List<String>.from(departments);
    if (selectedDepartment.isNotEmpty && !dropdownDepartments.contains(selectedDepartment)) {
      dropdownDepartments.add(selectedDepartment);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    designationController.dispose();
    companyController.dispose();
    hostController.dispose();
    purposeController.dispose();
    purposeOtherController.dispose();
    appointmentController.dispose();
    departmentController.dispose();
    accompanyingController.dispose();
    accompanyingCountController.dispose();
    laptopController.dispose();
    laptopDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                children: [
              Text('Edit Visitor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: fullNameController,
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator: (value) => value?.isEmpty == true ? 'Please enter full name' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: mobileController,
                        decoration: InputDecoration(labelText: 'Mobile'),
                        validator: (value) => value?.isEmpty == true ? 'Please enter mobile number' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) => value?.isEmpty == true ? 'Please enter email' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: designationController,
                        decoration: InputDecoration(labelText: 'Designation'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: companyController,
                        decoration: InputDecoration(labelText: 'Company'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: hostController,
                        decoration: InputDecoration(labelText: 'Host'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: purposeController,
                        decoration: InputDecoration(labelText: 'Purpose'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: purposeOtherController,
                        decoration: InputDecoration(labelText: 'Other Purpose'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: departmentController,
                        decoration: InputDecoration(labelText: 'Department'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                        try {
                          await FirebaseFirestore.instance
                              .collection(widget.collection)
                              .doc(widget.docId)
                              .update({
                            'fullName': fullNameController.text,
                            'mobile': mobileController.text,
                            'email': emailController.text,
                            'designation': designationController.text,
                            'company': companyController.text,
                            'host': hostController.text,
                            'purpose': purposeController.text,
                            'purposeOther': purposeOtherController.text,
                            'department': departmentController.text,
                          });
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Visitor updated successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating visitor: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: Text('Update'),
                  ),
                ],
          ),
        ],
      ),
        ),
      ),
    );
  }
} 

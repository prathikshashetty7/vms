import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dashboard.dart' show VisitorsPage;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';

class KioskRegistrationsPage extends StatefulWidget {
  const KioskRegistrationsPage({Key? key}) : super(key: key);

  @override
  State<KioskRegistrationsPage> createState() => _KioskRegistrationsPageState();
}

class _KioskRegistrationsPageState extends State<KioskRegistrationsPage> {
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFD4E9FF),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final departmentMap = snapshot.data ?? {};
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Image.asset('assets/images/rdl.png', height: 36),
                  const SizedBox(width: 12),
                  const Text('Kiosk Registrations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF6CA4FE),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              automaticallyImplyLeading: false,
              bottom: const TabBar(
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
                // Tab 1: Kiosk Visitors
                _buildKioskVisitorList(context),
                // Tab 2: Generated Passes
                _buildGeneratedPassesList(context, departmentMap: departmentMap),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _fetchDepartmentMap() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('departments')
          .get()
          .timeout(const Duration(seconds: 5));
      final Map<String, String> departmentMap = {};
      for (var doc in snapshot.docs) {
        departmentMap[doc.id] = doc['name'] ?? '';
      }
      return departmentMap;
    } catch (e) {
      print('Error fetching departments: $e');
      return {};
    }
  }

  Widget _buildKioskVisitorList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('manual_registrations').where('group', isEqualTo: 'kiosk').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading kiosk visitors: ${snapshot.error}',
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No kiosk visitors found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Sort the documents in memory by timestamp
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp); // descending order
        });

        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final name = data['fullName'] ?? 'Unknown';
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              
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
                            backgroundColor: const Color(0xFF6CA4FE).withOpacity(0.13),
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
                                : Icon(Icons.qr_code, color: const Color(0xFF6CA4FE), size: 32),
                          ),
                          const SizedBox(width: 16),
                          // Name and date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name, 
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Color(0xFF091016), 
                                    fontSize: 17
                                  ), 
                                  softWrap: true, 
                                  overflow: TextOverflow.ellipsis, 
                                  maxLines: 1
                                ),
                                if (time != null)
                                  Text(
                                    '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE)),
                                    softWrap: true, 
                                    overflow: TextOverflow.ellipsis, 
                                    maxLines: 1
                                  ),
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
                                  color: Colors.white,
                                  onSelected: (value) async {
                                    if (value == 'view') {
                                      _showVisitorDetails(context, data);
                                    } else if (value == 'delete') {
                                      _confirmDeleteVisitor(context, docId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.remove_red_eye, color: Colors.blue), 
                                          SizedBox(width: 8), 
                                          Text('View')
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.delete, color: Colors.red), 
                                          SizedBox(width: 8), 
                                          Text('Delete')
                                        ],
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
          ),
        );
      },
    );
  }

  Widget _buildGeneratedPassesList(BuildContext context, {required Map<String, String> departmentMap}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('passes').where('group', isEqualTo: 'kiosk').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading generated passes: ${snapshot.error}',
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No generated passes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Sort the documents in memory by created_at
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = aData['created_at'] as Timestamp?;
          final bCreatedAt = bData['created_at'] as Timestamp?;
          
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          
          return bCreatedAt.compareTo(aCreatedAt); // descending order
        });

        String searchQuery = '';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, company, or host',
                  prefixIcon: const Icon(Icons.search),
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
                itemCount: docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                          data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                          data['host_name']?.toString().toLowerCase().contains(searchQuery) == true);
                }).length,
                itemBuilder: (context, index) {
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                            data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                            data['host_name']?.toString().toLowerCase().contains(searchQuery) == true);
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
                      backgroundColor: const Color(0xFF6CA4FE).withOpacity(0.15),
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
                                Text(
                                  data['v_name'] ?? '', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016)), 
                                  softWrap: true, 
                                  overflow: TextOverflow.visible, 
                                  maxLines: null
                                ),
                                const SizedBox(height: 4),
                                Text('Company: ${data['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                if (data['department'] != null && data['department'].toString().isNotEmpty)
                                  Text('Department: ${data['department']}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6CA4FE)),
                                    const SizedBox(width: 4),
                                    Text('Date: ${data['created_at'] != null && data['created_at'] is Timestamp ? _formatDateOnly((data['created_at'] as Timestamp).toDate()) : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                                        child: _KioskPassDetailDialog(pass: data, cardWidth: cardWidth),
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
    );
  }

  void _showVisitorDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _KioskVisitorDetailsDialog(
        data: data,
        color: const Color(0xFF6CA4FE),
        icon: Icons.qr_code,
        name: data['fullName'] ?? 'Unknown',
      ),
    );
  }

  void _showPassDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pass Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', data['v_name'] ?? 'N/A'),
            _detailRow('Contact', data['v_contactno'] ?? 'N/A'),
            _detailRow('Company', data['v_company_name'] ?? 'N/A'),
            _detailRow('Host', data['host_name'] ?? 'N/A'),
            _detailRow('Generated', _formatTimestamp(data['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute}';
    }
    return timestamp.toString();
  }

  Future<void> _printPass(BuildContext context, Map<String, dynamic> passData, Map<String, String> departmentMap) async {
    try {
      final pdf = pw.Document();
      
      // Generate QR code
      final qrCode = pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: json.encode(passData),
        width: 100,
        height: 100,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('VISITOR PASS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 20),
                    qrCode,
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Name: ${passData['v_name'] ?? 'N/A'}'),
                pw.Text('Contact: ${passData['v_contactno'] ?? 'N/A'}'),
                pw.Text('Company: ${passData['v_company_name'] ?? 'N/A'}'),
                pw.Text('Host: ${passData['host_name'] ?? 'N/A'}'),
                pw.Text('Generated: ${_formatTimestamp(passData['created_at'])}'),
                pw.SizedBox(height: 20),
                pw.Text('This pass is valid for today only.', style: pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing pass: $e')),
        );
      }
    }
  }

  void _confirmDeleteVisitor(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visitor'),
        content: const Text('Are you sure you want to delete this visitor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('manual_registrations')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visitor deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting visitor: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
          Icon(icon, color: const Color(0xFF6CA4FE), size: 22),
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

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _KioskPassDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pass;
  final double cardWidth;
  const _KioskPassDetailDialog({required this.pass, required this.cardWidth, Key? key}) : super(key: key);

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
          color: const Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover),
        ),
      );
    } else {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF6CA4FE),
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
                            const TextSpan(text: 'Pass No      : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                            TextSpan(text: '${pass['pass_no'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(text: 'Visitor Name  : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                            TextSpan(text: '${pass['v_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(text: 'Company      : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                              TextSpan(text: '${pass['v_company_name']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                            ],
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      if (pass['v_designation'] != null && pass['v_designation'].toString().isNotEmpty)
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(text: 'Designation   : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                              TextSpan(text: '${pass['v_designation']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
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
                    const TextSpan(text: 'Accompanying Count    : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                    const TextSpan(text: 'Purpose       : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                    const TextSpan(text: 'Other Purpose    : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                    const TextSpan(text: 'Department   : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['department']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(text: 'Host          : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['host_name']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['date'] != null)
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(text: 'Date     : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                    const TextSpan(text: 'Time     : ', style: TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                      print('Debug: visitor_name = ${pass['v_name']}');
                      print('Debug: visitorId field = ${pass['visitorId']}');
                      print('Debug: visitor_id field = ${pass['visitor_id']}');
                      print('Debug: All pass keys = ${pass.keys.toList()}');
                      
                      // Check if visitor already exists in checked_in_out collection
                      // Use visitor_name as primary check since pass_id might be empty
                      final visitorName = pass['v_name'] ?? '';
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
                                            child: pw.Center(
                                              child: pw.Icon(
                                                pw.IconData(0xe7fd), // person icon
                                                color: PdfColor.fromInt(0xFFFFFFFF),
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                        pw.SizedBox(width: 16),
                                        pw.Expanded(
                                          child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.RichText(
                                                text: pw.TextSpan(
                                                  children: [
                                                    pw.TextSpan(text: 'Pass No      : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColor.fromInt(0xFF091016))),
                                                    pw.TextSpan(text: '${pass['pass_no'] ?? 0}', style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 18, color: PdfColor.fromInt(0xFF091016))),
                                                  ],
                                                ),
                                              ),
                                              pw.RichText(
                                                text: pw.TextSpan(
                                                  children: [
                                                    pw.TextSpan(text: 'Visitor Name  : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColor.fromInt(0xFF091016))),
                                                    pw.TextSpan(text: '${pass['v_name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 18, color: PdfColor.fromInt(0xFF091016))),
                                                  ],
                                                ),
                                              ),
                                              if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Company      : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['v_company_name']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              if (pass['v_designation'] != null && pass['v_designation'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Designation   : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['v_designation']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
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
                                            pw.TextSpan(text: 'Accompanying Count    : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['accompanyingVisitors']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['purpose'] != null && pass['purpose'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Purpose       : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['purpose']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['purposeOther'] != null && pass['purposeOther'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Other Purpose    : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['purposeOther']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['department'] != null && pass['department'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Department   : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['department']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Host          : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['host_name']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['date'] != null)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Date     : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['date']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['time'] != null)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Time     : ', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['time']}', style: pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF091016), fontWeight: pw.FontWeight.normal)),
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

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _KioskVisitorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String name;
  
  const _KioskVisitorDetailsDialog({
    required this.data, 
    required this.color, 
    required this.icon, 
    required this.name, 
    Key? key
  }) : super(key: key);

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
                offset: const Offset(0, 6),
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
                            child: Icon(icon, color: color, size: 36),
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
                // Visitor details
                _buildDetailRow(Icons.phone, 'Mobile', data['mobile']),
                _buildDetailRow(Icons.email, 'Email', data['email']),
                _buildDetailRow(Icons.business, 'Company', data['company']),
                _buildDetailRow(Icons.badge, 'Designation', data['designation']),
                _buildDetailRow(Icons.info_outline, 'Purpose', data['purpose']),
                _buildDetailRow(Icons.edit, 'Other Purpose', data['purposeOther']),
                _buildDetailRow(Icons.event_available, 'Appointment', data['appointment']),
                _buildDetailRow(Icons.apartment, 'Department', data['department']),
                _buildDetailRow(Icons.person_outline, 'Host', data['host']),
                _buildDetailRow(Icons.group, 'Accompanying', data['accompanying']),
                _buildDetailRow(Icons.format_list_numbered, 'Accompanying Count', data['accompanyingCount']),
                _buildDetailRow(Icons.laptop, 'Laptop', data['laptop']),
                _buildDetailRow(Icons.laptop_mac, 'Laptop Details', data['laptopDetails']),
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
                      // Generate unique pass number
                      final random = Random();
                      int passNo;
                      bool exists = true;
                      final passesRef = FirebaseFirestore.instance.collection('passes');
                      do {
                        passNo = 1000 + random.nextInt(9000); // 4-digit number
                        final query = await passesRef.where('pass_no', isEqualTo: passNo).limit(1).get();
                        exists = query.docs.isNotEmpty;
                      } while (exists);

                      final passData = {
                        'pass_no': passNo,
                        'v_name': data['fullName'] ?? '',
                        'v_contactno': data['mobile'] ?? '',
                        'v_company_name': data['company'] ?? '',
                        'v_designation': data['designation'] ?? '',
                        'purpose': data['purpose'] ?? '',
                        'accompanyingVisitors': data['accompanyingCount'] ?? '',
                        'host_name': data['host'] ?? '',
                        'department': data['department'] ?? '',
                        'photo': data['photo'] ?? '',
                        'date': _formatDateOnly(DateTime.now()),
                        'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        'created_at': FieldValue.serverTimestamp(),
                        'registration_type': 'kiosk',
                        'group': 'kiosk',
                      };
                      await FirebaseFirestore.instance.collection('passes').add(passData);
                      // Show success message
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pass generated successfully for ${data['fullName']}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
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
          Icon(icon, color: const Color(0xFF6CA4FE), size: 22),
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

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

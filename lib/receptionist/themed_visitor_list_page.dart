import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'dashboard.dart' show VisitorsPage;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ThemedVisitorListPage extends StatelessWidget {
  final String collection;
  final String title;
  final IconData icon;
  final Color color;
  final String nameField;
  final String mobileField;
  final String timeField;
  const ThemedVisitorListPage({
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
        if (collection == 'manual_registrations') {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Image.asset('assets/images/rdl.png', height: 36),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Tab(text: 'Manual Registrations'),
                    Tab(text: 'Generated Passes'),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFFD4E9FF),
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
        } else if (collection == 'visitor' || collection == 'visitors') {
          // For appointed visitors, show as tabs like manual registrations
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Image.asset('assets/images/rdl.png', height: 36),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              body: TabBarView(
                children: [
                  _buildVisitorList(context),
                  _buildGeneratedPassesList(context, appointed: true, departmentMap: departmentMap),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF6CA4FE),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              automaticallyImplyLeading: false,
            ),
            backgroundColor: const Color(0xFFD4E9FF),
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

  // Helper to build the visitor list (for manual registrations and other types)
  Widget _buildVisitorList(BuildContext context, {bool showPassButton = true}) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .orderBy(timeField, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No visitors found.', style: TextStyle(color: color)));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final name = data[nameField] ?? 'Unknown';
              final time = (data[timeField] as Timestamp?)?.toDate();
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
                            backgroundColor: color.withOpacity(0.13),
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
                                      if (collection == 'visitor' || collection == 'visitors') {
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
                                            color: color,
                                            icon: icon,
                                            name: data['v_name'] ?? '',
                                            docId: docId,
                                            collection: collection,
                                            hostName: hostName,
                                          ),
                                        );
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) => _VisitorDetailsDialog(
                                            data: data,
                                            color: color,
                                            icon: icon,
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
  Widget _buildGeneratedPassesList(BuildContext context, {bool appointed = false, required Map<String, String> departmentMap}) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('passes') // Always use 'passes' collection
            .orderBy('generated_at', descending: true)
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
                  itemCount: docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!appointed) {
                      // Manual registrations: keep old logic
                      return (data['fullName']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['company']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['host']?.toString().toLowerCase().contains(searchQuery) == true);
                    } else {
                      // Appointed visitors: use correct fields
                      return searchQuery.isEmpty ||
                        (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                         data['host_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                         data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true);
                    }
                  }).length,
                  itemBuilder: (context, index) {
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!appointed) {
                        return (data['fullName']?.toString().toLowerCase().contains(searchQuery) == true ||
                                data['company']?.toString().toLowerCase().contains(searchQuery) == true ||
                                data['host']?.toString().toLowerCase().contains(searchQuery) == true);
                      } else {
                        return searchQuery.isEmpty ||
                          (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                           data['host_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                           data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true);
                      }
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
                    if (!appointed) {
                      // ... existing manual registrations card ...
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
                                    Text(data['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    const SizedBox(height: 4),
                                    Text('Host:  ${data['host'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                            final now = Timestamp.now();
                                            if (data['id'] != null) {
                                              await FirebaseFirestore.instance.collection('passes').doc(data['id']).update({
                                                'printed_at': now,
                                              });
                                              await FirebaseFirestore.instance.collection('visitor').add({
                                                'fullName': data['fullName'],
                                                'v_name': data['fullName'],
                                                'mobile': data['mobile'],
                                                'email': data['email'],
                                                'designation': data['designation'],
                                                'company': data['company'],
                                                'host': data['host'],
                                                'purpose': data['purpose'],
                                                'purposeOther': data['purposeOther'],
                                                'appointment': data['appointment'],
                                                'department': data['department'],
                                                'accompanying': data['accompanying'],
                                                'accompanyingCount': data['accompanyingCount'],
                                                'laptop': data['laptop'],
                                                'laptopDetails': data['laptopDetails'],
                                                'photo': data['photo'],
                                                'printed_at': now,
                                                'v_date': now,
                                                'checked_out': false,
                                              });
                                            } else if (data['visitorId'] != null) {
                                              await FirebaseFirestore.instance.collection('visitor').doc(data['visitorId']).update({
                                                'printed_at': now,
                                              });
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
                                                                      pw.Text('Visitor Name : ${data['fullName'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            pw.SizedBox(height: 10),
                                                            if (data['company'] != null && data['company'].toString().isNotEmpty)
                                                              pw.Text('Company : ${data['company']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['designation'] != null && data['designation'].toString().isNotEmpty)
                                                              pw.Text('Designation: ${data['designation']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['host'] != null && data['host'].toString().isNotEmpty)
                                                              pw.Text('Host     : ${data['host']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['department'] != null && data['department'].toString().isNotEmpty)
                                                              pw.Text('Department: ${data['department']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['purpose'] != null && data['purpose'].toString().isNotEmpty)
                                                              pw.Text('Purpose  : ${data['purpose']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['purposeOther'] != null && data['purposeOther'].toString().isNotEmpty)
                                                              pw.Text('Other Purpose: ${data['purposeOther']}', style: pw.TextStyle(fontSize: 13)),
                                                            if (data['laptop'] != null && data['laptop'].toString().isNotEmpty) ...[
                                                              if (data['laptop'].toString().toLowerCase() == 'no')
                                                                pw.Text('Laptop   : No', style: pw.TextStyle(fontSize: 13)),
                                                              if (data['laptop'].toString().toLowerCase() != 'no' && data['laptopDetails'] != null && data['laptopDetails'].toString().isNotEmpty)
                                                                pw.Text('Laptop   : ${data['laptopDetails']}', style: pw.TextStyle(fontSize: 13)),
                                                            ],
                                                            if (data['accompanyingCount'] != null && data['accompanyingCount'].toString().isNotEmpty)
                                                              pw.Text('Accompanying Count: ${data['accompanyingCount']}', style: pw.TextStyle(fontSize: 13)),
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
                    } else {
                      // Appointed visitor card (match manual style)
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
                                    Text(data['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    const SizedBox(height: 4),
                                    if (data['host_name'] != null && data['host_name'].toString().isNotEmpty)
                                      Text('Host: ${data['host_name']}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    Text('Company: ${data['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    if (data['departmentId'] != null && departmentMap[data['departmentId']] != null)
                                      Text('Department: ${departmentMap[data['departmentId']]}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6CA4FE)),
                                        const SizedBox(width: 4),
                                        Text('Date: ${data['v_date'] is Timestamp ? _formatDateOnly((data['v_date'] as Timestamp).toDate()) : _formatDateOnly(data['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                            String departmentName = departmentMap[data['departmentId']] ?? data['departmentId'].toString();
                                            showGeneralDialog(
                                              context: context,
                                              barrierColor: Colors.white,
                                              barrierDismissible: true,
                                              barrierLabel: 'Pass',
                                              pageBuilder: (context, anim1, anim2) {
                                                return LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final double cardWidth = constraints.maxWidth > 360 ? 340 : (constraints.maxWidth - 20).clamp(200.0, 340.0);
                                                    return Center(
                                                      child: SingleChildScrollView(
                                                        child: _AppointedPassDetailDialog(pass: data, cardWidth: cardWidth, departmentName: departmentName),
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
                    }
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
    if (collection == 'visitor' || collection == 'visitors') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AppointedVisitorEditForm(data: data, docId: docId, collection: collection),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _EditVisitorForm(data: data, docId: docId, collection: collection),
      );
    }
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
              await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
              Navigator.of(context).pop();
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
                      backgroundColor: Color(0xFF6CA4FE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Generate Pass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      // Only allow for manual_registrations
                      if (data.containsKey('fullName')) {
                        final passData = {
                          'fullName': data['fullName'] ?? '',
                          'mobile': data['mobile'] ?? '',
                          'email': data['email'] ?? '',
                          'designation': data['designation'] ?? '',
                          'company': data['company'] ?? '',
                          'purpose': data['purpose'] ?? '',
                          'purposeOther': data['purposeOther'] ?? '',
                          'appointment': data['appointment'] ?? '',
                          'department': data['department'] ?? '',
                          'host': data['host'] ?? '',
                          'accompanying': data['accompanying'] ?? '',
                          'accompanyingCount': data['accompanyingCount'] ?? '',
                          'laptop': data['laptop'] ?? '',
                          'laptopDetails': data['laptopDetails'] ?? '',
                          'photo': data['photo'] ?? '',
                          'generated_at': FieldValue.serverTimestamp(),
                        };
                        await FirebaseFirestore.instance.collection('passes').add(passData);
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
                                        child: _ManualPassDetailDialog(pass: passData, cardWidth: cardWidth),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ).then((_) {
                          DefaultTabController.of(context)?.animateTo(1);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pass generation is only available for manual registrations.')),
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
    final photo = pass['photo'];
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black, decoration: TextDecoration.none),
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
              child: Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                      Text('Visitor Name : ${pass['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pass['company'] != null && pass['company'].toString().isNotEmpty)
              Text('Company : ${pass['company']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['designation'] != null && pass['designation'].toString().isNotEmpty)
              Text('Designation: ${pass['designation']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['host'] != null && pass['host'].toString().isNotEmpty)
              Text('Host     : ${pass['host']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['department'] != null && pass['department'].toString().isNotEmpty)
              Text('Department: ${pass['department']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['purpose'] != null && pass['purpose'].toString().isNotEmpty)
              Text('Purpose  : ${pass['purpose']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['purposeOther'] != null && pass['purposeOther'].toString().isNotEmpty)
              Text('Other Purpose: ${pass['purposeOther']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['laptop'] != null && pass['laptop'].toString().isNotEmpty) ...[
              if (pass['laptop'].toString().toLowerCase() == 'no')
                Text('Laptop   : No', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
              if (pass['laptop'].toString().toLowerCase() != 'no' && pass['laptopDetails'] != null && pass['laptopDetails'].toString().isNotEmpty)
                Text('Laptop   : ${pass['laptopDetails']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            ],
            if (pass['accompanyingCount'] != null && pass['accompanyingCount'].toString().isNotEmpty)
              Text('Accompanying Count: ${pass['accompanyingCount']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                              pw.Text('Visitor Name : ${pass['fullName'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 10),
                                    if (pass['company'] != null && pass['company'].toString().isNotEmpty)
                                      pw.Text('Company : ${pass['company']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['designation'] != null && pass['designation'].toString().isNotEmpty)
                                      pw.Text('Designation: ${pass['designation']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['host'] != null && pass['host'].toString().isNotEmpty)
                                      pw.Text('Host     : ${pass['host']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['department'] != null && pass['department'].toString().isNotEmpty)
                                      pw.Text('Department: ${pass['department']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['purpose'] != null && pass['purpose'].toString().isNotEmpty)
                                      pw.Text('Purpose  : ${pass['purpose']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['purposeOther'] != null && pass['purposeOther'].toString().isNotEmpty)
                                      pw.Text('Other Purpose: ${pass['purposeOther']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['laptop'] != null && pass['laptop'].toString().isNotEmpty) ...[
                                      if (pass['laptop'].toString().toLowerCase() == 'no')
                                        pw.Text('Laptop   : No', style: pw.TextStyle(fontSize: 13)),
                                      if (pass['laptop'].toString().toLowerCase() != 'no' && pass['laptopDetails'] != null && pass['laptopDetails'].toString().isNotEmpty)
                                        pw.Text('Laptop   : ${pass['laptopDetails']}', style: pw.TextStyle(fontSize: 13)),
                                    ],
                                    if (pass['accompanyingCount'] != null && pass['accompanyingCount'].toString().isNotEmpty)
                                      pw.Text('Accompanying Count: ${pass['accompanyingCount']}', style: pw.TextStyle(fontSize: 13)),
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

  String selectedPurpose = 'Select Purpose';
  String selectedAppointment = 'Yes';
  String selectedDepartment = 'Select Dept';
  String selectedAccompanying = 'No';
  String selectedLaptop = 'No';

  final List<String> purposes = [
    'Select Purpose', 'Business Meeting', 'Interview', 'Delivery', 'Maintenance', 'Other',
  ];
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
    selectedPurpose = purposeController.text.isNotEmpty ? purposeController.text : 'Select Purpose';
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Edit Visitor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF091016),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildEditField(fullNameController, 'Full Name', Icons.person, TextInputType.text, true),
                  const SizedBox(height: 14),
                  _buildEditField(mobileController, 'Mobile', Icons.phone, TextInputType.phone, true),
                  const SizedBox(height: 14),
                  _buildEditField(emailController, 'Email', Icons.email, TextInputType.emailAddress, false),
                  const SizedBox(height: 14),
                  _buildEditField(companyController, 'Company', Icons.business, TextInputType.text, false),
                  const SizedBox(height: 14),
                  _buildEditField(designationController, 'Designation', Icons.badge, TextInputType.text, false),
                  const SizedBox(height: 14),
                  _buildEditField(hostController, 'Host', Icons.person_outline, TextInputType.text, false),
                  const SizedBox(height: 14),
                  // Purpose dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Purpose of the Visit',
                      labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPurpose,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        items: purposes.map((e) => DropdownMenuItem(
                          value: e,
                          enabled: e != 'Select Purpose',
                          child: Text(e, style: TextStyle(color: e == 'Select Purpose' ? Color(0xFF888888) : Colors.black)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedPurpose = v;
                              purposeController.text = v;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (selectedPurpose == 'Other')
                    _buildEditField(purposeOtherController, 'Other Purpose', Icons.edit, TextInputType.text, false),
                  const SizedBox(height: 14),
                  // Appointment dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Do you have an appointment',
                      labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAppointment,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        items: yesNo.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedAppointment = v;
                              appointmentController.text = v;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Department dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('department').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final departments = snapshot.data!.docs
                        .map((doc) => doc['d_name'] as String)
                        .where((name) => name.isNotEmpty)
                        .toList();
                      // Ensure the visitor's current department is in the list
                      if (selectedDepartment.isNotEmpty && !departments.contains(selectedDepartment)) {
                        departments.add(selectedDepartment);
                      }
                      return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Department',
                      labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                            value: departments.contains(selectedDepartment) ? selectedDepartment : (departments.isNotEmpty ? departments.first : 'Select Dept'),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                            items: ['Select Dept', ...departments].map((e) => DropdownMenuItem(
                          value: e,
                          enabled: e != 'Select Dept',
                          child: Text(e, style: TextStyle(color: e == 'Select Dept' ? Color(0xFF888888) : Colors.black)),
                        )).toList(),
                        onChanged: (v) {
                              if (v != null && v != 'Select Dept') {
                                setState(() => selectedDepartment = v);
                              } else {
                                setState(() => selectedDepartment = 'Select Dept');
                          }
                        },
                      ),
                    ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // Accompanying dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Accompanying Visitors (if any)',
                      labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAccompanying,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        items: yesNo.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedAccompanying = v;
                              accompanyingController.text = v;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (selectedAccompanying == 'Yes')
                    _buildEditField(accompanyingCountController, 'Number of Accompanying Visitors', Icons.group, TextInputType.number, false),
                  const SizedBox(height: 14),
                  // Laptop dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Do you carrying a laptop?',
                      labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLaptop,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        items: yesNo.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedLaptop = v;
                              laptopController.text = v;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (selectedLaptop == 'Yes')
                    _buildEditField(laptopDetailsController, 'Enter the laptop model & serial number', Icons.laptop, TextInputType.text, false),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final updatedData = {
                            'fullName': fullNameController.text,
                            'mobile': mobileController.text,
                            'email': emailController.text,
                            'designation': designationController.text,
                            'company': companyController.text,
                            'host': hostController.text,
                            'purpose': purposeController.text,
                            'purposeOther': purposeOtherController.text,
                            'appointment': appointmentController.text,
                            'department': selectedDepartment == 'Select Dept' ? '' : selectedDepartment,
                            'accompanying': accompanyingController.text,
                            'accompanyingCount': accompanyingCountController.text,
                            'laptop': laptopController.text,
                            'laptopDetails': laptopDetailsController.text,
                          };
                          await FirebaseFirestore.instance.collection(widget.collection).doc(widget.docId).update(updatedData);
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6CA4FE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        elevation: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, TextInputType type, bool required) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF6CA4FE), width: 2),
        ),
      ),
    );
  }
} 

class AppointedVisitorEditForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String collection;
  const AppointedVisitorEditForm({required this.data, required this.docId, required this.collection, Key? key}) : super(key: key);

  @override
  State<AppointedVisitorEditForm> createState() => _AppointedVisitorEditFormState();
}

class _AppointedVisitorEditFormState extends State<AppointedVisitorEditForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController designationController;
  late TextEditingController companyController;
  late TextEditingController contactController;
  late TextEditingController totalNoController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['v_name'] ?? '');
    emailController = TextEditingController(text: widget.data['v_email'] ?? '');
    designationController = TextEditingController(text: widget.data['v_designation'] ?? '');
    companyController = TextEditingController(text: widget.data['v_company_name'] ?? '');
    contactController = TextEditingController(text: widget.data['v_contactno'] ?? '');
    totalNoController = TextEditingController(text: widget.data['v_totalno']?.toString() ?? '1');
    selectedDate = (widget.data['v_date'] is Timestamp)
        ? (widget.data['v_date'] as Timestamp).toDate()
        : DateTime.now();
    selectedTime = widget.data['v_time'] != null ? _parseTime(widget.data['v_time']) : TimeOfDay.now();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    designationController.dispose();
    companyController.dispose();
    contactController.dispose();
    totalNoController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return TimeOfDay.now();
    final parts = timeStr.split(":");
    if (parts.length < 2) return TimeOfDay.now();
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Edit Appointed Visitor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF091016),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildEditField(nameController, 'Name', Icons.person, TextInputType.text, true),
                  const SizedBox(height: 14),
                  _buildEditField(emailController, 'Email', Icons.email, TextInputType.emailAddress, false),
                  const SizedBox(height: 14),
                  _buildEditField(designationController, 'Designation', Icons.badge, TextInputType.text, false),
                  const SizedBox(height: 14),
                  _buildEditField(companyController, 'Company', Icons.business, TextInputType.text, false),
                  const SizedBox(height: 14),
                  _buildEditField(contactController, 'Contact No', Icons.phone, TextInputType.phone, true),
                  const SizedBox(height: 14),
                  _buildEditField(totalNoController, 'Total Visitors', Icons.group, TextInputType.number, false),
                  const SizedBox(height: 14),
                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                        ),
                        controller: TextEditingController(
                          text: selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Time Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                        ),
                        controller: TextEditingController(
                          text: selectedTime != null ? selectedTime!.format(context) : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final updatedData = {
                            'v_name': nameController.text,
                            'v_email': emailController.text,
                            'v_designation': designationController.text,
                            'v_company_name': companyController.text,
                            'v_contactno': contactController.text,
                            'v_totalno': int.tryParse(totalNoController.text) ?? 1,
                            'v_date': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                            'v_time': selectedTime != null ? selectedTime!.format(context) : null,
                          };
                          await FirebaseFirestore.instance.collection(widget.collection).doc(widget.docId).update(updatedData);
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6CA4FE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        elevation: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, TextInputType type, bool required) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF6CA4FE), width: 2),
        ),
      ),
    );
  }
} 

class _AppointedVisitorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String name;
  final String docId;
  final String collection;
  final String hostName;
  const _AppointedVisitorDetailsDialog({required this.data, required this.color, required this.icon, required this.name, required this.docId, required this.collection, required this.hostName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    CircleAvatar(
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
                _buildDetailRow(Icons.phone, 'Contact No', data['v_contactno']),
                _buildDetailRow(Icons.email, 'Email', data['v_email']),
                _buildDetailRow(Icons.badge, 'Designation', data['v_designation']),
                _buildDetailRow(Icons.business, 'Company', data['v_company_name']),
                _buildDetailRow(Icons.group, 'Total Visitors', data['v_totalno']),
                _buildDetailRow(Icons.calendar_today, 'Date', (data['v_date'] is Timestamp) ? _formatDateOnly((data['v_date'] as Timestamp).toDate()) : data['v_date']),
                _buildDetailRow(Icons.access_time, 'Time', data['v_time']),
                // Host row: show host name directly
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF6CA4FE), size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        'Host: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016)),
                      ),
                      Expanded(
                        child: Text(
                          hostName,
                          style: const TextStyle(color: Colors.black87),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6CA4FE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Generate Pass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final passData = {
                        'v_name': data['v_name'] ?? '',
                        'v_email': data['v_email'] ?? '',
                        'v_designation': data['v_designation'] ?? '',
                        'v_company_name': data['v_company_name'] ?? '',
                        'v_contactno': data['v_contactno'] ?? '',
                        'v_totalno': data['v_totalno'] ?? 1,
                        'v_date': data['v_date'],
                        'v_time': data['v_time'],
                        'emp_id': data['emp_id'],
                        'host_name': hostName,
                        'departmentId': data['departmentId'],
                        'generated_at': FieldValue.serverTimestamp(),
                        'visitor_doc_id': docId,
                      };
                      await FirebaseFirestore.instance.collection('passes').add(passData); // Use 'passes' collection
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pass generated and saved!')));
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

class _AppointedPassDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pass;
  final double cardWidth;
  final String departmentName;
  const _AppointedPassDetailDialog({required this.pass, required this.cardWidth, required this.departmentName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black, decoration: TextDecoration.none),
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
              child: Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person, size: 48, color: Color(0xFF6CA4FE)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visitor Name : ${pass['v_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
              Text('Company : ${pass['v_company_name']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
              Text('Host     : ${pass['host_name']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (departmentName.isNotEmpty)
              Text('Department: $departmentName', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['v_designation'] != null && pass['v_designation'].toString().isNotEmpty)
              Text('Designation: ${pass['v_designation']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['v_contactno'] != null && pass['v_contactno'].toString().isNotEmpty)
              Text('Contact  : ${pass['v_contactno']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['v_email'] != null && pass['v_email'].toString().isNotEmpty)
              Text('Email    : ${pass['v_email']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['v_totalno'] != null && pass['v_totalno'].toString().isNotEmpty)
              Text('Total Visitors: ${pass['v_totalno']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
            if (pass['v_date'] != null)
              Text('Date     : ${pass['v_date'] is Timestamp ? _formatDateOnly((pass['v_date'] as Timestamp).toDate()) : _formatDateOnly(pass['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016), decoration: TextDecoration.none), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                              pw.Text('Visitor Name : ${pass['v_name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 10),
                                    if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                                      pw.Text('Company : ${pass['v_company_name']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
                                      pw.Text('Host     : ${pass['host_name']}', style: pw.TextStyle(fontSize: 13)),
                                    if (departmentName.isNotEmpty)
                                      pw.Text('Department: $departmentName', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['v_designation'] != null && pass['v_designation'].toString().isNotEmpty)
                                      pw.Text('Designation: ${pass['v_designation']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['v_contactno'] != null && pass['v_contactno'].toString().isNotEmpty)
                                      pw.Text('Contact  : ${pass['v_contactno']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['v_email'] != null && pass['v_email'].toString().isNotEmpty)
                                      pw.Text('Email    : ${pass['v_email']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['v_totalno'] != null && pass['v_totalno'].toString().isNotEmpty)
                                      pw.Text('Total Visitors: ${pass['v_totalno']}', style: pw.TextStyle(fontSize: 13)),
                                    if (pass['v_date'] != null)
                                      pw.Text('Date     : ${pass['v_date'] is Timestamp ? _formatDateOnly((pass['v_date'] as Timestamp).toDate()) : _formatDateOnly(pass['v_date'])}', style: pw.TextStyle(fontSize: 13)),
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
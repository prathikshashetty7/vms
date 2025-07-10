import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/visitor_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostPassesPage extends StatefulWidget {
  const HostPassesPage({Key? key}) : super(key: key);

  @override
  State<HostPassesPage> createState() => _HostPassesPageState();
}

class _HostPassesPageState extends State<HostPassesPage> {
  String? departmentId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceptionistDepartment();
  }

  Future<void> _fetchReceptionistDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('receptionist').where('email', isEqualTo: user.email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        departmentId = data['departmentId'];
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
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD4E9FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: const Text('Host-Generated Passes'),
        backgroundColor: Color(0xFF6CA4FE),
        automaticallyImplyLeading: false,
      ),
      body: departmentId == null
          ? const Center(child: Text('Could not determine department.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('visitor')
                  .where('pass_generated', isEqualTo: true)
                  .where('departmentId', isEqualTo: departmentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No visitors found.', style: TextStyle(color: Colors.orange)));
                }
                final passes = snapshot.data!.docs;
                return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: passes.length,
        itemBuilder: (context, index) {
                    final doc = passes[index];
                    final pass = doc.data() as Map<String, dynamic>;
                    Widget avatar;
                    final photoBase64 = pass['photoBase64'];
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
                                      Text(pass['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016))),
                                      const SizedBox(height: 4),
                                      Text('Host: ${pass['host_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
                                      Text('Company: ${pass['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
                                      if (pass['department'] != null && pass['department'].toString().isNotEmpty)
                                        Text('Department: ${pass['department']}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
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
                                Text('Date: ${_formatDate(pass['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 16, color: Color(0xFF6CA4FE)),
                                const SizedBox(width: 4),
                                Text('Time: ${pass['v_time'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.print, color: Color(0xFF898AC4)),
                                tooltip: 'Print',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: _PassDetailDialog(pass: pass),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 1,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            // Already here
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/receptionist_reports');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_rounded),
            label: 'Host Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Add Visitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

class _PassDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pass;
  const _PassDetailDialog({required this.pass});

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
    Uint8List? imageBytes;
    if (pass['photoBase64'] != null && pass['photoBase64'] != '') {
      imageBytes = base64Decode(pass['photoBase64']);
    }
    // Load logo bytes for PDF
    final logoProvider = AssetImage('assets/images/rdl.png');
    // This is a workaround for PDF: you need to load the bytes asynchronously, so we'll use rootBundle
    return LayoutBuilder(
      builder: (context, constraints) {
        double dialogWidth = 340;
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth < 380) {
          dialogWidth = screenWidth * 0.95;
        } else if (screenWidth < 500) {
          dialogWidth = screenWidth * 0.90;
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Container(
                width: dialogWidth,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/rdl.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        const Text('RDL Technologies Pvt Ltd', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Visitor Pass', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBytes != null)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Color(0xFF6CA4FE),
                              borderRadius: BorderRadius.circular(4),
                              image: DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover),
                            ),
                          )
                        else
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
                              Text('Visitor Name : ${pass['v_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF091016))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                      Text('Company : ${pass['v_company_name']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                    Text('Host     : ${pass['host_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                    Text('Department: ${pass['department'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                    Text('Date     : ${_formatDate(pass['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                    Text('Time     : ${pass['v_time'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                          onPressed: () async {
                            // Load logo bytes for PDF
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
                                            // Logo and company name
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
                                                      pw.Text('Visitor Name : ${pass['v_name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            pw.SizedBox(height: 10),
                                            if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                                              pw.Text('Company : ${pass['v_company_name']}', style: pw.TextStyle(fontSize: 13)),
                                            pw.Text('Host     : ${pass['host_name'] ?? ''}', style: pw.TextStyle(fontSize: 13)),
                                            pw.Text('Department: ${pass['department'] ?? ''}', style: pw.TextStyle(fontSize: 13)),
                                            pw.Text('Date     : ${_formatDate(pass['v_date'])}', style: pw.TextStyle(fontSize: 13)),
                                            pw.Text('Time     : ${pass['v_time'] ?? ''}', style: pw.TextStyle(fontSize: 13)),
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
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 
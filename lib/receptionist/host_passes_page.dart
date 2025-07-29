import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart' show VisitorsPage;

class HostPassesPage extends StatefulWidget {
  const HostPassesPage({Key? key}) : super(key: key);

  @override
  State<HostPassesPage> createState() => _HostPassesPageState();
}

class _HostPassesPageState extends State<HostPassesPage> {
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
    return Scaffold(
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Host Passes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Color(0xFF6CA4FE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('passes')
                  .where('pass_generated_by', isEqualTo: 'host')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No host-generated passes found.'));
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No host-generated passes found.'));
            }
            
            // Sort the documents in memory by created_at
            final sortedDocs = docs.toList();
            sortedDocs.sort((a, b) {
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
                      return (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                              data['host_name']?.toString().toLowerCase().contains(searchQuery) == true);
                    }).length,
        itemBuilder: (context, index) {
                      final filteredDocs = sortedDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['v_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                                data['v_company_name']?.toString().toLowerCase().contains(searchQuery) == true ||
                                data['host_name']?.toString().toLowerCase().contains(searchQuery) == true);
                      }).toList();
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                    Widget avatar;
                      Uint8List? imageBytes;
                      final photo = data['photoBase64'];
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
                                    Text(data['v_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                      const SizedBox(height: 4),
                                    Text('Company: ${data['v_company_name'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                                    if (data['department'] != null && data['department'].toString().isNotEmpty)
                                      Text('Department: ${data['department']}', style: const TextStyle(fontSize: 14, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6CA4FE)),
                                const SizedBox(width: 4),
                                        Text('Date: ${data['created_at'] != null && data['created_at'] is Timestamp ? _formatDate((data['created_at'] as Timestamp).toDate()) : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016)), softWrap: true, overflow: TextOverflow.visible, maxLines: null),
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
                                                            child: _HostPassDetailDialog(pass: data, cardWidth: cardWidth),
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
            // Already here (Visitors)
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VisitorsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          }
        },
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
    );
  }
}

class _HostPassDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pass;
  final double cardWidth;
  const _HostPassDetailDialog({required this.pass, required this.cardWidth, Key? key}) : super(key: key);

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
    final photo = pass['photoBase64'] ?? pass['photo'];
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
                            TextSpan(text: '${pass['pass_no'] ?? pass['passNo'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
                          ],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Visitor Name  : ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF091016), decoration: TextDecoration.none)),
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
                              TextSpan(text: 'Company      : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
                              TextSpan(text: 'Designation   : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
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
            if (pass['v_totalno'] != null && pass['v_totalno'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Accompanying Count    : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['v_totalno']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
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
            if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Host          : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['host_name']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
                  ],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            if (pass['created_at'] != null)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Date     : ', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    TextSpan(text: '${pass['created_at'] is Timestamp ? _formatDate((pass['created_at'] as Timestamp).toDate()) : pass['created_at']}', style: const TextStyle(fontSize: 18, color: Color(0xFF091016), fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
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
                        await FirebaseFirestore.instance.collection('checked_in_out').add({
                        'visitor_name': pass['v_name'] ?? '',
                          'visitor_photo': pass['photoBase64'] ?? '',
                          'check_in_time': FieldValue.serverTimestamp(),
                        'check_in_date': _formatDateOnly(now.toDate()),
                          'status': 'Checked In',
                        'pass_id': pass['id'] ?? '',
                          'created_at': FieldValue.serverTimestamp(),
                        });
                        print('Successfully saved to checked_in_out collection');
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
                                              pw.Text('Pass No      : ${pass['pass_no'] ?? pass['passNo'] ?? 0}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                              pw.Text('Visitor Name : ${pass['v_name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                              if (pass['v_company_name'] != null && pass['v_company_name'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Company      : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['v_company_name']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                                if (pass['v_designation'] != null && pass['v_designation'].toString().isNotEmpty)
                                                pw.RichText(
                                                  text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: 'Designation   : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                                      pw.TextSpan(text: '${pass['v_designation']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      pw.SizedBox(height: 10),
                                    if (pass['v_totalno'] != null && pass['v_totalno'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Accompanying Count    : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['v_totalno']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
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
                                    if (pass['department'] != null && pass['department'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Department   : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['department']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['host_name'] != null && pass['host_name'].toString().isNotEmpty)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Host          : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['host_name']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    if (pass['created_at'] != null)
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          children: [
                                            pw.TextSpan(text: 'Date     : ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                            pw.TextSpan(text: '${pass['created_at'] is Timestamp ? _formatDate((pass['created_at'] as Timestamp).toDate()) : pass['created_at']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
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
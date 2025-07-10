import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:vms/receptionist/host_passes_page.dart' show PassDetailDialog;

class CreatePassPage extends StatefulWidget {
  const CreatePassPage({Key? key}) : super(key: key);

  @override
  State<CreatePassPage> createState() => _CreatePassPageState();
}

class _CreatePassPageState extends State<CreatePassPage> {
  String? hostName;
  String? hostDocId;
  String? departmentId;
  String? departmentName;
  bool loading = true;
  final Map<int, File?> _visitorImages = {};
  final Map<int, Uint8List?> _visitorImageBytes = {};
  final Map<int, String?> _visitorImageUrls = {};
  final Map<int, String?> _visitorImageBase64 = {};
  final ImagePicker _picker = ImagePicker();

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
      String? deptId = data['departmentId'];
      String? deptName = data['department'];
      if ((deptName == null || deptName.isEmpty) && deptId != null && deptId.isNotEmpty) {
        final deptSnap = await FirebaseFirestore.instance.collection('department').doc(deptId).get();
        if (deptSnap.exists) {
          deptName = deptSnap.data()?['d_name'] ?? deptId;
        } else {
          deptName = deptId;
        }
      }
      setState(() {
        hostName = data['emp_name'] ?? '';
        hostDocId = doc.id;
        departmentId = deptId ?? '';
        departmentName = deptName ?? '';
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  Future<void> _pickImage(int idx, String visitorId) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        Uint8List bytes = await pickedFile.readAsBytes();
        String base64Str = base64Encode(bytes);
        setState(() {
          _visitorImageBytes[idx] = bytes;
          _visitorImageBase64[idx] = base64Str;
        });
        try {
          await FirebaseFirestore.instance.collection('visitor').doc(visitorId).update({'photoBase64': base64Str});
        } catch (e) {
          print('Firestore update error: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
        }
      }
    } catch (e) {
      print('Image pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image selection failed: $e')));
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
                final visitors = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).where((v) {
                  final date = v['v_date'];
                  if (date == null) return false;
                  DateTime visitDate;
                  if (date is Timestamp) {
                    visitDate = date.toDate();
                  } else if (date is DateTime) {
                    visitDate = date;
                  } else {
                    try {
                      visitDate = DateTime.parse(date.toString());
                    } catch (_) {
                      return false;
                    }
                  }
                  final now = DateTime.now();
                  return !visitDate.isBefore(DateTime(now.year, now.month, now.day));
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, idx) {
                    final v = visitors[idx];
                    final visitorId = snapshot.data!.docs[idx].id;
                    Widget avatar;
                    final photoBase64 = v['photoBase64'] ?? _visitorImageBase64[idx];
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
                                Stack(
                                  children: [
                                    avatar,
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _pickImage(idx, visitorId),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                      if (departmentName != null && departmentName!.isNotEmpty)
                                        Text('Department: $departmentName', style: const TextStyle(fontSize: 14, color: Color(0xFF091016))),
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
                                  await FirebaseFirestore.instance.collection('visitor').doc(visitorId).update({
                                    'pass_generated': true,
                                    'departmentId': departmentId ?? '',
                                    'department': departmentName ?? '',
                                    'host_name': hostName ?? '',
                                  });
                                  // Prepare pass data
                                  dynamic vDate = v['v_date'];
                                  Timestamp passDate;
                                  if (vDate is Timestamp) {
                                    passDate = vDate;
                                  } else if (vDate is DateTime) {
                                    passDate = Timestamp.fromDate(vDate);
                                  } else {
                                    try {
                                      passDate = Timestamp.fromDate(DateTime.parse(vDate.toString()));
                                    } catch (_) {
                                      passDate = Timestamp.now();
                                    }
                                  }
                                  final passData = {
                                    'visitorId': visitorId,
                                    'v_name': v['v_name'] ?? '',
                                    'v_company_name': v['v_company_name'] ?? '',
                                    'department': departmentName ?? '',
                                    'departmentId': departmentId ?? '',
                                    'host_name': hostName ?? '',
                                    'v_date': passDate,
                                    'v_time': v['v_time'],
                                    'photoBase64': v['photoBase64'] ?? _visitorImageBase64[idx],
                                  };
                                  await FirebaseFirestore.instance.collection('passes').add({
                                    ...passData,
                                    'created_at': FieldValue.serverTimestamp(),
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 24), // Add this for better responsiveness
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: PassDetailDialog(pass: passData, showPrint: false),
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
  final Uint8List? imageBytes;
  final String departmentName;
  const _VisitorPassCard({required this.visitor, required this.hostName, required this.passNo, this.imageBytes, required this.departmentName});

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (imageBytes != null) {
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover),
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
              avatar,
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
          const SizedBox(height: 10),
          if (visitor['v_company_name'] != null && visitor['v_company_name'].toString().isNotEmpty)
            Text('Company : ${visitor['v_company_name']}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
          Text('Host     : $hostName', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
          Text('Department: $departmentName', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
          Text('Date     : ${_formatDate(visitor['v_date'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
          Text('Time     : ${visitor['v_time'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF091016))),
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
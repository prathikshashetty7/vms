import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class QRCodeVisitorsPage extends StatefulWidget {
  const QRCodeVisitorsPage({Key? key}) : super(key: key);

  @override
  State<QRCodeVisitorsPage> createState() => _QRCodeVisitorsPageState();
}

class _QRCodeVisitorsPageState extends State<QRCodeVisitorsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E9FF),
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/images/rdl.png', height: 36),
              const SizedBox(width: 12),
              const Text('QR Code Registrations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        body: TabBarView(
          children: [
            _buildVisitorList(context),
            _buildGeneratedPassesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('manual_registrations')
            .where('source', isEqualTo: 'qr_code')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No QR code visitors found.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['fullName'] ?? 'Unknown';
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              Uint8List? imageBytes;
              final photo = data['photo'];
              if (photo != null && photo is String && photo.isNotEmpty) {
                try {
                  imageBytes = const Base64Decoder().convert(photo);
                } catch (_) {
                  imageBytes = null;
                }
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x22005FFE),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                        child: imageBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.black, size: 32),
                      ),
                      const SizedBox(width: 16),
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
                      Text(data['department'] ?? '', style: const TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
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

  Widget _buildGeneratedPassesList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('passes')
            .where('source', isEqualTo: 'qr_code')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No passes found.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['v_name'] ?? data['visitorName'] ?? 'Unknown';
              final passNo = data['pass_no'] ?? data['passNo'] ?? '';
              final department = data['department'] ?? '';
              Uint8List? imageBytes;
              final photo = data['photoBase64'] ?? data['photo'];
              if (photo != null && photo is String && photo.isNotEmpty) {
                try {
                  imageBytes = const Base64Decoder().convert(photo);
                } catch (_) {
                  imageBytes = null;
                }
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x22005FFE),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                        child: imageBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              )
                            : const Icon(Icons.badge, color: Colors.black, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016), fontSize: 17), softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1),
                            Text('Pass No: $passNo', style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE))),
                          ],
                        ),
                      ),
                      Text(department, style: const TextStyle(color: Color(0xFF6CA4FE), fontWeight: FontWeight.bold)),
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

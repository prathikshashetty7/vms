import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart' show VisitorsPage;

class QRCodeVisitorsPage extends StatefulWidget {
  const QRCodeVisitorsPage({Key? key}) : super(key: key);

  @override
  State<QRCodeVisitorsPage> createState() => _QRCodeVisitorsPageState();
}

class _QRCodeVisitorsPageState extends State<QRCodeVisitorsPage> {
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
            .collection('visitor')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No visitors found.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['fullName'] ?? data['name'] ?? 'Unknown';
              final email = data['email'] ?? '';
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
                            if (email.isNotEmpty)
                              Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE)), softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1),
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
            .where('group', isEqualTo: 'qr_code')
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
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['v_name'] ?? data['visitorName'] ?? 'Unknown';
              final email = data['email'] ?? '';
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
                            if (email.isNotEmpty)
                              Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE)), softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1),
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
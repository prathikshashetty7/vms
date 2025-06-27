import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
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
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color(0x22005FFE),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
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
                  final name = data[nameField] ?? 'Unknown';
                  final mobile = data[mobileField] ?? '';
                  final time = (data[timeField] as Timestamp?)?.toDate();
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6FAFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22005FFE),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.13),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016))),
                      subtitle: Text('Mobile: $mobile', style: const TextStyle(color: Color(0xFF6CA4FE))),
                      trailing: time != null
                          ? Text(
                              '${time.day}/${time.month}/${time.year}\n${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF005FFE)),
                            )
                          : null,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _VisitorDetailsDialog(
                            data: data,
                            color: color,
                            icon: icon,
                            name: name,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 3,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/host_passes');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/manual_entry');
          } else if (index == 3) {
            // Already here
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

class _VisitorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String name;
  const _VisitorDetailsDialog({required this.data, required this.color, required this.icon, required this.name, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.13),
                  child: Icon(icon, color: color),
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
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
            ...data.entries.map((entry) {
              if (entry.key == 'timestamp') {
                final time = (entry.value as Timestamp?)?.toDate();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        time != null
                            ? '${time.day}/${time.month}/${time.year}  ${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                            : 'N/A',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }
              if (entry.key == 'photo' && entry.value != null && entry.value != '') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: MemoryImage(const Base64Decoder().convert(entry.value)),
                    ),
                  ),
                );
              }
              if (entry.value == null || entry.value.toString().isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(_iconForKey(entry.key), size: 18, color: color.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      '${_prettifyKey(entry.key)}: ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _prettifyKey(String key) {
    switch (key) {
      case 'fullName':
        return 'Name';
      case 'mobile':
        return 'Mobile';
      case 'email':
        return 'Email';
      case 'company':
        return 'Company';
      case 'host':
        return 'Host';
      case 'purpose':
        return 'Purpose';
      case 'appointment':
        return 'Appointment';
      case 'department':
        return 'Department';
      case 'accompanying':
        return 'Accompanying';
      case 'accompanyingCount':
        return 'Accompanying Count';
      case 'laptop':
        return 'Laptop';
      case 'laptopDetails':
        return 'Laptop Details';
      case 'purposeOther':
        return 'Other Purpose';
      case 'visitor':
        return 'Visitor';
      case 'passcode':
        return 'Passcode';
      case 'status':
        return 'Status';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'fullName':
        return Icons.person;
      case 'mobile':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'company':
        return Icons.business;
      case 'host':
        return Icons.person_outline;
      case 'purpose':
        return Icons.info_outline;
      case 'appointment':
        return Icons.event_available;
      case 'department':
        return Icons.apartment;
      case 'accompanying':
        return Icons.group;
      case 'accompanyingCount':
        return Icons.format_list_numbered;
      case 'laptop':
        return Icons.laptop;
      case 'laptopDetails':
        return Icons.laptop_mac;
      case 'purposeOther':
        return Icons.edit;
      case 'visitor':
        return Icons.person;
      case 'passcode':
        return Icons.vpn_key;
      case 'status':
        return Icons.verified_user;
      default:
        return Icons.label;
    }
  }
} 
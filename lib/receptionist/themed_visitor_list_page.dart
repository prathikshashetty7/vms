import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';
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
                final mobile = data[mobileField] ?? '';
                final time = (data[timeField] as Timestamp?)?.toDate();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.18),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016), fontSize: 16)),
                    subtitle: Text('Mobile: $mobile', style: const TextStyle(color: Color(0xFF6CA4FE), fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => _showEditVisitorSheet(context, data, docId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteVisitor(context, docId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                          onPressed: () {
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
                      ],
                    ),
                  ),
                );
              },
            );
          },
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

  void _showEditVisitorSheet(BuildContext context, Map<String, dynamic> data, String docId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['fullName']);
    final mobileController = TextEditingController(text: data['mobile']);
    final emailController = TextEditingController(text: data['email']);
    final companyController = TextEditingController(text: data['company']);
    final purposeController = TextEditingController(text: data['purpose']);
    final appointmentController = TextEditingController(text: data['appointment']);
    final departmentController = TextEditingController(text: data['department']);
    final hostController = TextEditingController(text: data['host']);
    final accompanyingController = TextEditingController(text: data['accompanying']);
    final accompanyingCountController = TextEditingController(text: data['accompanyingCount']);
    final laptopController = TextEditingController(text: data['laptop']);
    final laptopDetailsController = TextEditingController(text: data['laptopDetails']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Visitor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                ),
                TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(labelText: 'Mobile'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Mobile cannot be empty' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
                ),
                TextFormField(
                  controller: companyController,
                  decoration: InputDecoration(labelText: 'Company'),
                  validator: (value) => value!.isEmpty ? 'Company cannot be empty' : null,
                ),
                TextFormField(
                  controller: purposeController,
                  decoration: InputDecoration(labelText: 'Purpose'),
                  validator: (value) => value!.isEmpty ? 'Purpose cannot be empty' : null,
                ),
                TextFormField(
                  controller: appointmentController,
                  decoration: InputDecoration(labelText: 'Appointment'),
                  validator: (value) => value!.isEmpty ? 'Appointment cannot be empty' : null,
                ),
                TextFormField(
                  controller: departmentController,
                  decoration: InputDecoration(labelText: 'Department'),
                  validator: (value) => value!.isEmpty ? 'Department cannot be empty' : null,
                ),
                TextFormField(
                  controller: hostController,
                  decoration: InputDecoration(labelText: 'Host'),
                  validator: (value) => value!.isEmpty ? 'Host cannot be empty' : null,
                ),
                TextFormField(
                  controller: accompanyingController,
                  decoration: InputDecoration(labelText: 'Accompanying'),
                  validator: (value) => value!.isEmpty ? 'Accompanying cannot be empty' : null,
                ),
                TextFormField(
                  controller: accompanyingCountController,
                  decoration: InputDecoration(labelText: 'Accompanying Count'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Accompanying Count cannot be empty' : null,
                ),
                TextFormField(
                  controller: laptopController,
                  decoration: InputDecoration(labelText: 'Laptop'),
                  validator: (value) => value!.isEmpty ? 'Laptop cannot be empty' : null,
                ),
                TextFormField(
                  controller: laptopDetailsController,
                  decoration: InputDecoration(labelText: 'Laptop Details'),
                  validator: (value) => value!.isEmpty ? 'Laptop Details cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final updatedData = {
                        'fullName': nameController.text,
                        'mobile': mobileController.text,
                        'email': emailController.text,
                        'company': companyController.text,
                        'purpose': purposeController.text,
                        'appointment': appointmentController.text,
                        'department': departmentController.text,
                        'host': hostController.text,
                        'accompanying': accompanyingController.text,
                        'accompanyingCount': int.tryParse(accompanyingCountController.text) ?? 0,
                        'laptop': laptopController.text,
                        'laptopDetails': laptopDetailsController.text,
                      };
                      await FirebaseFirestore.instance.collection(collection).doc(docId).update(updatedData);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6CA4FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVisitor(BuildContext context, String docId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this visitor? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor deleted successfully!')),
      );
    }
  }
}

class _VisitorDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String name;
  const _VisitorDetailsDialog({required this.data, required this.color, required this.icon, required this.name, Key? key}) : super(key: key);

  @override
  State<_VisitorDetailsDialog> createState() => _VisitorDetailsDialogState();
}

class _VisitorDetailsDialogState extends State<_VisitorDetailsDialog> {
  bool _isPassGenerated = false;
  Map<String, dynamic>? _passDetails;

  @override
  void initState() {
    super.initState();
    _checkPassStatus();
  }

  Future<void> _checkPassStatus() async {
    final passRef = FirebaseFirestore.instance.collection('visitorPasses').doc(widget.data['_id']);
    final passDoc = await passRef.get();
    if (passDoc.exists) {
      setState(() {
        _isPassGenerated = true;
        _passDetails = passDoc.data() as Map<String, dynamic>;
      });
    }
  }

  Future<void> _generatePass() async {
    final passRef = FirebaseFirestore.instance.collection('visitorPasses').doc(widget.data['_id']);
    await passRef.set({
      'visitorId': widget.data['_id'],
      'fullName': widget.data['fullName'],
      'mobile': widget.data['mobile'],
      'email': widget.data['email'],
      'company': widget.data['company'],
      'purpose': widget.data['purpose'],
      'purposeOther': widget.data['purposeOther'],
      'appointment': widget.data['appointment'],
      'department': widget.data['department'],
      'host': widget.data['host'],
      'accompanying': widget.data['accompanying'],
      'accompanyingCount': widget.data['accompanyingCount'],
      'laptop': widget.data['laptop'],
      'laptopDetails': widget.data['laptopDetails'],
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      _isPassGenerated = true;
      _passDetails = widget.data; // Store the full visitor data as pass details
    });
  }

  Future<void> _printPass() async {
    final passRef = FirebaseFirestore.instance.collection('visitorPasses').doc(widget.data['_id']);
    final passDoc = await passRef.get();
    if (passDoc.exists) {
      final passData = passDoc.data() as Map<String, dynamic>;
      await Printing.layoutPdf(onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) => pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Visitor Pass', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  pw.Text('Name: ${passData['fullName'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Mobile: ${passData['mobile'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Email: ${passData['email'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Company: ${passData['company'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Purpose: ${passData['purpose'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Appointment: ${passData['appointment'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Department: ${passData['department'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Host: ${passData['host'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Accompanying: ${passData['accompanying'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Accompanying Count: ${passData['accompanyingCount'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Laptop: ${passData['laptop'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Laptop Details: ${passData['laptopDetails'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Timestamp: ${passData['timestamp'] ?? ''}', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        );
        return pdf.save();
      });
    }
  }

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
                  backgroundColor: widget.color.withOpacity(0.13),
                  child: Icon(widget.icon, color: widget.color),
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      color: widget.color,
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
            if (!_isPassGenerated)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _generatePass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Generate Pass'),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._displayFields(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _printPass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Print Pass'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _displayFields() {
    final List<Widget> fields = [];
    final List<String> displayOrder = [
      'photo',
      'fullName',
      'mobile',
      'email',
      'company',
      'purpose',
      'purposeOther',
      'appointment',
      'department',
      'host',
      'accompanying',
      'accompanyingCount',
      'laptop',
      'laptopDetails',
      'timestamp',
    ];

    for (final key in displayOrder) {
      final value = widget.data[key];
      if (value == null || value.toString().isEmpty) continue;

      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(_iconForKey(key), size: 18, color: widget.color.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                '${_prettifyKey(key)}: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: widget.color),
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return fields;
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
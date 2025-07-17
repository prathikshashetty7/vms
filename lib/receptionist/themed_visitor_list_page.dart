import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dashboard.dart' show VisitorsPage;

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
                final time = (data[timeField] as Timestamp?)?.toDate();
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
                              : Icon(icon, color: color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091016), fontSize: 17)),
                              if (time != null)
                                Text(
                                  '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF6CA4FE)),
                                ),
                            ],
                          ),
                        ),
                        Row(
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
            label: 'Checked In',
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

  void _showEditVisitorSheet(BuildContext context, Map<String, dynamic> data, String docId) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: data['fullName'] ?? '');
    final mobileController = TextEditingController(text: data['mobile'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final companyController = TextEditingController(text: data['company'] ?? '');
    final hostController = TextEditingController(text: data['host'] ?? '');
    final purposeController = TextEditingController(text: data['purpose'] ?? '');
    final purposeOtherController = TextEditingController(text: data['purposeOther'] ?? '');
    final appointmentController = TextEditingController(text: data['appointment'] ?? '');
    final departmentController = TextEditingController(text: data['department'] ?? '');
    final accompanyingController = TextEditingController(text: data['accompanying'] ?? '');
    final accompanyingCountController = TextEditingController(text: data['accompanyingCount']?.toString() ?? '');
    final laptopController = TextEditingController(text: data['laptop'] ?? '');
    final laptopDetailsController = TextEditingController(text: data['laptopDetails'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
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
                    _buildEditField(hostController, 'Host', Icons.person_outline, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(purposeController, 'Purpose', Icons.info_outline, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(purposeOtherController, 'Other Purpose', Icons.edit, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(appointmentController, 'Appointment', Icons.event_available, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(departmentController, 'Department', Icons.apartment, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(accompanyingController, 'Accompanying', Icons.group, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(accompanyingCountController, 'Accompanying Count', Icons.format_list_numbered, TextInputType.number, false),
                    const SizedBox(height: 14),
                    _buildEditField(laptopController, 'Laptop', Icons.laptop, TextInputType.text, false),
                    const SizedBox(height: 14),
                    _buildEditField(laptopDetailsController, 'Laptop Details', Icons.laptop_mac, TextInputType.text, false),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final updatedData = {
                              'fullName': fullNameController.text,
                              'mobile': mobileController.text,
                              'email': emailController.text,
                              'company': companyController.text,
                              'host': hostController.text,
                              'purpose': purposeController.text,
                              'purposeOther': purposeOtherController.text,
                              'appointment': appointmentController.text,
                              'department': departmentController.text,
                              'accompanying': accompanyingController.text,
                              'accompanyingCount': accompanyingCountController.text,
                              'laptop': laptopController.text,
                              'laptopDetails': laptopDetailsController.text,
                            };
                            await FirebaseFirestore.instance.collection(collection).doc(docId).update(updatedData);
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
                            child: Icon(icon, color: color, size: 36),
                          ),
                    const SizedBox(width: 18),
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
                _buildDetailRow(Icons.phone, 'Mobile', data['mobile']),
                _buildDetailRow(Icons.email, 'Email', data['email']),
                _buildDetailRow(Icons.business, 'Company', data['company']),
                _buildDetailRow(Icons.person_outline, 'Host', data['host']),
                _buildDetailRow(Icons.info_outline, 'Purpose', data['purpose']),
                _buildDetailRow(Icons.edit, 'Other Purpose', data['purposeOther']),
                _buildDetailRow(Icons.event_available, 'Appointment', data['appointment']),
                _buildDetailRow(Icons.apartment, 'Department', data['department']),
                _buildDetailRow(Icons.group, 'Accompanying', data['accompanying']),
                _buildDetailRow(Icons.format_list_numbered, 'Accompanying Count', data['accompanyingCount']),
                _buildDetailRow(Icons.laptop, 'Laptop', data['laptop']),
                _buildDetailRow(Icons.laptop_mac, 'Laptop Details', data['laptopDetails']),
                if (data['timestamp'] != null)
                  _buildDetailRow(
                    Icons.access_time,
                    'Registered At',
                    (data['timestamp'] is Timestamp)
                        ? (data['timestamp'] as Timestamp).toDate().toString()
                        : data['timestamp'].toString(),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 
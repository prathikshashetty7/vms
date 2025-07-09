import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageEmployees extends StatefulWidget {
  final String? currentDepartmentId;
  const ManageEmployees({Key? key, this.currentDepartmentId}) : super(key: key);

  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees> {
  final TextEditingController _empIdController = TextEditingController();
  final TextEditingController _empNameController = TextEditingController();
  final TextEditingController _empEmailController = TextEditingController();
  final TextEditingController _empPasswordController = TextEditingController();
  final TextEditingController _empContNoController = TextEditingController();
  final TextEditingController _empAddressController = TextEditingController();
  String? _selectedRole = 'Host'; // Default to Host
  String? _editingId;
  String? _editingCollection;
  String? get _currentDepartmentId => widget.currentDepartmentId;
  bool _obscurePassword = true;
  final FocusNode _empIdFocus = FocusNode();
  final FocusNode _empNameFocus = FocusNode();
  final FocusNode _empEmailFocus = FocusNode();
  final FocusNode _empPasswordFocus = FocusNode();
  final FocusNode _empContNoFocus = FocusNode();
  final FocusNode _empAddressFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // No need to fetch departmentId here
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _empNameController.dispose();
    _empEmailController.dispose();
    _empPasswordController.dispose();
    _empContNoController.dispose();
    _empAddressController.dispose();
    _empIdFocus.dispose();
    _empNameFocus.dispose();
    _empEmailFocus.dispose();
    _empPasswordFocus.dispose();
    _empContNoFocus.dispose();
    _empAddressFocus.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateEmployee() async {
    final empId = _empIdController.text.trim();
    final empName = _empNameController.text.trim();
    final empEmail = _empEmailController.text.trim();
    final empPassword = _empPasswordController.text.trim();
    final empContNo = _empContNoController.text.trim();
    final empAddress = _empAddressController.text.trim();
    final role = 'Host'; // Always Host
    if ([empId, empName, empEmail, empPassword, empContNo, empAddress].any((e) => e == null || e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      print('DEBUG: Not adding host - missing field.');
      return;
    }
    if (_currentDepartmentId == null || _currentDepartmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Department ID not found. Cannot add host.')),
      );
      print('DEBUG: Not adding host - departmentId missing.');
      return;
    }
    final employeeData = {
      'emp_id': empId,
      'emp_name': empName,
      'emp_email': empEmail,
      'emp_password': empPassword,
      'emp_contno': empContNo,
      'emp_address': empAddress,
      'role': role,
      'departmentId': _currentDepartmentId,
    };
    print('DEBUG: Add/Update host with data: $employeeData');
    try {
      if (_editingId == null) {
        // Add new host
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: empEmail,
          password: empPassword,
        );
        await FirebaseFirestore.instance.collection('host').add(employeeData);
        print('DEBUG: Host added to Firestore.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Host added successfully!')),
        );
      } else {
        // Update existing host
        await FirebaseFirestore.instance.collection('host').doc(_editingId).update(employeeData);
        print('DEBUG: Host updated in Firestore.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Host updated successfully!')),
        );
      }
    } catch (e) {
      print('DEBUG: Error adding/updating host: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.toString()}')),
      );
    }
    _empIdController.clear();
    _empNameController.clear();
    _empEmailController.clear();
    _empPasswordController.clear();
    _empContNoController.clear();
    _empAddressController.clear();
    _selectedRole = 'Host';
    _editingId = null;
    _editingCollection = null;
    setState(() {});
  }

  Future<void> _deleteEmployee(String id, String collectionName) async {
    await FirebaseFirestore.instance.collection(collectionName).doc(id).delete();
    setState(() {});
  }

  void _startEdit(DocumentSnapshot doc, String collectionName) {
    _editingId = doc.id;
    _editingCollection = collectionName;
    _empIdController.text = doc['emp_id'] ?? '';
    _empNameController.text = doc['emp_name'] ?? '';
    _empEmailController.text = doc['emp_email'] ?? '';
    _empPasswordController.text = doc['emp_password'] ?? '';
    _empContNoController.text = doc['emp_contno'] ?? '';
    _empAddressController.text = doc['emp_address'] ?? '';
    _selectedRole = doc['role'] ?? null;
    setState(() {});
  }

  Future<List<DropdownMenuItem<String>>> _getRoleDropdownItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('roles').get();
    return snapshot.docs
        .map((doc) => DropdownMenuItem<String>(
              value: doc['role_name'],
              child: Text(doc['role_name']),
            ))
        .toList();
  }

  Future<void> _updateHostsDepartmentId() async {
    if (_currentDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department ID not found.')),
      );
      return;
    }
    final hostQuery = await FirebaseFirestore.instance
        .collection('host')
        .where('departmentId', isNull: true)
        .get();
    for (var doc in hostQuery.docs) {
      await doc.reference.update({'departmentId': _currentDepartmentId});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All hosts updated with departmentId!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    // Receptionists list
    final receptionistStream = _currentDepartmentId == null
        ? null
        : FirebaseFirestore.instance.collection('receptionist')
            .where('departmentId', isEqualTo: _currentDepartmentId)
            .snapshots();
    // Hosts list
    final hostStream = _currentDepartmentId == null
        ? null
        : FirebaseFirestore.instance.collection('host')
            .where('departmentId', isEqualTo: _currentDepartmentId)
            .snapshots();

    void showEmployeeForm([DocumentSnapshot? doc, String? collectionName]) {
      if (doc != null && collectionName != null) {
        _startEdit(doc, collectionName);
      } else {
        _editingId = null;
        _editingCollection = null;
        _empIdController.clear();
        _empNameController.clear();
        _empEmailController.clear();
        _empPasswordController.clear();
        _empContNoController.clear();
        _empAddressController.clear();
        _selectedRole = 'Host'; // Always Host
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: isLargeScreen ? 32 : 16,
                right: isLargeScreen ? 32 : 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ReceptionistTheme.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _editingId == null ? 'Add Host' : 'Edit Host',
                        style: ReceptionistTheme.heading.copyWith(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _empIdController,
                        focusNode: _empIdFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_empNameFocus),
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Employee ID',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _empNameController,
                        focusNode: _empNameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_empEmailFocus),
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Employee Name',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _empEmailController,
                        focusNode: _empEmailFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_empPasswordFocus),
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      StatefulBuilder(
                        builder: (context, setStateSB) {
                          return TextField(
                        controller: _empPasswordController,
                            focusNode: _empPasswordFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(_empContNoFocus),
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setStateSB(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                        ),
                            obscureText: _obscurePassword,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _empContNoController,
                        focusNode: _empContNoFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_empAddressFocus),
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Contact Number',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _empAddressController,
                        focusNode: _empAddressFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {},
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Address',
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _addOrUpdateEmployee();
                              Navigator.of(context).pop();
                            },
                            icon: Icon(_editingId == null ? Icons.add : Icons.update, color: Colors.white),
                            label: Text(_editingId == null ? 'Add' : 'Update', style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editingId == null ? ReceptionistTheme.primary : ReceptionistTheme.text,
                              padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 30 : 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
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

    Widget _customHeader() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: const BoxDecoration(
          color: Color(0xFF6CA4FE),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 32),
            const SizedBox(width: 12),
            const Text('Manage Employees', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD4E9FF),
      body: Column(
        children: [
          _customHeader(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Lists
                  Expanded(
                    child: ListView(
                      children: [
                        _buildEmployeeList('host', 'Hosts', showEmployeeForm),
                        // Removed Receptionists section
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ], // <-- Close the children list for Column
      ), // <-- Close the Column
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => showEmployeeForm(),
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Add Employee',
      ),
    );
  }

  Widget _buildEmployeeList(String collectionName, String title, void Function([DocumentSnapshot?, String?]) showEmployeeForm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: ReceptionistTheme.subheading),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: collectionName == 'host' && _currentDepartmentId != null
              ? FirebaseFirestore.instance.collection('host').where('departmentId', isEqualTo: _currentDepartmentId).snapshots()
              : FirebaseFirestore.instance.collection(collectionName).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No $title found.'));
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.black),
                    title: Text(doc['emp_name'] ?? '', style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                    subtitle: Text('ID: ${doc['emp_id']}, Role: ${doc['role']}', style: ReceptionistTheme.body.copyWith(color: Colors.black54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => showEmployeeForm(doc, collectionName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.black),
                          onPressed: () => _deleteEmployee(doc.id, collectionName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Colors.black),
                          onPressed: () {
                            // Add your view logic here
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
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({Key? key}) : super(key: key);

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
  String? _selectedRole;
  String? _editingId;
  String? _editingCollection;

  Future<void> _addOrUpdateEmployee() async {
    final empId = _empIdController.text.trim();
    final empName = _empNameController.text.trim();
    final empEmail = _empEmailController.text.trim();
    final empPassword = _empPasswordController.text.trim();
    final empContNo = _empContNoController.text.trim();
    final empAddress = _empAddressController.text.trim();
    final role = _selectedRole;
    if ([empId, empName, empEmail, empPassword, empContNo, empAddress, role].any((e) => e == null || e.isEmpty)) return;
    
    final collectionName = role == 'Host' ? 'host' : 'receptionist';

    final employeeData = {
      'emp_id': empId,
      'emp_name': empName,
      'emp_email': empEmail,
      'emp_password': empPassword,
      'emp_contno': empContNo,
      'emp_address': empAddress,
      'role': role,
    };

    if (_editingId == null) {
      // Add new employee
      await FirebaseFirestore.instance.collection(collectionName).add(employeeData);
    } else {
      // Update existing employee
      if (_editingCollection != null && _editingCollection != collectionName) {
        // Role has changed, so move the document
        await FirebaseFirestore.instance.collection(_editingCollection!).doc(_editingId!).delete();
        await FirebaseFirestore.instance.collection(collectionName).doc(_editingId!).set(employeeData);
      } else {
        await FirebaseFirestore.instance.collection(collectionName).doc(_editingId!).update(employeeData);
      }
      _editingId = null;
      _editingCollection = null;
    }

    _empIdController.clear();
    _empNameController.clear();
    _empEmailController.clear();
    _empPasswordController.clear();
    _empContNoController.clear();
    _empAddressController.clear();
    _selectedRole = null;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

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
        _selectedRole = null;
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
                  gradient: DeptTheme.deptGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: DeptTheme.deptPrimary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  child: FutureBuilder<List<DropdownMenuItem<String>>>(
                    future: _getRoleDropdownItems(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _editingId == null ? 'Add Employee' : 'Edit Employee',
                            style: DeptTheme.heading.copyWith(fontSize: 20, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _empIdController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Employee ID',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _empNameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Employee Name',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _empEmailController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _empPasswordController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _empContNoController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Contact Number',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _empAddressController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Address',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                _selectedRole = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Role',
                              filled: true,
                              fillColor: DeptTheme.deptLight,
                              hintStyle: DeptTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: DeptTheme.deptPrimary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
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
                                label: Text(_editingId == null ? 'Add' : 'Update', style: DeptTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _editingId == null ? DeptTheme.deptPrimary : DeptTheme.deptDark,
                                  padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 30 : 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Employees', style: DeptTheme.appBarTitle),
        backgroundColor: DeptTheme.deptPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Lists
            Expanded(
              child: ListView(
                children: [
                  _buildEmployeeList('host', 'Hosts', showEmployeeForm),
                  _buildEmployeeList('receptionist', 'Receptionists', showEmployeeForm),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DeptTheme.deptPrimary,
        onPressed: () => showEmployeeForm(),
        child: const Icon(Icons.add, color: Colors.white),
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
          child: Text(title, style: DeptTheme.subheading),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    gradient: DeptTheme.deptGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: DeptTheme.deptPrimary.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(doc['emp_name'] ?? '', style: DeptTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                    subtitle: Text('ID: ${doc['emp_id']}, Role: ${doc['role']}', style: DeptTheme.body.copyWith(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: DeptTheme.deptPrimary),
                          onPressed: () => showEmployeeForm(doc, collectionName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: DeptTheme.deptPrimary),
                          onPressed: () => _deleteEmployee(doc.id, collectionName),
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
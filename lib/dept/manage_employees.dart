import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _currentDepartmentId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentDepartmentId();
  }

  Future<void> _fetchCurrentDepartmentId() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    print('Current department user email: $userEmail');
    if (userEmail == null) return;
    final query = await FirebaseFirestore.instance
        .collection('department')
        .where('d_email', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      setState(() {
        _currentDepartmentId = query.docs.first.id;
      });
      print('Fetched departmentId: \\_currentDepartmentId=$_currentDepartmentId');
    } else {
      print('No department found for email: $userEmail');
    }
  }

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

    // Ensure departmentId is set for hosts
    if (role == 'Host' && (_currentDepartmentId == null || _currentDepartmentId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Department ID not found. Cannot add host.')),
      );
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
      if (role == 'Host')
        'departmentId': _currentDepartmentId,
    };
    print('Adding employee with data: $employeeData');

    if (_editingId == null) {
      // Add new employee
      if (role == 'Host') {
        try {
          // Optionally sign out current user if needed (depends on your auth rules)
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: empEmail,
            password: empPassword,
          );
        } catch (e) {
          // Handle error (e.g., email already in use)
          print('Error creating host in Firebase Auth: ' + e.toString());
          // Optionally show a message to the user
        }
      }
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
                            style: ReceptionistTheme.heading.copyWith(fontSize: 20, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _empIdController,
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
                          TextField(
                            controller: _empPasswordController,
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
        backgroundColor: ReceptionistTheme.primary,
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
                          icon: const Icon(Icons.edit, color: ReceptionistTheme.primary),
                          onPressed: () => showEmployeeForm(doc, collectionName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: ReceptionistTheme.primary),
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
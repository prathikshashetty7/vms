import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employees')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<DropdownMenuItem<String>>>(
              future: _getRoleDropdownItems(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return Column(
                  children: [
                    TextField(
                      controller: _empIdController,
                      decoration: const InputDecoration(labelText: 'Employee ID'),
                    ),
                    TextField(
                      controller: _empNameController,
                      decoration: const InputDecoration(labelText: 'Employee Name'),
                    ),
                    TextField(
                      controller: _empEmailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: _empPasswordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    TextField(
                      controller: _empContNoController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: _empAddressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: items,
                      onChanged: (val) {
                        setState(() {
                          _selectedRole = val;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addOrUpdateEmployee,
                      child: Text(_editingId == null ? 'Add' : 'Update'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildEmployeeList('host', 'Hosts'),
                  _buildEmployeeList('receptionist', 'Receptionists'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList(String collectionName, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
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
                return ListTile(
                  title: Text(doc['emp_name'] ?? ''),
                  subtitle: Text('ID: ${doc['emp_id']}, Role: ${doc['role']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _startEdit(doc, collectionName),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteEmployee(doc.id, collectionName),
                      ),
                    ],
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
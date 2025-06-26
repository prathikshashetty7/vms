import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDepartments extends StatefulWidget {
  const ManageDepartments({Key? key}) : super(key: key);

  @override
  State<ManageDepartments> createState() => _ManageDepartmentsState();
}

class _ManageDepartmentsState extends State<ManageDepartments> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _editingId;

  Future<void> _addOrUpdateDepartment() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;
    if (_editingId == null) {
      // Add new department
      await FirebaseFirestore.instance.collection('department').add({
        'd_name': name,
        'd_email': email,
        'd_password': password,
      });
    } else {
      // Update existing department
      await FirebaseFirestore.instance.collection('department').doc(_editingId).update({
        'd_name': name,
        'd_email': email,
        'd_password': password,
      });
      _editingId = null;
    }
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {});
  }

  Future<void> _deleteDepartment(String id) async {
    await FirebaseFirestore.instance.collection('department').doc(id).delete();
    setState(() {});
  }

  void _startEdit(String id, String name, String email, String password) {
    _editingId = id;
    _nameController.text = name;
    _emailController.text = email;
    _passwordController.text = password;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addOrUpdateDepartment,
                  child: Text(_editingId == null ? 'Add' : 'Update'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('department').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No departments found.'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final id = doc.id;
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final name = data['d_name'] ?? '';
                      final email = data['d_email'] ?? '';
                      final password = data['d_password'] ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: $email'),
                              Text('Password: $password'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _startEdit(id, name, email, password),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteDepartment(id),
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
          ],
        ),
      ),
    );
  }
} 
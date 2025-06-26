import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRoles extends StatefulWidget {
  const ManageRoles({Key? key}) : super(key: key);

  @override
  State<ManageRoles> createState() => _ManageRolesState();
}

class _ManageRolesState extends State<ManageRoles> {
  final TextEditingController _roleController = TextEditingController();
  String? _editingId;

  Future<void> _addOrUpdateRole() async {
    final role = _roleController.text.trim();
    if (role.isEmpty) return;
    if (_editingId == null) {
      // Add new role
      await FirebaseFirestore.instance.collection('roles').add({
        'role_name': role,
      });
    } else {
      // Update existing role
      await FirebaseFirestore.instance.collection('roles').doc(_editingId).update({
        'role_name': role,
      });
      _editingId = null;
    }
    _roleController.clear();
    setState(() {});
  }

  Future<void> _deleteRole(String id) async {
    await FirebaseFirestore.instance.collection('roles').doc(id).delete();
    setState(() {});
  }

  void _startEdit(String id, String name) {
    _editingId = id;
    _roleController.text = name;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeptTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage Roles', style: DeptTheme.heading),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: DeptTheme.deptPrimary),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: DeptTheme.deptLight.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roleController,
                          decoration: const InputDecoration(
                            labelText: 'Role Name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DeptTheme.deptPrimary,
                        ),
                        onPressed: _addOrUpdateRole,
                        child: Text(_editingId == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('roles').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No roles found.', style: DeptTheme.body));
                        }
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final id = doc.id;
                            final name = doc['role_name'] ?? '';
                            return Card(
                              color: DeptTheme.deptAccent.withOpacity(0.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(name, style: DeptTheme.subheading),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: DeptTheme.deptPrimary),
                                      onPressed: () => _startEdit(id, name),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: DeptTheme.deptDark),
                                      onPressed: () => _deleteRole(id),
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
          ),
        ),
      ),
    );
  }
} 
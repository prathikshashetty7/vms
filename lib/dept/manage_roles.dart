import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Roles')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    return const Center(child: Text('No roles found.'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final id = doc.id;
                      final name = doc['role_name'] ?? '';
                      return ListTile(
                        title: Text(name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _startEdit(id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteRole(id),
                            ),
                          ],
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
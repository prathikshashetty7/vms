import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDepartments extends StatefulWidget {
  const ManageDepartments({Key? key}) : super(key: key);

  @override
  State<ManageDepartments> createState() => _ManageDepartmentsState();
}

class _ManageDepartmentsState extends State<ManageDepartments> {
  final TextEditingController _nameController = TextEditingController();
  String? _editingId;

  Future<void> _addOrUpdateDepartment() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_editingId == null) {
      // Add new department
      await FirebaseFirestore.instance.collection('department').add({
        'd_name': name,
      });
    } else {
      // Update existing department
      await FirebaseFirestore.instance.collection('department').doc(_editingId).update({
        'd_name': name,
      });
      _editingId = null;
    }
    _nameController.clear();
    setState(() {});
  }

  Future<void> _deleteDepartment(String id) async {
    await FirebaseFirestore.instance.collection('department').doc(id).delete();
    setState(() {});
  }

  void _startEdit(String id, String name) {
    _editingId = id;
    _nameController.text = name;
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                    ),
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
                      final name = doc['d_name'] ?? '';
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
                              onPressed: () => _deleteDepartment(id),
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
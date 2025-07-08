import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRoles extends StatefulWidget {
  final String? currentDepartmentId;
  const ManageRoles({Key? key, this.currentDepartmentId}) : super(key: key);

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
        'departmentId': widget.currentDepartmentId,
      });
    } else {
      // Update existing role
      await FirebaseFirestore.instance.collection('roles').doc(_editingId).update({
        'role_name': role,
        'departmentId': widget.currentDepartmentId,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

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
            const Text('Manage Roles', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD4E9FF),
      body: Column(
        children: [
          _customHeader(),
          Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Role Section
                Container(
                  padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                  decoration: BoxDecoration(
                    gradient: ReceptionistTheme.deptGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ReceptionistTheme.primary.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingId == null ? 'Add Role' : 'Edit Role',
                        style: ReceptionistTheme.heading.copyWith(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _roleController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter role name...',
                          filled: true,
                          fillColor: ReceptionistTheme.secondary,
                          hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addOrUpdateRole,
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
                const SizedBox(height: 24),
                // List of Roles
                SizedBox(
                  height: 300, // or MediaQuery.of(context).size.height - someOffset
                  child: StreamBuilder<QuerySnapshot>(
                    stream: widget.currentDepartmentId == null
                        ? null
                        : FirebaseFirestore.instance.collection('roles')
                            .where('departmentId', isEqualTo: widget.currentDepartmentId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No roles added yet.', style: ReceptionistTheme.body.copyWith(color: ReceptionistTheme.text)));
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final id = doc.id;
                          final name = doc['role_name'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: ReceptionistTheme.deptGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ReceptionistTheme.primary.withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.security, color: Colors.white),
                              title: Text(name, style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: ReceptionistTheme.primary),
                                    onPressed: () => _startEdit(id, name),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: ReceptionistTheme.primary),
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
        ],
      ),
    );
  }
} 
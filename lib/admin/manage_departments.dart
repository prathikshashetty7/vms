import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';
import 'admin_dashboard.dart';

class ManageDepartments extends StatefulWidget {
  const ManageDepartments({Key? key}) : super(key: key);

  @override
  State<ManageDepartments> createState() => _ManageDepartmentsState();
}

class _ManageDepartmentsState extends State<ManageDepartments> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _editingId;

  // TODO: Replace with your actual admin credentials
  static const String adminEmail = 'ADMIN_EMAIL';
  static const String adminPassword = 'ADMIN_PASSWORD';

  Future<void> _addOrUpdateDepartment() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    if (_editingId == null) {
      try {
        // 1. Sign out admin
        await FirebaseAuth.instance.signOut();
        // 2. Create department user
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // 3. Add to Firestore
        await FirebaseFirestore.instance.collection('department').add({
          'd_name': name,
          'd_email': email,
          'd_password': password,
        });
        // 4. Sign out department user
        await FirebaseAuth.instance.signOut();
        // 5. Sign admin back in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department added successfully!')),
        );
      } on FirebaseAuthException catch (e) {
        String msg = 'Error: ';
        if (e.code == 'email-already-in-use') {
          msg += 'Email already in use.';
        } else if (e.code == 'weak-password') {
          msg += 'Password is too weak.';
        } else {
          msg += e.message ?? 'Unknown error';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        // Try to sign admin back in if needed
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        } catch (_) {}
        return;
      }
    } else {
      // Update existing department in Firestore
      await FirebaseFirestore.instance.collection('department').doc(_editingId).update({
        'd_name': name,
        'd_email': email,
        'd_password': password,
      });
      _editingId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated!')),
      );
    }
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {});
  }

  Future<void> _deleteDepartment(String id) async {
    await FirebaseFirestore.instance.collection('department').doc(id).delete();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted successfully!')),
    );
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF081735)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manage Departments',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF081735), fontSize: 16),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple, size: 20),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AdminTheme.adminBackgroundGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search departments...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _addOrUpdateDepartment,
                      child: Text(_editingId == null ? 'Add' : 'Update'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('department').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No departments found.', style: TextStyle(color: AdminTheme.textLight)));
                    }
                    final docs = snapshot.data!.docs;
                    final filteredDocs = _searchQuery.isEmpty
                        ? docs
                        : docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final name = (data['d_name'] ?? '').toString().toLowerCase();
                            return name.contains(_searchQuery);
                          }).toList();
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final id = doc.id;
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final name = data['d_name'] ?? '';
                        final email = data['d_email'] ?? '';
                        final password = data['d_password'] ?? '';
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: $email', style: const TextStyle(color: Colors.black)),
                                Text('Password: $password', style: const TextStyle(color: Colors.black)),
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
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4B006E), Color(0xFF0F2027), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('admin@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Settings',
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              text: 'Admin Dashboard',
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      selected: selected,
      onTap: onTap,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/admin_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';
import 'admin_dashboard.dart';

class ManageDepartments extends StatefulWidget {
  const ManageDepartments({Key? key}) : super(key: key);

  @override
  State<ManageDepartments> createState() => _ManageDepartmentsState();
}

class _ManageDepartmentsState extends State<ManageDepartments> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _obscurePassword = true;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String _searchQuery = '';
  String? _editingId;

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Department name is required.' : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value.trim())) return 'Please enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required.';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~^%()_+=\[\]{}|;:,.<>/?-]).{6,}').hasMatch(value.trim())) {
      return 'Password must contain a letter, a number, and a special character.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Request focus for the name field when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // TODO: Replace with your actual admin credentials
  static const String adminEmail = 'ADMIN_EMAIL';
  static const String adminPassword = 'ADMIN_PASSWORD';

  Future<void> _addOrUpdateDepartment() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_editingId == null) {
      try {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await FirebaseFirestore.instance.collection('department').add({
          'd_name': name,
          'd_email': email,
          'd_password': password,
        });
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        setState(() {
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _obscurePassword = true;
        });
        _formKey.currentState!.reset();
        Future.delayed(const Duration(milliseconds: 100), () {
          _nameFocusNode.requestFocus();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department added successfully!'), backgroundColor: Colors.green),
          );
        });
      } on FirebaseAuthException catch (e) {
        String msg = 'Error: ';
        if (e.code == 'email-already-in-use') {
          msg += 'Email already in use.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        } else if (e.code == 'weak-password') {
          msg += 'Password is too weak.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        } else if (e.code == 'invalid-email') {
          // Do not show snackbar for badly formatted email
        } else {
          msg += e.message ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        }
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        } catch (_) {}
        return;
      }
    } else {
      await FirebaseFirestore.instance.collection('department').doc(_editingId).update({
        'd_name': name,
        'd_email': email,
        'd_password': password,
      });
      _editingId = null;
      setState(() {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _obscurePassword = true;
      });
      _formKey.currentState!.reset();
      Future.delayed(const Duration(milliseconds: 100), () {
        _nameFocusNode.requestFocus();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteDepartment(String id) async {
    // Fetch department email and password before deleting
    final docSnap = await FirebaseFirestore.instance.collection('department').doc(id).get();
    final data = docSnap.data() as Map<String, dynamic>? ?? {};
    final email = data['d_email']?.toString() ?? '';
    final password = data['d_password']?.toString() ?? '';

    // 1. Delete from Firestore
    await FirebaseFirestore.instance.collection('department').doc(id).delete();

    // 2. Sign in as the department user to delete from Auth
    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user?.delete();
      } catch (e) {
        // Handle error (user may already be deleted, wrong password, etc.)
      }
    }

    // 3. Sign admin back in (if needed)
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } catch (_) {}

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted successfully!'), backgroundColor: Colors.green),
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
            Image.asset('assets/images/rdl.png', height: 40),
            const SizedBox(width: 10),
            const Text('Manage Departments', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
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
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search departments...',
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
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
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Department Name',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        validator: _validateName,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 8),
                      StatefulBuilder(
                        builder: (context, setLocalState) {
                          return TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                                onPressed: () {
                                  setLocalState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              _addOrUpdateDepartment();
                            },
                          );
                        },
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
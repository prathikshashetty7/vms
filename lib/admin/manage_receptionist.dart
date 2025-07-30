import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageReceptionistPage extends StatefulWidget {
  const ManageReceptionistPage({Key? key}) : super(key: key);

  @override
  State<ManageReceptionistPage> createState() => _ManageReceptionistPageState();
}

class _ManageReceptionistPageState extends State<ManageReceptionistPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _phoneError;
  // Removed department fields
  // String? _selectedDepartment = null;
  // List<Map<String, String>> _departments = [];
  // String? _selectedDepartmentId;
  
  // Focus nodes for form fields
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Removed _fetchDepartments and batchUpdateReceptionistDepartmentIds
  }

  // Removed _fetchDepartments

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Full name is required.' : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value.trim())) return 'Please enter a valid email address.';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\d{10}').hasMatch(value.trim())) return 'Enter a valid 10-digit phone number.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required.';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~^%()_+=\[\]{}|;:,.<>/?-]).{6,}').hasMatch(value.trim())) {
      return 'Password must contain a letter, a number, and a special character.';
    }
    return null;
  }

  void _showAddReceptionistDialog() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _obscurePassword = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Receptionist'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) {
                          _phoneFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setLocalState) {
                          return TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setLocalState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              _addReceptionist(showDialogSetState: setStateSB);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addReceptionist(showDialogSetState: (fn) => setState(() { fn(); }));
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addReceptionist({void Function(void Function())? showDialogSetState}) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance.collection('receptionist').add({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'receptionist',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _obscurePassword = true;
      });
      _formKey.currentState!.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receptionist added successfully!'), backgroundColor: Colors.green),
        );
      });
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already in use.'), backgroundColor: Colors.red),
        );
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is too weak.'), backgroundColor: Colors.red),
        );
      } else if (e.code == 'invalid-email') {
        if (showDialogSetState != null) {
          showDialogSetState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteReceptionist(String receptionistId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Receptionist'),
          content: Text('Are you sure you want to delete $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('receptionist')
                      .doc(receptionistId)
                      .delete();
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receptionist deleted successfully')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting receptionist: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditReceptionistDialog(String docId, Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _passwordController.text = data['password'] ?? '';
    _obscurePassword = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Receptionist'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) {
                          _phoneFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setLocalState) {
                          return TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setLocalState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              _updateReceptionist(docId, setStateSB);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateReceptionist(docId, (fn) => setState(() { fn(); }));
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateReceptionist(String docId, void Function(void Function()) showDialogSetState) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    try {
      await FirebaseFirestore.instance.collection('receptionist').doc(docId).update({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });
      setState(() {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _obscurePassword = true;
      });
      _formKey.currentState!.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receptionist updated successfully!'), backgroundColor: Colors.green),
        );
      });
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating receptionist: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Removed batchUpdateReceptionistDepartmentIds

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
            const Text('Manage Receptionists', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search receptionists...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddReceptionistDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Receptionist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('receptionist').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';
                    final phone = data['phone']?.toString().toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    
                    return name.contains(query) || 
                           email.contains(query) || 
                           phone.contains(query);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No receptionists found' : 'No matching receptionists',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final email = data['email'] ?? 'No email';
                      final phone = data['phone'] ?? 'No phone';
                      // Removed department and departmentId from data
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'R',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${data['email']}', style: const TextStyle(color: Colors.black)),
                              Text('Phone: ${data['phone']}', style: const TextStyle(color: Colors.black)),
                              Text('Password: ${data['password']}', style: const TextStyle(color: Colors.black)), // <-- Add this line
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                onPressed: () => _showEditReceptionistDialog(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteReceptionist(doc.id, name),
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
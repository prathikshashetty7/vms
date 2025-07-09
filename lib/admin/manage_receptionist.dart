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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _obscurePassword = true;
  String? _selectedDepartment = null;
  List<Map<String, String>> _departments = [];
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    // One-time batch update for existing receptionists
    batchUpdateReceptionistDepartmentIds();
  }

  Future<void> _fetchDepartments() async {
    final snapshot = await FirebaseFirestore.instance.collection('department').get();
    setState(() {
      _departments = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['d_name'] as String,
      }).toList();
      // Do not pre-select any department
      _selectedDepartment = null;
      _selectedDepartmentId = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddReceptionistDialog() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _obscurePassword = true;
    _selectedDepartment = null;
    _selectedDepartmentId = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Receptionist'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Department'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Department'),
                        ),
                        ..._departments.map((dept) => DropdownMenuItem<String>(
                          value: dept['name'],
                          child: Text(dept['name']!),
                        ))
                      ],
                      onChanged: (value) {
                        setStateSB(() {
                          _selectedDepartment = value;
                          _selectedDepartmentId = _departments.firstWhere((dept) => dept['name'] == value)['id'];
                        });
                      },
                      validator: (value) => value == null ? 'Please select a department' : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setStateSB(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
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
                _addReceptionist();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addReceptionist() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a department')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    try {
      // Create user in Firebase Auth
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already in use.')),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating user: $e')),
          );
          return;
        }
      }
      // Add to Firestore
      await FirebaseFirestore.instance.collection('receptionist').add({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'role': 'receptionist',
        'department': _selectedDepartment,
        'departmentId': _selectedDepartmentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receptionist added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding receptionist: $e')),
      );
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
    _selectedDepartment = data['department'];
    _selectedDepartmentId = data['departmentId'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Receptionist'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setStateSB(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Department'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Department'),
                        ),
                        ..._departments.map((dept) => DropdownMenuItem<String>(
                          value: dept['name'],
                          child: Text(dept['name']!),
                        ))
                      ],
                      onChanged: (value) {
                        setStateSB(() {
                          _selectedDepartment = value;
                          _selectedDepartmentId = _departments.firstWhere((dept) => dept['name'] == value)['id'];
                        });
                      },
                      validator: (value) => value == null ? 'Please select a department' : null,
                    ),
                  ],
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
                _updateReceptionist(docId);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateReceptionist(String docId) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a department')),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('receptionist').doc(docId).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'department': _selectedDepartment,
        'departmentId': _selectedDepartmentId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receptionist updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating receptionist: $e')),
      );
    }
  }

  // Utility: Batch update all receptionists to add departmentId based on department name
  Future<void> batchUpdateReceptionistDepartmentIds() async {
    final departmentSnaps = await FirebaseFirestore.instance.collection('department').get();
    final Map<String, String> nameToId = {
      for (var doc in departmentSnaps.docs) (doc['d_name'] as String): doc.id
    };
    final receptionists = await FirebaseFirestore.instance.collection('receptionist').get();
    for (var doc in receptionists.docs) {
      final deptName = doc['department'];
      final deptId = nameToId[deptName];
      if (deptId != null) {
        await doc.reference.update({'departmentId': deptId});
        print('Updated ${doc.id} with departmentId $deptId');
      } else {
        print('No departmentId found for department $deptName');
      }
    }
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
                      final department = data['department'];
                      final departmentId = data['departmentId'];
                      return FutureBuilder<String>(
                        future: (() async {
                          if (department != null && department.toString().isNotEmpty) {
                            return department.toString();
                          } else if (departmentId != null && departmentId.toString().isNotEmpty) {
                            final deptSnap = await FirebaseFirestore.instance.collection('department').doc(departmentId).get();
                            if (deptSnap.exists) {
                              return deptSnap.data()?['d_name']?.toString() ?? departmentId.toString();
                            } else {
                              return departmentId.toString();
                            }
                          } else {
                            return 'No department';
                          }
                        })(),
                        builder: (context, snapshot) {
                          final deptName = snapshot.data ?? 'Loading...';
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(email)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(phone),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(deptName),
                                    ],
                                  ),
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
import 'package:flutter/material.dart';
import 'admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({Key? key}) : super(key: key);

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> with SingleTickerProviderStateMixin {
  String _filterType = 'All';
  String _selectedDepartment = 'All';
  List<String> _departments = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final snapshot = await FirebaseFirestore.instance.collection('department').get();
    setState(() {
      _departments = ['All', ...snapshot.docs.map((doc) => doc['d_name'].toString()).toList()];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF081735)),
          title: Row(
            children: [
              Image.asset('assets/images/rdl.png', height: 56),
              const SizedBox(width: 10),
              const Text('Employee Management', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF081735))),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurple),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Hosts'),
              Tab(icon: Icon(Icons.person_outline), text: 'Receptionists'),
            ],
            labelColor: Color(0xFF081735),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF081735),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('Filter by:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedDepartment,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      items: _departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDepartment = val ?? 'All';
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _EmployeeListView(
                      collection: 'host',
                      filterDepartment: _selectedDepartment,
                    ),
                    _EmployeeListView(
                      collection: 'receptionist',
                      filterDepartment: _selectedDepartment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeListView extends StatelessWidget {
  final String collection;
  final String filterDepartment;
  const _EmployeeListView({required this.collection, required this.filterDepartment, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white70)));
        }
        final docs = snapshot.data!.docs.where((doc) {
          if (filterDepartment == 'All') return true;
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return (data['department'] ?? '').toString() == filterDepartment;
        }).toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Department', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final role = data['role'] ?? (collection == 'host' ? 'Host' : 'Receptionist');
              final department = data['department'] ?? '';
              final status = (data['isActive'] ?? true) ? 'Active' : 'Inactive';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(name, style: const TextStyle(color: Colors.black))),
                      Expanded(flex: 2, child: Text(email, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(role, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(department, style: const TextStyle(color: Colors.black))),
                      Expanded(child: Text(status, style: TextStyle(color: status == 'Active' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () {
                          // TODO: Implement edit user info
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
} 
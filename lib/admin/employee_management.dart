import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String name;
  final String role;
  final String department;
  final String email;
  final String phone;

  Employee({
    required this.name,
    required this.role,
    required this.department,
    required this.email,
    this.phone = '',
  });
}

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({Key? key}) : super(key: key);

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> with SingleTickerProviderStateMixin {
  String _filterType = 'All';
  String _selectedDepartment = 'All';
  List<String> _departments = ['All'];
  String _selectedRole = 'All';
  List<String> _roles = ['All'];
  TextEditingController _searchController = TextEditingController();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedType = 'Host'; // Host or Receptionist

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchRoles();
    _fetchEmployees();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    final snapshot = await FirebaseFirestore.instance.collection('department').get();
    setState(() {
      _departments = ['All', ...snapshot.docs.map((doc) => doc['d_name'].toString()).toList()];
    });
  }

  Future<void> _fetchRoles() async {
    final snapshot = await FirebaseFirestore.instance.collection('role').get();
    // Collect roles from Firestore
    final firestoreRoles = snapshot.docs.map((doc) => doc['r_name'].toString()).toSet();
    // Always include 'Host' and 'Receptionist'
    firestoreRoles.addAll(['Host', 'Receptionist']);
    setState(() {
      _roles = ['All', ...firestoreRoles];
    });
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch departments and build a map of id -> name
      final deptSnap = await FirebaseFirestore.instance.collection('department').get();
      final Map<String, String> deptMap = {};
      for (var doc in deptSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        deptMap[doc.id] = data['d_name'] ?? '';
      }

      final hostSnap = await FirebaseFirestore.instance.collection('host').get();
      final recSnap = await FirebaseFirestore.instance.collection('receptionist').get();
      List<Employee> all = [];
      
      // Add hosts with department name
      for (var doc in hostSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final deptId = data['departmentId'] ?? '';
        final deptName = deptMap[deptId] ?? deptId;
        all.add(Employee(
          name: data['emp_name'] ?? '',
          role: 'Host',
          department: deptName,
          email: data['emp_email'] ?? '',
          phone: data['emp_contno'] ?? '', // Use emp_contno for host contact number
        ));
      }
      
      // Add receptionists
      for (var doc in recSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        all.add(Employee(
          name: data['name'] ?? '',
          role: 'Receptionist',
          department: data['department'] ?? '', // Use the department field for receptionists
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
        ));
      }
      
      setState(() {
        _employees = all;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load employees:\n\n${e.toString()}';
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEmployees = _employees.where((e) {
        final matchesName = _searchController.text.isEmpty || 
                           e.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           e.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           e.phone.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesRole = _selectedRole == 'All' || e.role == _selectedRole;
        final matchesDept = _selectedDepartment == 'All' || e.department == _selectedDepartment;
        return matchesName && matchesRole && matchesDept;
      }).toList();
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
              const Text('Employee Management', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
                  : Column(
                      children: [
                        // Search bar below AppBar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                hintText: _selectedType == 'Host' ? 'Search hosts...' : 'Search receptionists...',
                                hintStyle: const TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        // Custom tab-like toggle for Host/Receptionist
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              _buildCustomTab('Host'),
                              _buildCustomTab('Receptionist'),
                            ],
                          ),
                        ),
                        // After the tab row, add the dropdown (only for Host)
                        if (_selectedType == 'Host')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<String>(
                                value: _selectedDepartment,
                                isExpanded: true,
                                items: _departments.map((dept) => DropdownMenuItem<String>(
                                  value: dept,
                                  child: Text(dept, style: const TextStyle(color: Colors.black87)),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDepartment = val!;
                                    _applyFilters();
                                  });
                                },
                                underline: Container(),
                                style: const TextStyle(color: Colors.black, fontSize: 15),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Cards for filtered employees
                        Expanded(
                          child: _buildEmployeeList(_selectedType),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(String role) {
    final employees = role == 'All'
        ? _filteredEmployees
        : _filteredEmployees.where((e) => e.role == role).toList();
    if (employees.isEmpty) {
      return Center(
        child: Text('No employees found.', style: const TextStyle(color: Colors.black, fontSize: 18)),
      );
    }
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(emp.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 8),
                if (emp.role == 'Host') ...[
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(emp.phone, style: TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.apartment, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(emp.department, style: TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.badge, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(emp.role, style: TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(emp.email, style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab(String type) {
    final isSelected = _selectedType == type;
    IconData icon = type == 'Host' ? Icons.person : Icons.badge;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(0),
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSelected
                  ? CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(icon, color: const Color(0xFF181F2C), size: 22),
                    )
                  : Icon(icon, color: Colors.grey, size: 24),
              const SizedBox(height: 2),
              Text(
                type == 'Host' ? 'Hosts' : 'Receptionists',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
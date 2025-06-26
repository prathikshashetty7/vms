import 'package:flutter/material.dart';

class EmployeeManagementPage extends StatelessWidget {
  const EmployeeManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      body: const Center(
        child: Text('Employee Management Page Content Goes Here', style: TextStyle(fontSize: 20)),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';

class DeptReport extends StatelessWidget {
  const DeptReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeptTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Department Report', style: DeptTheme.heading),
          backgroundColor: DeptTheme.deptPrimary.withOpacity(0.9),
          elevation: 0,
        ),
        body: Center(
          child: Card(
            color: DeptTheme.deptLight.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            margin: const EdgeInsets.all(32),
            child: const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Reports will be shown here. (Coming soon!)',
                style: DeptTheme.body,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
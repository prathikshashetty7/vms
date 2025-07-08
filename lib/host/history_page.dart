import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFD4E9FF),
        ),
        child: Center(
          child: Text('No history yet.', style: TextStyle(color: Color(0xFF091016), fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
} 
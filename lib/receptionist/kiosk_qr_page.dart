import 'package:flutter/material.dart';
import '../theme/system_theme.dart';

class KioskQRPage extends StatelessWidget {
  const KioskQRPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD4E9FF),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Kiosk QR Registration', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Color(0xFF6CA4FE),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: SystemTheme.secondary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SystemTheme.primary.withOpacity(0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Center(
                child: Text('QR CODE', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Scan this QR code to fill the kiosk form',
              style: TextStyle(
                color: SystemTheme.accent,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
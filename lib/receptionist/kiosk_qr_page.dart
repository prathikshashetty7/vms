import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';

class KioskQRPage extends StatelessWidget {
  const KioskQRPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReceptionistTheme.background,
      appBar: AppBar(
        title: const Text('Kiosk QR Registration'),
        backgroundColor: ReceptionistTheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: ReceptionistTheme.secondary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: ReceptionistTheme.primary.withOpacity(0.2),
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
                color: ReceptionistTheme.accent,
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
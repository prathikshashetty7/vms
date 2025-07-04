import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutTile extends StatelessWidget {
  const LogoutTile({Key? key}) : super(key: key);

  void _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Logout'),
      onTap: () => _logout(context),
    );
  }
} 
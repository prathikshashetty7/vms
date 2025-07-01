import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showChangePassword = false;
  bool _darkMode = false;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Clear session and redirect to login
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
            const Icon(Icons.settings, color: Colors.black),
            const SizedBox(width: 10),
            const Text('Settings', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Section
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.person, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            SizedBox(height: 4),
                            Text('admin@gmail.com', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Navigate to edit profile page
                        },
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Security Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock, color: Colors.deepPurple),
                    title: const Text('Change Password'),
                    trailing: Icon(_showChangePassword ? Icons.expand_less : Icons.expand_more),
                    onTap: () {
                      setState(() {
                        _showChangePassword = !_showChangePassword;
                      });
                    },
                  ),
                  if (_showChangePassword)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_open),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement password update logic
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Update Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  // Theme Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                      // TODO: Implement theme switching
                    },
                    secondary: const Icon(Icons.brightness_6, color: Colors.deepPurple),
                  ),
                  const Divider(),
                  // Logout Section
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
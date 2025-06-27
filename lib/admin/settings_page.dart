import 'package:flutter/material.dart';
import 'admin_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
            Image.asset('assets/images/rdl.png', height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Settings',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF081735), fontSize: 16),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple, size: 20),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4B006E), Color(0xFF0F2027), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('admin@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDrawerItem(context, Icons.settings, 'Settings', true, () => Navigator.pop(context)),
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard', false, () {/* Navigate to dashboard */}),
            _buildDrawerItem(context, Icons.logout, 'Logout', false, () {/* Handle logout */}),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(thickness: 1.2, color: Colors.deepPurple.shade100),
            ),
            const SizedBox(height: 16),
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _sectionTitle('Edit Profile'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: const Text('Edit Profile'),
                  subtitle: const Text('Name, email, password, profile picture'),
                  trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {/* Edit profile logic */}),
                ),
              ),
            ),
            _sectionTitle('Theme Mode'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: false,
                  onChanged: (val) {/* Toggle theme */},
                  secondary: const Icon(Icons.dark_mode),
                ),
              ),
            ),
            _sectionTitle('Notification Preferences'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      value: true,
                      onChanged: (val) {/* Toggle push */},
                      secondary: const Icon(Icons.notifications),
                    ),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      value: false,
                      onChanged: (val) {/* Toggle email */},
                      secondary: const Icon(Icons.email),
                    ),
                    SwitchListTile(
                      title: const Text('SMS Notifications'),
                      value: false,
                      onChanged: (val) {/* Toggle SMS */},
                      secondary: const Icon(Icons.sms),
                    ),
                  ],
                ),
              ),
            ),
            _sectionTitle('Language'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('App Language'),
                  trailing: DropdownButton<String>(
                    value: 'English',
                    items: const [DropdownMenuItem(value: 'English', child: Text('English')), DropdownMenuItem(value: 'Spanish', child: Text('Spanish'))],
                    onChanged: (val) {/* Change language */},
                  ),
                ),
              ),
            ),
            _sectionTitle('Privacy & Security'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      onTap: () {/* Change password logic */},
                    ),
                    SwitchListTile(
                      title: const Text('Two-Factor Authentication'),
                      value: false,
                      onChanged: (val) {/* Toggle 2FA */},
                      secondary: const Icon(Icons.verified_user),
                    ),
                  ],
                ),
              ),
            ),
            _sectionTitle('About App'),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version 1.0.0'),
                  subtitle: const Text('Developed by Your Company\nContact: support@example.com'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () {/* Handle logout */},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      );

  Widget _buildDrawerItem(BuildContext context, IconData icon, String text, bool selected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.deepPurple : Colors.black54),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: selected ? Colors.deepPurple : Colors.black87)),
      selected: selected,
      selectedTileColor: Colors.deepPurple.shade50,
      hoverColor: Colors.deepPurple.shade50,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
} 
import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'widgets/stat_card.dart';
import '../signin.dart';
import 'dart:ui';
import 'manual_entry_page.dart';
import 'receptionist_reports_page.dart';

class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Receptionist Dashboard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFF6CA4FE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: ReceptionistTheme.primary,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ReceptionistTheme.accent,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 12),
                  Text('Receptionist', style: TextStyle(color: ReceptionistTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('receptionist@email.com', style: TextStyle(color: ReceptionistTheme.text, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: ReceptionistTheme.accent),
              title: const Text('Dashboard', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                // Already on dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: ReceptionistTheme.accent),
              title: const Text('Host Passes', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/host_passes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: ReceptionistTheme.accent),
              title: const Text('Manual Entry', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manual_entry');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: ReceptionistTheme.accent),
              title: const Text('Kiosk QR', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/kiosk_qr');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes, color: ReceptionistTheme.accent),
              title: const Text('Visitor Tracking', style: TextStyle(color: ReceptionistTheme.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/visitor_tracking');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFD4E9FF),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              // Decorative Header
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22005FFE),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: ReceptionistTheme.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 600),
                                style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle())
                                    .copyWith(
                                      color: Color(0xFF091016),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      shadows: [Shadow(color: Color(0xFF005FFE), blurRadius: 8)],
                                    ),
                                child: Text('Welcome, Receptionist!'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Here is a quick overview of today.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Color(0xFF6CA4FE),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionButton(
                      icon: Icons.person_add_alt_1,
                      label: 'Add Visitor',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManualEntryPage()),
                        );
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.list_alt,
                      label: 'Visitor Log',
                      onTap: () {
                        // TODO: Implement visitor log navigation
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.bar_chart,
                      label: 'Reports',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReceptionistReportsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Daily Tip / Motivation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: const Color(0xFFFFF176), // Vibrant yellow
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orangeAccent, size: 30, shadows: [Shadow(color: Colors.orange, blurRadius: 8)]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Tip: Greet every visitor with a smile! 😊',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(color: Colors.orangeAccent, blurRadius: 6, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Stat Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _StyledStatCard(
                      title: 'Current Visitors',
                      value: '12',
                      icon: Icons.people,
                    ),
                    _StyledStatCard(
                      title: 'Checked In',
                      value: '8',
                      icon: Icons.login,
                    ),
                    _StyledStatCard(
                      title: 'Checked Out',
                      value: '4',
                      icon: Icons.logout,
                    ),
                    _StyledStatCard(
                      title: 'Pending Approvals',
                      value: '2',
                      icon: Icons.pending_actions,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Optionally, add more creative widgets here
            ],
          ),
        ),
      ),
    );
  }
}

// Modern styled stat card widget
class _StyledStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StyledStatCard({
    required this.title,
    required this.value,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x22005FFE),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF6CA4FE).withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Color(0xFF005FFE),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF091016),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Add quick action button widget
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap, Key? key}) : super(key: key);
  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1.0);
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              // Glassmorphism effect
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      widget.icon,
                      color: Colors.black,
                      size: 30,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
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
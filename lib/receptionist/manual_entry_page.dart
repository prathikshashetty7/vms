import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({Key? key}) : super(key: key);

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String fullName = '', mobile = '', email = '', company = '', host = '', purpose = 'Business Meeting', appointment = 'Yes', accompanying = 'No', accompanyingCount = '', laptop = 'No', laptopDetails = '', department = 'HR';
  final List<String> purposes = [
    'Business Meeting', 'Interview', 'Delivery', 'Maintenance', 'Other',
  ];
  final List<String> yesNo = ['Yes', 'No'];
  final List<String> departments = [
    'HR', 'Finance', 'IT', 'Admin', 'Operations', 'Other',
  ];
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _buttonScale = Tween<double>(begin: 1.0, end: 1.08).animate(_buttonController);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReceptionistTheme.background,
      body: Stack(
        children: [
          // Decorative background shapes
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: ReceptionistTheme.primary.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ReceptionistTheme.accent.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Wavy header
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ReceptionistTheme.primary, ReceptionistTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 30),
                    Icon(Icons.emoji_people, color: Colors.white, size: 48),
                    SizedBox(height: 10),
                    Text('Welcome Visitor!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
          // Form card
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Visitor Registration',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: ReceptionistTheme.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField('Visitor Full Name', onSaved: (v) => fullName = v!, validator: _required, icon: Icons.person),
                          const SizedBox(height: 16),
                          _buildTextField('Visitor Mobile No', onSaved: (v) => mobile = v!, validator: _required, icon: Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          _buildTextField('Visitor Email ID', onSaved: (v) => email = v!, validator: _required, icon: Icons.email, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildTextField('Company/Organization Name', onSaved: (v) => company = v!, validator: _required, icon: Icons.business),
                          const SizedBox(height: 16),
                          _buildDropdown('Purpose of the Visit', purposes, purpose, (v) => setState(() => purpose = v!)),
                          const SizedBox(height: 16),
                          _buildDropdown('Do you have an appointment', yesNo, appointment, (v) => setState(() => appointment = v!)),
                          const SizedBox(height: 16),
                          _buildDropdown('Department', departments, department, (v) => setState(() => department = v!)),
                          const SizedBox(height: 16),
                          _buildTextField('Host Name', onSaved: (v) => host = v!, validator: _required, icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildDropdown('Accompanying Visitors (if any)', yesNo, accompanying, (v) => setState(() => accompanying = v!)),
                          const SizedBox(height: 16),
                          if (accompanying == 'Yes')
                            _buildTextField('Number of Accompanying Visitors', onSaved: (v) => accompanyingCount = v!, validator: _required, icon: Icons.group, keyboardType: TextInputType.number),
                          if (accompanying == 'Yes') const SizedBox(height: 16),
                          _buildDropdown('Do you carrying a laptop?', yesNo, laptop, (v) => setState(() => laptop = v!)),
                          const SizedBox(height: 16),
                          if (laptop == 'Yes')
                            _buildTextField('Enter the laptop model & serial number', onSaved: (v) => laptopDetails = v!, validator: _required, icon: Icons.laptop),
                          if (laptop == 'Yes') const SizedBox(height: 16),
                          const SizedBox(height: 24),
                          Center(
                            child: ScaleTransition(
                              scale: _buttonScale,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ReceptionistTheme.accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  elevation: 6,
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Register Visitor', style: TextStyle(fontSize: 18)),
                                onPressed: () async {
                                  await _buttonController.forward();
                                  await Future.delayed(const Duration(milliseconds: 80));
                                  _buttonController.reverse();
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    // TODO: Save to Firestore
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Visitor registered!')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  Widget _buildTextField(String label, {required FormFieldSetter<String> onSaved, required FormFieldValidator<String> validator, IconData? icon, TextInputType? keyboardType}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: ReceptionistTheme.primary) : null,
        filled: true,
        fillColor: ReceptionistTheme.secondary.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ReceptionistTheme.accent, width: 2),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: ReceptionistTheme.secondary.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ReceptionistTheme.accent, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/receptionist_theme.dart';
import 'receptionist_reports_page.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({Key? key}) : super(key: key);

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String fullName = '', mobile = '', email = '', company = '', host = '', purpose = 'Business Meeting', appointment = 'Yes', accompanying = 'No', accompanyingCount = '', laptop = 'No', laptopDetails = '', department = 'HR';
  Uint8List? visitorPhoto;
  final List<String> purposes = [
    'Business Meeting', 'Interview', 'Delivery', 'Maintenance', 'Other',
  ];
  final List<String> yesNo = ['Yes', 'No'];
  List<String> departments = [];
  bool _departmentsLoading = true;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  String? purposeOther;
  // Add focus nodes for each field
  final _fullNameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _hostFocus = FocusNode();
  final _accompanyingCountFocus = FocusNode();
  final _laptopDetailsFocus = FocusNode();
  final _purposeOtherFocus = FocusNode();

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        visitorPhoto = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _buttonScale = Tween<double>(begin: 1.0, end: 1.08).animate(_buttonController);
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final snapshot = await FirebaseFirestore.instance.collection('departments').get();
    setState(() {
      departments = snapshot.docs.map((doc) => doc['name'] as String).toList();
      _departmentsLoading = false;
    });
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6CA4FE),
        title: Row(
          children: [
            Image.asset('assets/images/rdl.png', height: 36),
            const SizedBox(width: 12),
            const Text('Manual Entry', style: TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFD4E9FF),
      body: Stack(
        children: [
          // Wavy blue header
          Container(
              height: 180,
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 30),
                  Icon(Icons.emoji_people, color: Color(0xFF005FFE), size: 48),
                    SizedBox(height: 10),
                  Text('Welcome Visitor!', style: TextStyle(color: Color(0xFF091016), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
              ),
            ),
          ),
          // Form card with glassmorphism
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22005FFE),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                            child: Text(
                              'Visitor Registration',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.blueAccent,
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ),
                            const SizedBox(height: 18),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.7),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      border: Border.all(color: Colors.blueAccent, width: 3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: visitorPhoto != null ? MemoryImage(visitorPhoto!) : null,
                                      child: visitorPhoto == null
                                          ? Icon(Icons.account_circle, color: Colors.black, size: 54, shadows: [Shadow(color: Colors.blueAccent, blurRadius: 16)])
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _pickPhoto,
                                    icon: const Icon(Icons.add_a_photo),
                                    label: const Text('Capture Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildTextField('Visitor Full Name',
                              onSaved: (v) => fullName = v!,
                              validator: _required,
                              icon: Icons.person,
                              focusNode: _fullNameFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_mobileFocus),
                            ),
                          const SizedBox(height: 16),
                            _buildTextField('Visitor Mobile No',
                              onSaved: (v) => mobile = v!,
                              validator: _required,
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              focusNode: _mobileFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                            ),
                          const SizedBox(height: 16),
                            _buildTextField('Visitor Email ID',
                              onSaved: (v) => email = v!,
                              validator: _required,
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_companyFocus),
                            ),
                          const SizedBox(height: 16),
                            _buildTextField('Company/Organization Name',
                              onSaved: (v) => company = v!,
                              validator: _required,
                              icon: Icons.business,
                              focusNode: _companyFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                            ),
                          const SizedBox(height: 16),
                          _buildDropdown('Purpose of the Visit', purposes, purpose, (v) => setState(() => purpose = v!)),
                            if (purpose == 'Other')
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: _buildTextField('Enter Purpose',
                                  onSaved: (v) => purposeOther = v!,
                                  validator: (v) => v == null || v.isEmpty ? 'Please enter purpose' : null,
                                  icon: Icons.edit,
                                  focusNode: _purposeOtherFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                                ),
                              ),
                          const SizedBox(height: 16),
                          _buildDropdown('Do you have an appointment', yesNo, appointment, (v) => setState(() => appointment = v!)),
                          const SizedBox(height: 16),
                            _departmentsLoading
                                ? Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()))
                                : _buildDropdown(
                                    'Department',
                                    ['Select Dept', ...departments],
                                    (department.isNotEmpty && departments.contains(department)) ? department : 'Select Dept',
                                    (v) {
                                      if (v != null && v != 'Select Dept') {
                                        setState(() => department = v);
                                      }
                                    },
                                  ),
                          const SizedBox(height: 16),
                            _buildTextField('Host Name',
                              onSaved: (v) => host = v!,
                              validator: _required,
                              icon: Icons.person_outline,
                              focusNode: _hostFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                            ),
                          const SizedBox(height: 16),
                          _buildDropdown('Accompanying Visitors (if any)', yesNo, accompanying, (v) => setState(() => accompanying = v!)),
                          const SizedBox(height: 16),
                          if (accompanying == 'Yes')
                              _buildTextField('Number of Accompanying Visitors',
                                onSaved: (v) => accompanyingCount = v!,
                                validator: _required,
                                icon: Icons.group,
                                keyboardType: TextInputType.number,
                                focusNode: _accompanyingCountFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              ),
                          if (accompanying == 'Yes') const SizedBox(height: 16),
                          _buildDropdown('Do you carrying a laptop?', yesNo, laptop, (v) => setState(() => laptop = v!)),
                          const SizedBox(height: 16),
                          if (laptop == 'Yes')
                              _buildTextField('Enter the laptop model & serial number',
                                onSaved: (v) => laptopDetails = v!,
                                validator: _required,
                                icon: Icons.laptop,
                                focusNode: _laptopDetailsFocus,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              ),
                          if (laptop == 'Yes') const SizedBox(height: 16),
                          const SizedBox(height: 24),
                          Center(
                            child: ScaleTransition(
                              scale: _buttonScale,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF64B5F6),
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
                                      // Store in Firestore
                                      await FirebaseFirestore.instance.collection('manual_registrations').add({
                                        'fullName': fullName,
                                        'mobile': mobile,
                                        'email': email,
                                        'company': company,
                                        'host': host,
                                        'purpose': purpose == 'Other' ? (purposeOther ?? '') : purpose,
                                        'purposeOther': purpose == 'Other' ? (purposeOther ?? '') : null,
                                        'appointment': appointment,
                                        'department': department == 'Select Dept' ? '' : department,
                                        'accompanying': accompanying,
                                        'accompanyingCount': accompanying == 'Yes' ? accompanyingCount : '',
                                        'laptop': laptop,
                                        'laptopDetails': laptop == 'Yes' ? laptopDetails : '',
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'photo': visitorPhoto != null ? base64Encode(visitorPhoto!) : null,
                                      });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Visitor registered!')),
                                    );
                                      await Future.delayed(const Duration(milliseconds: 600));
                                      Navigator.pushReplacementNamed(context, '/receptionist_reports');
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 2,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/host_passes');
          } else if (index == 2) {
            // Already here
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/receptionist_reports');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_rounded),
            label: 'Host Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Add Visitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  Widget _buildTextField(String label, {required FormFieldSetter<String> onSaved, required FormFieldValidator<String> validator, IconData? icon, TextInputType? keyboardType, FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: icon != null
            ? ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(icon, color: Colors.white),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      style: const TextStyle(color: Colors.white),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?>? onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    enabled: e != 'Select Dept',
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
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
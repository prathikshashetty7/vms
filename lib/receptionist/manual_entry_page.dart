import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/receptionist_theme.dart';
import 'receptionist_reports_page.dart';
import 'dashboard.dart' show VisitorsPage;
import 'package:image/image.dart' as img;

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({Key? key}) : super(key: key);

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String fullName = '', mobile = '', email = '', company = '', host = '', purpose = 'Select Purpose', appointment = 'Yes', accompanying = 'No', accompanyingCount = '', laptop = 'No', laptopDetails = '', department = 'HR';
  Uint8List? visitorPhoto;
  final List<String> purposes = [
    'Select Purpose', 'Business Meeting', 'Interview', 'Delivery', 'Maintenance', 'Other',
  ];
  final List<String> yesNo = ['Yes', 'No'];
  List<String> departments = [];
  bool _departmentsLoading = true;
  bool _isSaving = false; // Add this line
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  String? purposeOther;
  String designation = '';
  // Add focus nodes for each field
  final _fullNameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _hostFocus = FocusNode();
  final _accompanyingCountFocus = FocusNode();
  final _laptopDetailsFocus = FocusNode();
  final _purposeOtherFocus = FocusNode();
  final _designationFocus = FocusNode();

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      // Decode the image
      img.Image? original = img.decodeImage(bytes);
      if (original != null) {
        // Resize to a max width of 400px
        img.Image resized = img.copyResize(original, width: 400);
        // Encode as JPEG with quality 60
        final compressedBytes = img.encodeJpg(resized, quality: 60);
        setState(() {
          visitorPhoto = Uint8List.fromList(compressedBytes);
        });
      } else {
        setState(() {
          visitorPhoto = bytes;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _buttonScale = Tween<double>(begin: 1.0, end: 1.08).animate(_buttonController);
    // _fetchDepartments(); // This function is no longer needed
  }

  // Future<void> _fetchDepartments() async { // This function is no longer needed
  //   final snapshot = await FirebaseFirestore.instance.collection('department').get();
  //   // Debug print to see what is fetched
  //   print('Fetched departments:');
  //   for (var doc in snapshot.docs) {
  //     print(doc.data());
  //   }
  //   setState(() {
  //     departments = snapshot.docs
  //       .map((doc) => doc.data())
  //       .where((data) => data.containsKey('d_name') && data['d_name'] is String)
  //       .map((data) => data['d_name'] as String)
  //       .toList();
  //     _departmentsLoading = false;
  //   });
  // }

  @override
  void dispose() {
    _buttonController.dispose();
    _designationFocus.dispose();
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
            const Text('Visitor Form', style: TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFD4E9FF),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('department').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final departments = snapshot.data!.docs
            .map((doc) => doc['d_name'] as String)
            .where((name) => name.isNotEmpty)
            .toList();
          return Stack(
            children: [
              // Gradient wavy header
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF64B5F6), Color(0xFF005FFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22005FFE),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _WavyHeaderPainter(),
                  child: Container(),
                ),
              ),
              // Form card with glassmorphism and shadow
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33005FFE),
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ],
                        border: Border.all(color: Color(0xFF64B5F6).withOpacity(0.18), width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Visitor Registration',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.black,
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
                                          ? Icon(Icons.person, color: Colors.black, size: 54, shadows: [Shadow(color: Colors.blueAccent, blurRadius: 16)])
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
                            _buildTextField('Designation',
                              onSaved: (v) => designation = v!,
                              validator: _required,
                              icon: Icons.badge,
                              focusNode: _designationFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_companyFocus),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown('Purpose of the Visit', purposes, purpose, (v) => setState(() => purpose = v!), hintText: 'Select Purpose'),
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
                                  hintText: 'Type your purpose',
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildDropdown('Do you have an appointment', yesNo, appointment, (v) => setState(() => appointment = v!)),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('department').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(),
      ));
    }
    final departments = snapshot.data!.docs
      .map((doc) => doc['d_name'] as String)
      .where((name) => name.isNotEmpty)
      .toList();
    return _buildDropdown(
      'Department',
      ['Select Dept', ...departments],
      (department.isNotEmpty && ['Select Dept', ...departments].contains(department)) ? department : 'Select Dept',
      (v) {
        if (v != null && v != 'Select Dept') {
          setState(() => department = v);
        } else {
          setState(() => department = '');
        }
      },
    );
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
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                    elevation: 6,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Register Visitor', style: TextStyle(fontSize: 18)),
                                  onPressed: () async {
                                    if (_isSaving) return;
                                    setState(() => _isSaving = true);
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
                                          'designation': designation,
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
                                      setState(() => _isSaving = false);
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
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6CA4FE),
        unselectedItemColor: Color(0xFF091016),
        currentIndex: 3,
        onTap: (index) {
          if (index == 4) {
            Navigator.pushReplacementNamed(context, '/signin');
            return;
          }
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/receptionist_reports');
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VisitorsPage()),
            );
          } else if (index == 3) {
            // Already here (Add Visitor)
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_rounded),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Add Visitor',
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

  Widget _buildTextField(String label, {required FormFieldSetter<String> onSaved, required FormFieldValidator<String> validator, IconData? icon, TextInputType? keyboardType, FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted, String? hintText}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
        prefixIcon: icon != null
            ? Icon(icon, color: Color(0xFF005FFE))
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF888888)),
      ),
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?>? onChanged, {String? hintText}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF005FFE), width: 2),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF888888)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    enabled: e != 'Select Purpose' && e != 'Select Dept',
                    child: Text(e, style: TextStyle(color: e == 'Select Purpose' || e == 'Select Dept' ? Color(0xFF888888) : Colors.black)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _WavyHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFF005FFE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.5, size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 80,
      size.width, size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
    // Optionally, add a subtle highlight
    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final highlightPath = Path();
    highlightPath.moveTo(0, size.height * 0.5);
    highlightPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.7,
      size.width, size.height * 0.4,
    );
    highlightPath.lineTo(size.width, 0);
    highlightPath.lineTo(0, 0);
    highlightPath.close();
    canvas.drawPath(highlightPath, highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
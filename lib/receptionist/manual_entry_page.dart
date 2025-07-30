  import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/system_theme.dart';
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
  String fullName = '', mobile = '', email = '', company = '', host = '', purpose = '', appointment = 'Yes', accompanying = 'No', accompanyingCount = '', laptop = 'No', laptopDetails = '', department = 'Select Dept';
  String? purposeOther;
  Uint8List? visitorPhoto;
  bool _isSaving = false;
  bool _showDeptTotalVisitors = false; // New variable to track if we should show dept's total visitors
  int _deptTotalVisitors = 1; // New variable to store dept's total visitors count
  final List<String> yesNo = ['Yes', 'No'];
  List<String> departments = [];
  bool _departmentsLoading = true;
  bool _isSaving = false; // Add this line
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  String designation = '';
  String? selectedVisitorId; // Add variable to store selected visitor ID
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

  // Add controllers for form fields
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();
  final _purposeController = TextEditingController();

  // Function to reset form
  void _resetForm() {
    setState(() {
      fullName = '';
      mobile = '';
      email = '';
      company = '';
      host = '';
      purpose = '';
      appointment = 'Yes';
      accompanying = 'No';
      accompanyingCount = '';
      laptop = 'No';
      laptopDetails = '';
      department = 'Select Dept';
      designation = '';
      purposeOther = null;
      visitorPhoto = null;
      selectedVisitorId = null; // Reset selected visitor ID
      _showDeptTotalVisitors = false;
      _deptTotalVisitors = 1;
    });
    
    // Clear controllers
    _fullNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _companyController.clear();
    _designationController.clear();
    _purposeController.clear();
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    
    XFile? image;
    try {
      // Directly open camera without showing dialog
      image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      
      // If camera didn't work, show a helpful message
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not available. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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

  // Add this function to generate a unique 4-digit pass number
  Future<int> _generateUniquePassNo() async {
    final random = Random();
    int passNo;
    bool exists = true;
    final passesRef = FirebaseFirestore.instance.collection('passes');
    do {
      passNo = 1000 + random.nextInt(9000); // 4-digit number
      final query = await passesRef.where('pass_no', isEqualTo: passNo).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return passNo;
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _designationFocus.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _purposeController.dispose();
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
            .toSet() // Remove duplicates
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
                                    label: const Text('Add Photo'),
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
                              controller: _fullNameController,
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
                              controller: _mobileController,
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
                              controller: _emailController,
                            ),
                            
                            const SizedBox(height: 16),
                            _buildTextField('Company/Organization Name',
                              onSaved: (v) => company = v!,
                              validator: _required,
                              icon: Icons.business,
                              focusNode: _companyFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              controller: _companyController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField('Designation',
                              onSaved: (v) => designation = v!,
                              validator: _required,
                              icon: Icons.badge,
                              focusNode: _designationFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_companyFocus),
                              controller: _designationController,
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
  stream: FirebaseFirestore.instance
      .collection('department')
      .snapshots(),
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
      .toSet() // Remove duplicates
      .toList();
    
    // Create unique dropdown items
    final dropdownItems = <String>['Select Dept'];
    dropdownItems.addAll(departments);
    
    // Ensure the current department is in the list if it's not empty
    if (department.isNotEmpty && 
        department != 'Select Dept' && 
        !dropdownItems.contains(department)) {
      dropdownItems.add(department);
    }
    
    // Validate the selected value
    final validValue = dropdownItems.contains(department) ? department : 'Select Dept';
    
    return _buildDropdown(
      'Department',
      dropdownItems,
      validValue,
>>>>>>> e9f7e31ef09a3a692f1b367bf40096632e1ac24d
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
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('host')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(),
                                  ));
                                }
                                
                                // Extract host names from host collection
                                final hosts = snapshot.data!.docs;
                                final allHostNames = hosts
                                    .map((doc) => doc.data() as Map<String, dynamic>)
                                    .where((data) => data['emp_name'] != null && data['emp_name'].toString().isNotEmpty)
                                    .map((data) => data['emp_name'].toString())
                                    .toSet()
                                    .toList();
                                
                                // Add "Select Host" option at the beginning
                                final hostNames = <String>['Select Host'];
                                hostNames.addAll(allHostNames);
                                
                                // Sort all hosts alphabetically (except "Select Host")
                                if (hostNames.length > 1) {
                                  final selectHost = hostNames[0];
                                  final remainingHosts = hostNames.sublist(1)..sort();
                                  hostNames.clear();
                                  hostNames.add(selectHost);
                                  hostNames.addAll(remainingHosts);
                                }
                                
                                return _buildDropdown(
                                  'Host Name',
                                  hostNames,
                                  host.isEmpty ? 'Select Host' : host,
                                  (v) {
                                    if (v != null && v != 'Select Host') {
                                      setState(() => host = v);
                                    } else {
                                      setState(() => host = '');
                                    }
                                  },
                                  hintText: 'Select Host',
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Conditional accompanying visitors section
                            if (_showDeptTotalVisitors) ...[
                              // Show department's total visitors count
                              _buildTextField('Accompanying Visitors',
                                onSaved: (v) => accompanyingCount = v!,
                                validator: _required,
                                icon: Icons.group,
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: _deptTotalVisitors.toString()),
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              ),
                            ] else ...[
                              // Show original Yes/No dropdown + number field
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
                            ],
                            if (_showDeptTotalVisitors || (accompanying == 'Yes' && !_showDeptTotalVisitors)) const SizedBox(height: 16),
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
                                    
                                    // Validate form first before setting loading state
                                    if (!_formKey.currentState!.validate()) {
                                      // Show error message for incomplete form
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please fill all required fields'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    // Only set loading state if validation passes
                                    setState(() => _isSaving = true);
                                    
                                    try {
                                      print('DEBUG: Form submission - selectedVisitorId = $selectedVisitorId');
                                      _formKey.currentState!.save();
                                      
                                      // Generate unique pass number
                                      final passNo = await _generateUniquePassNo();
                                      
                                      // Debug: Print selectedVisitorId
                                      print('DEBUG: selectedVisitorId = $selectedVisitorId');
                                      
                                      // Store in manual_registrations collection
                                      final manualRegistrationRef = await FirebaseFirestore.instance.collection('manual_registrations').add({
                                        'fullName': fullName,
                                        'mobile': mobile,
                                        'email': email,
                                        'designation': designation,
                                        'company': company,
                                        'host': host,
                                        'purpose': purpose,
                                        'appointment': appointment,
                                        'department': department == 'Select Dept' ? '' : department,
                                        'accompanying': _showDeptTotalVisitors ? 'Yes' : accompanying,
                                        'accompanyingCount': _showDeptTotalVisitors ? _deptTotalVisitors.toString() : (accompanying == 'Yes' ? accompanyingCount : ''),
                                        'laptop': laptop,
                                        'laptopDetails': laptop == 'Yes' ? laptopDetails : '',
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'photo': visitorPhoto != null ? base64Encode(visitorPhoto!) : null,
                                        'pass_no': passNo,
                                        'source': 'manual',
                                        'visitor_id': selectedVisitorId, // Add selectedVisitorId
                                      });
                                      
                                      // Also store in passes collection for consistency
                                      await FirebaseFirestore.instance.collection('passes').add({
                                        'visitorId': manualRegistrationRef.id,
                                        'v_name': fullName,
                                        'v_company_name': company,
                                        'department': department == 'Select Dept' ? '' : department,
                                        'host_name': host,
                                        'v_date': FieldValue.serverTimestamp(),
                                        'v_time': FieldValue.serverTimestamp(),
                                        'photoBase64': visitorPhoto != null ? base64Encode(visitorPhoto!) : null,
                                        'v_designation': designation,
                                        'pass_no': passNo,
                                        'v_totalno': _showDeptTotalVisitors ? _deptTotalVisitors.toString() : (accompanying == 'Yes' ? accompanyingCount : ''),
                                        'purpose': purpose,
                                        'created_at': FieldValue.serverTimestamp(),
                                        'pass_generated_by': 'receptionist',
                                        'source': 'manual',
                                      });
                                      
                                      setState(() => _isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Visitor registered successfully!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      
                                      await Future.delayed(const Duration(milliseconds: 600));
                                      Navigator.pushReplacementNamed(context, '/receptionist_reports');
                                      
                                    } catch (e) {
                                      // Handle any errors during registration
                                      setState(() => _isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error registering visitor: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
>>>>>>> e9f7e31ef09a3a692f1b367bf40096632e1ac24d
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showReceptionistVisitorsDialog();
        },
        backgroundColor: Color(0xFF6CA4FE),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        elevation: 8,
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

  Widget _buildTextField(String label, {required FormFieldSetter<String> onSaved, required FormFieldValidator<String> validator, IconData? icon, TextInputType? keyboardType, FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted, String? hintText, TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
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
    final uniqueItems = items.toSet().toList(); // Ensure unique items
    final validValue = uniqueItems.contains(value) ? value : uniqueItems.isNotEmpty ? uniqueItems.first : null;
    
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
          value: validValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF005FFE)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          items: uniqueItems
              .map((e) => DropdownMenuItem(
                    value: e,
                    enabled: e != 'Select Purpose' && e != 'Select Dept' && e != 'Select Host',
                    child: Text(e, style: TextStyle(color: e == 'Select Purpose' || e == 'Select Dept' || e == 'Select Host' ? Color(0xFF888888) : Colors.black)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showReceptionistVisitorsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Color(0xFF6CA4FE)),
                    const SizedBox(width: 8),
                    Text(
                      'Department Visitors',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF091016),
                        fontFamily: 'Poppins'
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('visitor')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading visitors: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text(
                            'No data available.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      
                      // Filter visitors with receptionist-generated passes
                      final allVisitors = snapshot.data!.docs;
                      final visitors = allVisitors.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['pass_generated_by'] == 'receptionist';
                      }).toList();
                      
                      // Sort by date descending
                      visitors.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aDate = aData['v_date'];
                        final bDate = bData['v_date'];
                        
                        if (aDate == null && bDate == null) return 0;
                        if (aDate == null) return 1;
                        if (bDate == null) return -1;
                        
                        DateTime aDateTime, bDateTime;
                        if (aDate is Timestamp) {
                          aDateTime = aDate.toDate();
                        } else if (aDate is DateTime) {
                          aDateTime = aDate;
                        } else {
                          aDateTime = DateTime.tryParse(aDate.toString()) ?? DateTime.now();
                        }
                        
                        if (bDate is Timestamp) {
                          bDateTime = bDate.toDate();
                        } else if (bDate is DateTime) {
                          bDateTime = bDate;
                        } else {
                          bDateTime = DateTime.tryParse(bDate.toString()) ?? DateTime.now();
                        }
                        
                        return bDateTime.compareTo(aDateTime);
                      });
                      
                      if (visitors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, color: Color(0xFF6CA4FE), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'No visitors found.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact Department Manager',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: visitors.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4E9FF)),
                        itemBuilder: (context, index) {
                          final visitor = visitors[index].data() as Map<String, dynamic>;
                          final visitorId = visitors[index].id;
                          
                          String name = visitor['v_name'] ?? 'Unknown';
                          String company = visitor['v_company_name'] ?? '';
                          String email = visitor['v_email'] ?? '';
                          String time = visitor['v_time'] ?? '';
                          DateTime? date;
                          String dateInfo = '';
                          
                          if (visitor['v_date'] != null) {
                            final vDate = visitor['v_date'];
                            if (vDate is Timestamp) {
                              date = vDate.toDate();
                              dateInfo = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                            }
                          }
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF6CA4FE),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (company.isNotEmpty)
                                  Text('Company: $company', style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))),
                                if (email.isNotEmpty)
                                  Text('Email: $email', style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))),
                                if (time.isNotEmpty || dateInfo.isNotEmpty)
                                  Text(
                                    '${dateInfo.isNotEmpty ? dateInfo : ''}${dateInfo.isNotEmpty && time.isNotEmpty ? ' at ' : ''}${time.isNotEmpty ? time : ''}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6CA4FE))
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Check if department has total visitors count
                                final deptTotalVisitors = visitor['v_totalno'];
                                final hasDeptTotalVisitors = deptTotalVisitors != null && deptTotalVisitors >= 1;
                                
                                // Fill the form with this visitor's data from department
                                setState(() {
                                  fullName = visitor['v_name'] ?? '';
                                  mobile = visitor['v_contactno'] ?? '';
                                  email = visitor['v_email'] ?? '';
                                  company = visitor['v_company_name'] ?? '';
                                  host = visitor['emp_name'] ?? visitor['host_name'] ?? '';
                                  purpose = visitor['purpose'] ?? '';
                                  appointment = 'Yes';
                                  
                                  // Handle accompanying visitors based on dept data
                                  if (hasDeptTotalVisitors) {
                                    _showDeptTotalVisitors = true;
                                    _deptTotalVisitors = deptTotalVisitors;
                                    accompanying = 'Yes';
                                    accompanyingCount = deptTotalVisitors.toString();
                                  } else {
                                    _showDeptTotalVisitors = false;
                                    _deptTotalVisitors = 1;
                                    accompanying = 'No';
                                    accompanyingCount = '';
                                  }
                                  
                                  laptop = 'No';
                                  laptopDetails = '';
                                  department = visitor['department'] ?? 'Select Dept';
                                  designation = visitor['v_designation'] ?? '';
                                  purposeOther = null;
                                  visitorPhoto = null;
                                  selectedVisitorId = visitorId; // Store the selected visitor ID
                                  print('DEBUG: Fill Form clicked for visitorId = $visitorId');
                                });
                                
                                // Update controllers to display the filled data
                                _fullNameController.text = fullName;
                                _mobileController.text = mobile;
                                _emailController.text = email;
                                _companyController.text = company;
                                _designationController.text = designation;
                                _purposeController.text = purpose;
                                
                                // Force rebuild to ensure form updates
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() {});
                                });
                                
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Form filled with ${visitor['v_name']}\'s data. Please add remaining details manually.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Fill Form', style: TextStyle(fontSize: 12)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
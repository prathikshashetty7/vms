import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/system_theme.dart';
import 'package:image/image.dart' as img;

class QRCodeRegistrationsPage extends StatefulWidget {
  const QRCodeRegistrationsPage({Key? key}) : super(key: key);

  @override
  State<QRCodeRegistrationsPage> createState() => _QRCodeRegistrationsPageState();
}

class _QRCodeRegistrationsPageState extends State<QRCodeRegistrationsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String fullName = '', mobile = '', email = '', company = '', host = '', purpose = '', appointment = 'Yes', accompanying = 'No', accompanyingCount = '', laptop = 'No', laptopDetails = '', department = 'Select Dept';
  String? purposeOther;
  Uint8List? visitorPhoto;
  bool _isSaving = false;
  bool _isPhotoLoading = false; // Add this variable to your state
  final List<String> yesNo = ['Yes', 'No'];
  List<String> departments = [];
  bool _departmentsLoading = true;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  String designation = '';
  String? departmentId = ''; // Add this line
  // ...existing state variables...

Map<String, List<String>> _hostsCache = {};
bool _hostsLoading = false;
List<String> _currentHosts = ['Select Host'];

// ...focus nodes and other variables...

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
    setState(() => _isPhotoLoading = true); // Show loading indicator

    final ImagePicker picker = ImagePicker();
    XFile? image;
    try {
      // Optimize image picker settings for faster processing
      image = await picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50, // Reduced from 70 to 50 for faster processing
        maxWidth: 300, // Limit max width
        maxHeight: 300, // Limit max height
        preferredCameraDevice: CameraDevice.front, // Usually faster for selfies
      );
      
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not available. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isPhotoLoading = false);
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isPhotoLoading = false);
      return;
    }

    if (image != null) {
      try {
        // Process image in a more efficient way
        final bytes = await image.readAsBytes();
        
        // Check if image is already small enough (less than 100KB)
        if (bytes.length < 100 * 1024) {
          setState(() {
            visitorPhoto = bytes;
            _isPhotoLoading = false;
          });
          return;
        }
        
        // Process larger images
        img.Image? original = img.decodeImage(bytes);
        if (original != null) {
          // More aggressive resizing for faster processing
          img.Image resized = img.copyResize(
            original, 
            width: 200, // Reduced from 400 to 200
            height: 200, // Fixed height for consistency
            interpolation: img.Interpolation.linear, // Faster interpolation
          );
          
          // More aggressive compression
          final compressedBytes = img.encodeJpg(resized, quality: 40); // Reduced from 60 to 40
          
          setState(() {
            visitorPhoto = Uint8List.fromList(compressedBytes);
            _isPhotoLoading = false;
          });
          
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo captured successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Fallback for unsupported image formats
          setState(() {
            visitorPhoto = bytes;
            _isPhotoLoading = false;
          });
        }
      } catch (e) {
        print('Image processing error: $e');
        setState(() => _isPhotoLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process image. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      setState(() => _isPhotoLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _buttonScale = Tween<double>(begin: 1.0, end: 1.08).animate(_buttonController);
  }

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
            const Text('Visitor Registration', style: TextStyle(color: Colors.white)),
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
  .map((doc) => {
    'id': doc.id,
    'name': doc['d_name'] as String,
  })
  .where((dept) => dept['name'] != null && dept['name']!.isNotEmpty)
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
                                'Please fill the form',
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
                                    child: _isPhotoLoading
                                        ? const SizedBox(
                                            height: 96,
                                            width: 96,
                                            child: Center(child: CircularProgressIndicator()),
                                          )
                                        : CircleAvatar(
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
                            _buildTextField('Purpose of the Visit',
                              onSaved: (v) => purpose = v!,
                              validator: _required,
                              icon: Icons.edit,
                              focusNode: _purposeOtherFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              controller: _purposeController,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown('Do you have an appointment', yesNo, appointment, (v) => setState(() => appointment = v!)),
                            const SizedBox(height: 16),
                            // Department dropdown
                            _buildDropdown(
                              'Department',
                              [
                                'Select Dept',
                                ...departments.map((dept) => dept['name'] as String),
                              ],
                              department,
                              (value) async {
                                setState(() {
                                  department = value!;
                                  final selected = departments.firstWhere(
                                    (d) => d['name'] == value,
                                    orElse: () => {'id': '', 'name': 'Select Dept'},
                                  );
                                  departmentId = selected['id'];
                                  host = '';
                                  _hostsLoading = true;
                                  _currentHosts = ['Select Host'];
                                });

                                // Fetch hosts only if not cached
                                if (departmentId != null && departmentId!.isNotEmpty) {
                                  if (_hostsCache.containsKey(departmentId)) {
                                    setState(() {
                                      _currentHosts = _hostsCache[departmentId]!;
                                      _hostsLoading = false;
                                    });
                                  } else {
                                    final hostSnapshot = await FirebaseFirestore.instance
                                        .collection('host')
                                        .where('departmentId', isEqualTo: departmentId)
                                        .limit(50)
                                        .get();
                                    final hostNames = <String>['Select Host'];
                                    hostNames.addAll(
                                      hostSnapshot.docs
                                          .map((doc) => (doc.data() as Map<String, dynamic>)['emp_name'] as String)
                                          .where((name) => name.isNotEmpty)
                                          .toList(),
                                    );
                                    setState(() {
                                      _hostsCache[departmentId!] = hostNames;
                                      _currentHosts = hostNames;
                                      _hostsLoading = false;
                                    });
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            // Host dropdown (show loading or dropdown)
                            if (departmentId != null && departmentId!.isNotEmpty)
                              _hostsLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : _buildDropdown(
                                      'Host Name',
                                      _currentHosts,
                                      host.isEmpty ? 'Select Host' : host,
                                      (value) {
                                        setState(() {
                                          host = value == 'Select Host' ? '' : value!;
                                        });
                                      },
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

                                    if (!_formKey.currentState!.validate()) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
                                      );
                                      return;
                                    }

                                    setState(() => _isSaving = true);

                                    try {
                                      _formKey.currentState!.save();

                                      // Show progress message
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Checking email...'),
                                            backgroundColor: Colors.blue,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }

                                      // First, check if email exists in visitor collection
                                      final visitorQuery = await FirebaseFirestore.instance
                                          .collection('visitor')
                                          .where('v_email', isEqualTo: email)
                                          .limit(1)
                                          .get();

                                      if (visitorQuery.docs.isEmpty) {
                                        setState(() => _isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Email ID does not exist'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 4),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Email exists, proceed with registration
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Processing registration...'),
                                            backgroundColor: Colors.blue,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }

                                      // Get the visitor document ID from the existing visitor
                                      final existingVisitorDoc = visitorQuery.docs.first;
                                      final visitorId = existingVisitorDoc.id;

                                      // Generate unique pass number
                                      final passNo = await _generateUniquePassNo();

                                      // Prepare photo data efficiently
                                      String photoData = '';
                                      if (visitorPhoto != null) {
                                        try {
                                          // Use compute to encode image in background
                                          photoData = base64Encode(visitorPhoto!);
                                        } catch (e) {
                                          print('Photo encoding error: $e');
                                          photoData = '';
                                        }
                                      }

                                      // Save to manual_registrations collection only
                                      await FirebaseFirestore.instance.collection('manual_registrations').add({
                                        'fullName': fullName,
                                        'mobile': mobile,
                                        'email': email,
                                        'designation': designation,
                                        'company': company,
                                        'host': host,
                                        'purpose': purpose,
                                        'purposeOther': purposeOther ?? '',
                                        'appointment': appointment,
                                        'department': department == 'Select Dept' ? '' : department,
                                        'accompanying': accompanying,
                                        'accompanyingCount': accompanying == 'Yes' ? accompanyingCount : '',
                                        'laptop': laptop,
                                        'laptopDetails': laptop == 'Yes' ? laptopDetails : '',
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'photo': photoData,
                                        'pass_no': passNo,
                                        'source': 'qr_code',
                                        'visitor_id': visitorId, // Use existing visitor ID
                                      });

                                      // Add pass to passes collection
                                      await FirebaseFirestore.instance.collection('passes').add({
                                        'pass_no': passNo,
                                        'v_name': fullName,
                                        'email': email,
                                        'mobile': mobile,
                                        'company': company,
                                        'designation': designation,
                                        'host': host,
                                        'purpose': purpose,
                                        'department': department == 'Select Dept' ? '' : department,
                                        'photo': photoData,
                                        'created_at': FieldValue.serverTimestamp(),
                                        'group': 'qr_code',
                                        'visitor_id': visitorId, // Use existing visitor ID
                                      });

                                      setState(() => _isSaving = false);
                                      
                                      // Show success dialog
                                      await showSuccessDialog(context);

                                    } catch (e) {
                                      setState(() => _isSaving = false);
                                      print('Firestore error: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error registering visitor: ${e.toString()}'), 
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 4),
                                          ),
                                        );
                                      }
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

  // Animated success dialog
Future<void> showSuccessDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: const Text(
                      'Registration Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: const Text(
                      'Visitor has been registered successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
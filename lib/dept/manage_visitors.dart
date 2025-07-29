import 'package:flutter/material.dart';
import '../theme/system_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ManageVisitors extends StatefulWidget {
  final String? currentDepartmentId;
  const ManageVisitors({Key? key, this.currentDepartmentId}) : super(key: key);

  @override
  _ManageVisitorsState createState() => _ManageVisitorsState();
}

class _ManageVisitorsState extends State<ManageVisitors> {
  String? get _currentDepartmentId => widget.currentDepartmentId;

  // FocusNodes for form fields
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _designationFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _totalNoFocus = FocusNode();
  final FocusNode _purposeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // No need to fetch departmentId here
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _designationFocus.dispose();
    _companyFocus.dispose();
    _contactFocus.dispose();
    _totalNoFocus.dispose();
    _purposeFocus.dispose();
    super.dispose();
  }

  void _showVisitorForm([DocumentSnapshot? visitor]) {
    final isEditing = visitor != null;
    final _formKey = GlobalKey<FormState>();
    final vNameController = TextEditingController(text: visitor?['v_name']);
    final vEmailController = TextEditingController(text: visitor?['v_email']);
    final vDesignationController = TextEditingController(text: visitor?['v_designation']);
    final vCompanyNameController = TextEditingController(text: visitor?['v_company_name']);
    final vContactNoController = TextEditingController(text: visitor?['v_contactno']);
    final vTotalNoController = TextEditingController(text: visitor?['v_totalno']?.toString() ?? '1');
    final vPurposeController = TextEditingController(text: visitor?['purpose']);
    String? selectedHostId = visitor?['emp_id'];
    DateTime selectedDate = (visitor?['v_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    TimeOfDay selectedTime = visitor != null && visitor['v_time'] != null
      ? _parseTime(visitor['v_time'])
      : TimeOfDay.now();
    String passGeneratedBy = (visitor?.data() as Map<String, dynamic>?)?['pass_generated_by'] ?? 'host';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth > 600;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: isLargeScreen ? 32 : 16,
              right: isLargeScreen ? 32 : 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SystemTheme.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                child: FutureBuilder<List<DropdownMenuItem<String>>>(
                  future: _getHostDropdownItems(),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return Form(
              key: _formKey,
              child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                          Text(
                            isEditing ? 'Edit Visitor' : 'Add Visitor',
                            style: SystemTheme.heading.copyWith(fontSize: 20, color: SystemTheme.text),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: vNameController,
                            focusNode: _nameFocus,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_emailFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vEmailController,
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_designationFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vDesignationController,
                            focusNode: _designationFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_companyFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Designation',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vCompanyNameController,
                            focusNode: _companyFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_purposeFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Company Name',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vPurposeController,
                            focusNode: _purposeFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_contactFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Purpose',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vContactNoController,
                            focusNode: _contactFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_totalNoFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Contact No',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                  TextFormField(
                    controller: vTotalNoController,
                    focusNode: _totalNoFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Total Visitors',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                    keyboardType: TextInputType.number,
                  ),
                          const SizedBox(height: 10),
                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                selectedDate = picked;
                                (context as Element).markNeedsBuild();
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Select Date',
                                  hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                                  labelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Time Picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                selectedTime = picked;
                                (context as Element).markNeedsBuild();
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Select Time',
                                  hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                                  labelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: selectedTime.format(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                        value: selectedHostId,
                            items: items,
                        onChanged: (val) => selectedHostId = val,
                            decoration: InputDecoration(
                              hintText: 'Host',
                              hintStyle: SystemTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
                          const SizedBox(height: 10),
                          // Pass Generation Radio Buttons
                          Text(
                            'Pass Generated By:',
                            style: SystemTheme.body.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  RadioListTile<String>(
                                    title: Text(
                                      'Host',
                                      style: SystemTheme.body.copyWith(color: Colors.black),
                                    ),
                                    value: 'host',
                                    groupValue: passGeneratedBy,
                                    onChanged: (value) {
                                      setState(() {
                                        passGeneratedBy = value!;
                                      });
                                    },
                                    activeColor: SystemTheme.primary,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  RadioListTile<String>(
                                    title: Text(
                                      'Receptionist',
                                      style: SystemTheme.body.copyWith(color: Colors.black),
              ),
                                    value: 'receptionist',
                                    groupValue: passGeneratedBy,
                                    onChanged: (value) {
                                      setState(() {
                                        passGeneratedBy = value!;
                                      });
                                    },
                                    activeColor: SystemTheme.primary,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              );
                            },
          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final visitorData = {
                    'v_name': vNameController.text,
                    'v_email': vEmailController.text,
                    'v_designation': vDesignationController.text,
                    'v_company_name': vCompanyNameController.text,
                    'purpose': vPurposeController.text,
                    'v_contactno': vContactNoController.text,
                    'v_totalno': int.tryParse(vTotalNoController.text) ?? 1,
                    'v_date': Timestamp.fromDate(selectedDate),
                    'v_time': selectedTime.format(context),
                    'emp_id': selectedHostId,
                    'departmentId': _currentDepartmentId,
                    'pass_generated_by': passGeneratedBy,
                  };
                  
                  if (!isEditing) {
                    // Add to visitors collection
                    final visitorDocRef = await FirebaseFirestore.instance.collection('visitor').add(visitorData);
                    
                    // Also add to manual_registrations collection with visitor ID
                    final manualRegistrationData = {
                      'fullName': vNameController.text,
                      'email': vEmailController.text,
                      'designation': vDesignationController.text,
                      'company': vCompanyNameController.text,
                      'purpose': vPurposeController.text,
                      'mobile': vContactNoController.text,
                      'accompanyingCount': vTotalNoController.text,
                      'appointment': 'Yes',
                      'accompanying': 'No',
                      'laptop': 'No',
                      'laptopDetails': '',
                      'department': '', // Will be filled by receptionist
                      'host': '', // Will be filled by receptionist
                      'timestamp': FieldValue.serverTimestamp(),
                      'source': 'department',
                      'visitor_id': visitorDocRef.id, // Store the visitor ID
                    };
                    
                    await FirebaseFirestore.instance.collection('manual_registrations').add(manualRegistrationData);
                  } else {
                    // Update existing visitor
                    await visitor!.reference.update(visitorData);
                    
                    // Also update in manual_registrations if it exists
                    final manualRegQuery = await FirebaseFirestore.instance
                        .collection('manual_registrations')
                        .where('visitor_id', isEqualTo: visitor!.id)
                        .limit(1)
                        .get();
                    
                    if (manualRegQuery.docs.isNotEmpty) {
                      final manualRegDoc = manualRegQuery.docs.first;
                      await manualRegDoc.reference.update({
                        'fullName': vNameController.text,
                        'email': vEmailController.text,
                        'designation': vDesignationController.text,
                        'company': vCompanyNameController.text,
                        'purpose': vPurposeController.text,
                        'mobile': vContactNoController.text,
                        'accompanyingCount': vTotalNoController.text,
                      });
                    }
                  }
                  Navigator.of(context).pop();
                }
              },
                                icon: Icon(isEditing ? Icons.update : Icons.add, color: Colors.white),
                                label: Text(isEditing ? 'Update' : 'Add', style: SystemTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SystemTheme.text,
                                  padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 30 : 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVisitorDetailsDialog(DocumentSnapshot visitor) {
    showGeneralDialog(
    context: context,
      barrierDismissible: true,
      barrierLabel: 'Visitor Details',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Dialog(
        shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
        ),
                  elevation: 12,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person, size: 38, color: Colors.blue),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Visitor Details',
                                  style: SystemTheme.heading.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Card(
                            color: Colors.grey[50],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  detailRow('Name', visitor['v_name']),
                                  detailRow('Email', visitor['v_email'], onCopy: () {
                                    Clipboard.setData(ClipboardData(text: visitor['v_email']));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied!'), backgroundColor: Colors.green));
                                  }),
                                  detailRow('Designation', visitor['v_designation']),
                                  detailRow('Contact No', visitor['v_contactno'], onCopy: () {
                                    Clipboard.setData(ClipboardData(text: visitor['v_contactno']));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact copied!'), backgroundColor: Colors.green));
                                  }),
                                  detailRow('Company', visitor['v_company_name']),
                                  SizedBox(height: 6),
                                  detailRow('Purpose', visitor['purpose']),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(),
                          Card(
                            color: Colors.grey[50],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  detailRow('Total Visitors', visitor['v_totalno'].toString()),
                                  FutureBuilder<String>(
                                    future: _getHostName(visitor['emp_id']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return detailRow('Host', 'Loading...');
                                      }
                                      return detailRow('Host', snapshot.data ?? 'N/A');
                                    },
                                  ),
                                  detailRow('Date', _formatDate((visitor['v_date'] as Timestamp).toDate())),
                                  detailRow('Time', visitor['v_time']),
                                  detailRow('Pass Generated By', (visitor.data() as Map<String, dynamic>?)?['pass_generated_by'] ?? 'Host'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              child: Text('Close', style: TextStyle(fontSize: 16, color: Colors.black87)),
            onPressed: () {
              Navigator.of(context).pop();
            },
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
      );
    },
  );
}

  Widget detailRow(String label, String value, {VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy $label',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: onCopy,
          ),
      ],
    );
  }

  Future<List<DropdownMenuItem<String>>> _getHostDropdownItems() async {
    print('DEBUG: _currentDepartmentId =  [32m [1m [4m [7m' + (_currentDepartmentId ?? 'null') + '\u001b[0m');
    if (_currentDepartmentId == null) return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('No department ID found'),
      ),
    ];
    final snapshot = await FirebaseFirestore.instance
        .collection('host')
        .where('departmentId', isEqualTo: _currentDepartmentId)
        .get();
    print('DEBUG: Hosts fetched for departmentId $_currentDepartmentId:');
    for (var doc in snapshot.docs) {
      print('  Host: ' + (doc.data()['emp_name'] ?? 'NO NAME'));
    }
    if (snapshot.docs.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No hosts found for this department'),
        ),
      ];
    }
    return snapshot.docs.map((doc) => DropdownMenuItem<String>(
      value: doc.id,
      child: Text(doc['emp_name']),
    )).toList();
  }

  Future<String> _getHostName(String hostId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('host').doc(hostId).get();
      if (doc.exists) {
        return doc.data()?['emp_name'] ?? 'Unknown Host';
      }
    } catch (e) {
      // It's good practice to handle potential errors
    }
    return 'Unknown Host';
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return TimeOfDay.now();
    final parts = timeStr.split(":");
    if (parts.length < 2) return TimeOfDay.now();
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFD4E9FF),
      body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _currentDepartmentId == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('visitor')
                        .where('departmentId', isEqualTo: _currentDepartmentId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final totalVisitors = doc['v_totalno'] ?? 1;
                      final hostId = doc['emp_id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.black),
                          title: Text(doc['v_name'], style: SystemTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                          subtitle: FutureBuilder<String>(
                            future: hostId != null ? _getHostName(hostId) : Future.value('N/A'),
                            builder: (context, hostSnapshot) {
                              if (hostSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Loading host...");
                              }
                              final email = doc['v_email'] ?? '';
                              final company = doc['v_company_name'] ?? '';
                              final contact = doc['v_contactno'] ?? '';
                              final host = hostSnapshot.hasError || !hostSnapshot.hasData || hostSnapshot.data == null
                                  ? 'N/A'
                                  : hostSnapshot.data;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: $email', style: SystemTheme.body.copyWith(color: Colors.black54)),
                                  Text('Company: $company', style: SystemTheme.body.copyWith(color: Colors.black54)),
                                  Text('Purpose: ${doc['purpose'] ?? 'N/A'}', style: SystemTheme.body.copyWith(color: Colors.black54)),
                                  Text('Contact: $contact', style: SystemTheme.body.copyWith(color: Colors.black54)),
                                  Text('Host: $host', style: SystemTheme.body.copyWith(color: Colors.black54)),
                                ],
                              );
                            }
                          ),
                          trailing: PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert, color: Colors.black),
  onSelected: (value) {
    if (value == 'view') {
      _showVisitorDetailsDialog(doc);
    } else if (value == 'edit') {
      _showVisitorForm(doc);
    } else if (value == 'delete') {
      doc.reference.delete();
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'view',
      child: Row(
        children: const [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')],
      ),
    ),
    PopupMenuItem(
      value: 'edit',
      child: Row(
        children: const [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')],
      ),
    ),
    PopupMenuItem(
      value: 'delete',
      child: Row(
        children: const [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('Delete')],
      ),
    ),
  ],
),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: SystemTheme.primary,
        onPressed: () => _showVisitorForm(),
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Add Visitor',
      ),
    );
  }
}
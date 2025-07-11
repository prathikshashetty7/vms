import 'package:flutter/material.dart';
import '../theme/receptionist_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageVisitors extends StatefulWidget {
  final String? currentDepartmentId;
  const ManageVisitors({Key? key, this.currentDepartmentId}) : super(key: key);

  @override
  _ManageVisitorsState createState() => _ManageVisitorsState();
}

class _ManageVisitorsState extends State<ManageVisitors> {
  // Add missing FocusNodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _designationFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _totalFocus = FocusNode();

  String? get _currentDepartmentId => widget.currentDepartmentId;

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
    _totalFocus.dispose();
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
    String? selectedHostId = visitor?['emp_id'];
    DateTime selectedDate = (visitor?['v_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    TimeOfDay selectedTime = visitor != null && visitor['v_time'] != null
      ? _parseTime(visitor['v_time'])
      : TimeOfDay.now();

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
                    color: ReceptionistTheme.primary.withOpacity(0.12),
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
                            style: ReceptionistTheme.heading.copyWith(fontSize: 20, color: ReceptionistTheme.text),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: vNameController,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_emailFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Name',
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
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
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
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
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vCompanyNameController,
                            focusNode: _companyFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_contactFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Company Name',
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: vContactNoController,
                            focusNode: _contactFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_totalFocus);
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Contact No',
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                  TextFormField(
                    controller: vTotalNoController,
                    focusNode: _totalFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // Optionally submit the form here
                    },
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Total Visitors',
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                                  labelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white, width: 2),
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                                  labelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white, width: 2),
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
                              filled: true,
                              fillColor: Colors.white,
                              hintStyle: ReceptionistTheme.body.copyWith(color: Colors.black.withOpacity(0.6)),
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ReceptionistTheme.primary.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
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
                    'v_contactno': vContactNoController.text,
                    'v_totalno': int.tryParse(vTotalNoController.text) ?? 1,
                    'v_date': Timestamp.fromDate(selectedDate),
                    'v_time': selectedTime.format(context),
                    'emp_id': selectedHostId,
                    'departmentId': _currentDepartmentId,
                  };
                  if (!isEditing) {
                    await FirebaseFirestore.instance.collection('visitor').add(visitorData);
                  } else {
                    await visitor!.reference.update(visitorData);
                  }
                  Navigator.of(context).pop();
                }
              },
                                icon: Icon(isEditing ? Icons.update : Icons.add, color: Colors.white),
                                label: Text(isEditing ? 'Update' : 'Add', style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEditing ? ReceptionistTheme.text : ReceptionistTheme.primary,
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Visitor Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Name: ${visitor['v_name']}'),
                Text('Email: ${visitor['v_email']}'),
                Text('Designation: ${visitor['v_designation']}'),
                Text('Company: ${visitor['v_company_name']}'),
                Text('Contact No: ${visitor['v_contactno']}'),
                Text('Total Visitors: ${visitor['v_totalno']}'),
                FutureBuilder<String>(
                  future: _getHostName(visitor['emp_id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Host: Loading...');
                    }
                    return Text('Host: ${snapshot.data ?? 'N/A'}');
                  },
                ),
                Text('Date: ${_formatDate((visitor['v_date'] as Timestamp).toDate())}'),
                Text('Time: ${visitor['v_time']}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
        body: Column(
          children: [
            _customHeader(),
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
                          title: Text(doc['v_name'], style: ReceptionistTheme.heading.copyWith(fontSize: 16, color: Colors.black)),
                          subtitle: FutureBuilder<String>(
                            future: hostId != null ? _getHostName(hostId) : Future.value('N/A'),
                            builder: (context, hostSnapshot) {
                              if (hostSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Loading host...");
                              }
                              if (hostSnapshot.hasError || !hostSnapshot.hasData || hostSnapshot.data == null) {
                                return Text("Host not found | Total Visitors: $totalVisitors", style: ReceptionistTheme.body.copyWith(color: Colors.black54));
                              }
                              return Text('Host: ${hostSnapshot.data} | Total Visitors: $totalVisitors', style: ReceptionistTheme.body.copyWith(color: Colors.black54));
                            }
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.black), onPressed: () => _showVisitorForm(doc)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.black), onPressed: () => doc.reference.delete()),
                              IconButton(icon: const Icon(Icons.visibility, color: Colors.black), onPressed: () => _showVisitorDetailsDialog(doc)),
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: ReceptionistTheme.primary,
        onPressed: () => _showVisitorForm(),
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Add Visitor',
      ),
    );
  }
}

Widget _customHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: const BoxDecoration(
      color: Color(0xFF6CA4FE),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: Row(
      children: [
        Image.asset('assets/images/rdl.png', height: 32),
        const SizedBox(width: 12),
        const Text('Manage Visitors', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      ],
    ),
  );
} 
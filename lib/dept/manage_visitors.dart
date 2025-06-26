import 'package:flutter/material.dart';
import '../theme/dept_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageVisitors extends StatefulWidget {
  const ManageVisitors({Key? key}) : super(key: key);

  @override
  _ManageVisitorsState createState() => _ManageVisitorsState();
}

class _ManageVisitorsState extends State<ManageVisitors> {
  Future<void> _showAddEditVisitorDialog({DocumentSnapshot? visitor}) async {
    final _formKey = GlobalKey<FormState>();
    final vNameController = TextEditingController(text: visitor?['v_name']);
    final vEmailController = TextEditingController(text: visitor?['v_email']);
    final vDesignationController = TextEditingController(text: visitor?['v_designation']);
    final vCompanyNameController = TextEditingController(text: visitor?['v_company_name']);
    final vContactNoController = TextEditingController(text: visitor?['v_contactno']);
    final vTotalNoController = TextEditingController(text: visitor?['v_totalno']?.toString() ?? '1');
    String? selectedHostId = visitor?['emp_id'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(visitor == null ? 'Add Visitor' : 'Edit Visitor'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: vNameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextFormField(controller: vEmailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextFormField(controller: vDesignationController, decoration: const InputDecoration(labelText: 'Designation')),
                  TextFormField(controller: vCompanyNameController, decoration: const InputDecoration(labelText: 'Company Name')),
                  TextFormField(controller: vContactNoController, decoration: const InputDecoration(labelText: 'Contact No')),
                  TextFormField(
                    controller: vTotalNoController,
                    decoration: const InputDecoration(labelText: 'Total Visitors'),
                    keyboardType: TextInputType.number,
                  ),
                  FutureBuilder<List<DropdownMenuItem<String>>>(
                    future: _getHostDropdownItems(),
                    builder: (context, snapshot) {
                      return DropdownButtonFormField<String>(
                        value: selectedHostId,
                        items: snapshot.data ?? [],
                        onChanged: (val) => selectedHostId = val,
                        decoration: const InputDecoration(labelText: 'Host'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final visitorData = {
                    'v_name': vNameController.text,
                    'v_email': vEmailController.text,
                    'v_designation': vDesignationController.text,
                    'v_company_name': vCompanyNameController.text,
                    'v_contactno': vContactNoController.text,
                    'v_totalno': int.tryParse(vTotalNoController.text) ?? 1,
                    'v_date': Timestamp.now(),
                    'v_time': TimeOfDay.now().format(context),
                    'emp_id': selectedHostId,
                  };

                  if (visitor == null) {
                    await FirebaseFirestore.instance.collection('visitor').add(visitorData);
                  } else {
                    await visitor.reference.update(visitorData);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text(visitor == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      // Dispose controllers when dialog is closed
      [vNameController, vEmailController, vDesignationController, vCompanyNameController, vContactNoController, vTotalNoController].forEach((c) => c.dispose());
    });
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
                Text('Date: ${ (visitor['v_date'] as Timestamp).toDate().toLocal().toString().split(' ')[0]}'),
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
    final snapshot = await FirebaseFirestore.instance.collection('host').get();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeptTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage Visitors', style: DeptTheme.heading),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: DeptTheme.deptPrimary),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: DeptTheme.deptLight.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('visitor').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final totalVisitors = doc['v_totalno'] ?? 1;
                      final hostId = doc['emp_id'];
                      return Card(
                        color: DeptTheme.deptAccent.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(doc['v_name'], style: DeptTheme.body),
                          subtitle: FutureBuilder<String>(
                            future: hostId != null ? _getHostName(hostId) : Future.value('N/A'),
                            builder: (context, hostSnapshot) {
                              if (hostSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Loading host...");
                              }
                              if (hostSnapshot.hasError || !hostSnapshot.hasData || hostSnapshot.data == null) {
                                return Text("Host not found | Total Visitors: $totalVisitors", style: DeptTheme.body);
                              }
                              return Text('Host: ${hostSnapshot.data} | Total Visitors: $totalVisitors', style: DeptTheme.body);
                            }
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: DeptTheme.deptPrimary), onPressed: () => _showAddEditVisitorDialog(visitor: doc)),
                              IconButton(icon: const Icon(Icons.delete, color: DeptTheme.deptDark), onPressed: () => doc.reference.delete()),
                              IconButton(icon: const Icon(Icons.visibility, color: DeptTheme.deptPrimary), onPressed: () => _showVisitorDetailsDialog(doc)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: DeptTheme.deptPrimary,
          onPressed: () => _showAddEditVisitorDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
} 
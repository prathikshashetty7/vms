import 'package:cloud_firestore/cloud_firestore.dart';

class SearchUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search visitors by name, email, or phone number
  static Future<List<Map<String, dynamic>>> searchVisitors({
    required String query,
    String? departmentId,
    String? hostId,
    int limit = 20,
  }) async {
    try {
      List<Map<String, dynamic>> results = [];
      
      // Search in visitor collection
      Query visitorQuery = _firestore.collection('visitor');
      
      // Add filters if provided
      if (departmentId != null) {
        visitorQuery = visitorQuery.where('departmentId', isEqualTo: departmentId);
      }
      if (hostId != null) {
        visitorQuery = visitorQuery.where('emp_id', isEqualTo: hostId);
      }
      
      final visitorSnapshot = await visitorQuery.get();
      
      for (final doc in visitorSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['v_name'] ?? '').toString().toLowerCase();
        final email = (data['v_email'] ?? '').toString().toLowerCase();
        final phone = (data['v_contactno'] ?? '').toString().toLowerCase();
        final company = (data['v_company_name'] ?? '').toString().toLowerCase();
        
        if (name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase()) ||
            phone.contains(query.toLowerCase()) ||
            company.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'visitor',
            'name': data['v_name'] ?? '',
            'email': data['v_email'] ?? '',
            'phone': data['v_contactno'] ?? '',
            'company': data['v_company_name'] ?? '',
            'designation': data['v_designation'] ?? '',
            'purpose': data['purpose'] ?? '',
            'visitDate': data['v_date'],
            'data': data,
          });
        }
      }
      
      // Search in manual_registrations collection
      Query manualQuery = _firestore.collection('manual_registrations');
      
      if (departmentId != null) {
        manualQuery = manualQuery.where('departmentId', isEqualTo: departmentId);
      }
      if (hostId != null) {
        manualQuery = manualQuery.where('emp_id', isEqualTo: hostId);
      }
      
      final manualSnapshot = await manualQuery.get();
      
      for (final doc in manualSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['fullName'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final phone = (data['mobile'] ?? '').toString().toLowerCase();
        final company = (data['company'] ?? '').toString().toLowerCase();
        
        if (name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase()) ||
            phone.contains(query.toLowerCase()) ||
            company.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'manual_registration',
            'name': data['fullName'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['mobile'] ?? '',
            'company': data['company'] ?? '',
            'designation': data['designation'] ?? '',
            'purpose': data['purpose'] ?? '',
            'visitDate': data['v_date'],
            'data': data,
          });
        }
      }
      
      // Sort results by name
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      // Limit results
      if (results.length > limit) {
        results = results.take(limit).toList();
      }
      
      return results;
    } catch (e) {
      print('Error searching visitors: $e');
      return [];
    }
  }

  /// Search hosts by name or email
  static Future<List<Map<String, dynamic>>> searchHosts({
    required String query,
    String? departmentId,
    int limit = 20,
  }) async {
    try {
      Query hostQuery = _firestore.collection('host');
      
      if (departmentId != null) {
        hostQuery = hostQuery.where('departmentId', isEqualTo: departmentId);
      }
      
      final hostSnapshot = await hostQuery.get();
      List<Map<String, dynamic>> results = [];
      
      for (final doc in hostSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['emp_name'] ?? '').toString().toLowerCase();
        final email = (data['emp_email'] ?? '').toString().toLowerCase();
        
        if (name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'host',
            'name': data['emp_name'] ?? '',
            'email': data['emp_email'] ?? '',
            'department': data['department'] ?? '',
            'departmentId': data['departmentId'] ?? '',
            'data': data,
          });
        }
      }
      
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      if (results.length > limit) {
        results = results.take(limit).toList();
      }
      
      return results;
    } catch (e) {
      print('Error searching hosts: $e');
      return [];
    }
  }

  /// Search departments by name
  static Future<List<Map<String, dynamic>>> searchDepartments({
    required String query,
    int limit = 20,
  }) async {
    try {
      final deptSnapshot = await _firestore.collection('department').get();
      List<Map<String, dynamic>> results = [];
      
      for (final doc in deptSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['d_name'] ?? '').toString().toLowerCase();
        
        if (name.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'department',
            'name': data['d_name'] ?? '',
            'data': data,
          });
        }
      }
      
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      if (results.length > limit) {
        results = results.take(limit).toList();
      }
      
      return results;
    } catch (e) {
      print('Error searching departments: $e');
      return [];
    }
  }

  /// Search passes by visitor name or pass number
  static Future<List<Map<String, dynamic>>> searchPasses({
    required String query,
    String? departmentId,
    String? hostId,
    int limit = 20,
  }) async {
    try {
      Query passQuery = _firestore.collection('passes');
      
      if (departmentId != null) {
        passQuery = passQuery.where('departmentId', isEqualTo: departmentId);
      }
      if (hostId != null) {
        passQuery = passQuery.where('emp_id', isEqualTo: hostId);
      }
      
      final passSnapshot = await passQuery.get();
      List<Map<String, dynamic>> results = [];
      
      for (final doc in passSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final passNumber = (data['pass_no'] ?? '').toString().toLowerCase();
        final visitorId = data['visitorId'];
        
        // Check if pass number matches
        if (passNumber.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'pass',
            'passNumber': data['pass_no'] ?? '',
            'visitorId': visitorId,
            'createdAt': data['created_at'],
            'data': data,
          });
        }
        
        // If visitor ID exists, get visitor details and check name
        if (visitorId != null) {
          try {
            final visitorDoc = await _firestore.collection('visitor').doc(visitorId).get();
            if (visitorDoc.exists) {
              final visitorData = visitorDoc.data()!;
              final visitorName = (visitorData['v_name'] ?? '').toString().toLowerCase();
              
              if (visitorName.contains(query.toLowerCase())) {
                results.add({
                  'id': doc.id,
                  'type': 'pass',
                  'passNumber': data['pass_no'] ?? '',
                  'visitorId': visitorId,
                  'visitorName': visitorData['v_name'] ?? '',
                  'createdAt': data['created_at'],
                  'data': data,
                });
              }
            }
          } catch (e) {
            print('Error fetching visitor details: $e');
          }
        }
      }
      
      // Remove duplicates based on pass ID
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (final result in results) {
        uniqueResults[result['id']] = result;
      }
      
      final finalResults = uniqueResults.values.toList();
      finalResults.sort((a, b) => (a['passNumber'] ?? '').compareTo(b['passNumber'] ?? ''));
      
      if (finalResults.length > limit) {
        return finalResults.take(limit).toList();
      }
      
      return finalResults;
    } catch (e) {
      print('Error searching passes: $e');
      return [];
    }
  }

  /// Search check-in/out records by visitor name or status
  static Future<List<Map<String, dynamic>>> searchCheckInOut({
    required String query,
    String? departmentId,
    String? hostId,
    int limit = 20,
  }) async {
    try {
      Query checkInOutQuery = _firestore.collection('checked_in_out');
      
      if (departmentId != null) {
        checkInOutQuery = checkInOutQuery.where('departmentId', isEqualTo: departmentId);
      }
      if (hostId != null) {
        checkInOutQuery = checkInOutQuery.where('emp_id', isEqualTo: hostId);
      }
      
      final checkInOutSnapshot = await checkInOutQuery.get();
      List<Map<String, dynamic>> results = [];
      
      for (final doc in checkInOutSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final visitorId = data['visitor_id'];
        
        // Check if status matches
        if (status.contains(query.toLowerCase())) {
          results.add({
            'id': doc.id,
            'type': 'check_in_out',
            'status': data['status'] ?? '',
            'visitorId': visitorId,
            'checkInTime': data['check_in_time'],
            'checkOutTime': data['check_out_time'],
            'createdAt': data['created_at'],
            'data': data,
          });
        }
        
        // If visitor ID exists, get visitor details and check name
        if (visitorId != null) {
          try {
            final visitorDoc = await _firestore.collection('visitor').doc(visitorId).get();
            if (visitorDoc.exists) {
              final visitorData = visitorDoc.data()!;
              final visitorName = (visitorData['v_name'] ?? '').toString().toLowerCase();
              
              if (visitorName.contains(query.toLowerCase())) {
                results.add({
                  'id': doc.id,
                  'type': 'check_in_out',
                  'status': data['status'] ?? '',
                  'visitorId': visitorId,
                  'visitorName': visitorData['v_name'] ?? '',
                  'checkInTime': data['check_in_time'],
                  'checkOutTime': data['check_out_time'],
                  'createdAt': data['created_at'],
                  'data': data,
                });
              }
            }
          } catch (e) {
            print('Error fetching visitor details: $e');
          }
        }
      }
      
      // Remove duplicates based on record ID
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (final result in results) {
        uniqueResults[result['id']] = result;
      }
      
      final finalResults = uniqueResults.values.toList();
      finalResults.sort((a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      
      if (finalResults.length > limit) {
        return finalResults.take(limit).toList();
      }
      
      return finalResults;
    } catch (e) {
      print('Error searching check-in/out records: $e');
      return [];
    }
  }

  /// Universal search across all collections
  static Future<Map<String, List<Map<String, dynamic>>>> universalSearch({
    required String query,
    String? departmentId,
    String? hostId,
    int limitPerType = 10,
  }) async {
    try {
      final results = <String, List<Map<String, dynamic>>>{};
      
      // Search visitors
      results['visitors'] = await searchVisitors(
        query: query,
        departmentId: departmentId,
        hostId: hostId,
        limit: limitPerType,
      );
      
      // Search hosts
      results['hosts'] = await searchHosts(
        query: query,
        departmentId: departmentId,
        limit: limitPerType,
      );
      
      // Search departments
      results['departments'] = await searchDepartments(
        query: query,
        limit: limitPerType,
      );
      
      // Search passes
      results['passes'] = await searchPasses(
        query: query,
        departmentId: departmentId,
        hostId: hostId,
        limit: limitPerType,
      );
      
      // Search check-in/out records
      results['checkInOut'] = await searchCheckInOut(
        query: query,
        departmentId: departmentId,
        hostId: hostId,
        limit: limitPerType,
      );
      
      return results;
    } catch (e) {
      print('Error in universal search: $e');
      return {};
    }
  }

  /// Get entity details by ID
  static Future<Map<String, dynamic>?> getEntityDetails({
    required String entityType,
    required String entityId,
  }) async {
    try {
      DocumentSnapshot doc;
      
      switch (entityType) {
        case 'visitor':
          doc = await _firestore.collection('visitor').doc(entityId).get();
          break;
        case 'manual_registration':
          doc = await _firestore.collection('manual_registrations').doc(entityId).get();
          break;
        case 'host':
          doc = await _firestore.collection('host').doc(entityId).get();
          break;
        case 'department':
          doc = await _firestore.collection('department').doc(entityId).get();
          break;
        case 'pass':
          doc = await _firestore.collection('passes').doc(entityId).get();
          break;
        case 'check_in_out':
          doc = await _firestore.collection('checked_in_out').doc(entityId).get();
          break;
        default:
          return null;
      }
      
      if (doc.exists) {
        return {
          'id': doc.id,
          'type': entityType,
          'data': doc.data() as Map<String, dynamic>,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting entity details: $e');
      return null;
    }
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String hostId;
  final String visitorId;
  final String visitorName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.hostId,
    required this.visitorId,
    required this.visitorName,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      visitorId: data['visitorId'] ?? '',
      visitorName: data['visitorName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'visitorId': visitorId,
      'visitorName': visitorName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  static Future<void> sendNotification({
    required String hostId,
    required String visitorId,
    required String visitorName,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('notification').add({
      'hostId': hostId,
      'visitorId': visitorId,
      'visitorName': visitorName,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  static Stream<List<AppNotification>> getHostNotifications(String hostId) {
    return FirebaseFirestore.instance
        .collection('notification')
        .where('hostId', isEqualTo: hostId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList());
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance.collection('notification').doc(notificationId).update({'isRead': true});
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsCollection(String uid) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications(String uid) {
    return _itemsCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _itemsCollection(uid).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String uid, List<String> unreadIds) async {
    if (unreadIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in unreadIds) {
      batch.update(_itemsCollection(uid).doc(id), {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<String?> getFcmToken(String uid, {String? role}) async {
    try {
      if (role != null) {
        final collection =
            role == 'company' ? 'companies' : 'jobSeekers';
        final doc = await _firestore.collection(collection).doc(uid).get();
        final token = doc.data()?['fcmToken'] as String?;
        if (token != null) return token;
      } else {
        final seekerDoc =
            await _firestore.collection('jobSeekers').doc(uid).get();
        final seekerToken = seekerDoc.data()?['fcmToken'] as String?;
        if (seekerToken != null) return seekerToken;

        final companyDoc =
            await _firestore.collection('companies').doc(uid).get();
        final companyToken = companyDoc.data()?['fcmToken'] as String?;
        if (companyToken != null) return companyToken;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data()?['fcmToken'] as String?;
    } catch (e) {
      debugPrint('Error in NotificationRepository.getFcmToken: $e');
      return null;
    }
  }
}

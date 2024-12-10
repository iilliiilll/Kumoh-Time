import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => _notifications;

  // Firestore에서 알림 가져오기
  Future<void> fetchNotifications(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      _notifications.clear();
      _notifications.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList());
      notifyListeners();
    } catch (e) {
      print('알림 가져오기 실패: $e');
    }
  }

  // 알림 삭제하기
  Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _notifications
          .removeWhere((notification) => notification['id'] == notificationId);
      notifyListeners();
    } catch (e) {
      print('알림 삭제 실패: $e');
    }
  }

  // 알림 모두 초기화
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}

Future<void> addNotificationToAllUsers(
    String title, String body, String postId) async {
  try {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'postId': postId, // 게시글 ID 추가
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    print('모든 사용자에게 알림 전송 완료');
  } catch (e) {
    print('알림 전송 실패: $e');
    rethrow; // 예외를 다시 던져 호출한 쪽에서 처리하도록 함
  }
}

Future<void> addNotification(
    String userId, String title, String body, String postId) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'postId': postId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('알림 추가 실패: $e');
  }
}

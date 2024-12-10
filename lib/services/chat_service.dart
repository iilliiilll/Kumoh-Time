import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getMessages(String roomId) {
    return _firestore
        .collection('chatrooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(String roomId, String message) async {
    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data()!;

    await _firestore
        .collection('chatrooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': user.uid, // 프로필 조회용 ID
      'senderName': '${userData['department']} - ${userData['year']}학년',
      'senderDepartment': userData['department'], // 프로필 표시용
      'senderYear': userData['year'], // 프로필 표시용
      'message': message,
      'timestamp': Timestamp.now(),
    });
  }

  Future<String> getOrCreatePersonalChatRoom(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    // 채팅방 ID를 정렬된 userId로 생성하여 항상 동일한 ID가 생성되도록 함
    final users = [currentUserId, otherUserId]..sort();
    final chatRoomId = 'personal_${users[0]}_${users[1]}';

    final chatRoomRef = _firestore.collection('personal_chats').doc(chatRoomId);
    final chatRoom = await chatRoomRef.get();

    if (!chatRoom.exists) {
      // 채팅방이 없으면 새로 생성
      await chatRoomRef.set({
        'users': users,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    return chatRoomId;
  }

  // 1:1 채팅 메시지 가져오기
  Stream<QuerySnapshot> getPersonalMessages(String chatRoomId) {
    return _firestore
        .collection('personal_chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 1:1 채팅 메시지 보내기
  Future<void> sendPersonalMessage(String chatRoomId, String message) async {
    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data()!;

    final batch = _firestore.batch();

    // 메시지 추가
    final messageRef = _firestore
        .collection('personal_chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': user.uid,
      'senderName': userData['name'],
      'senderDepartment': userData['department'],
      'senderYear': userData['year'],
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 마지막 메시지 업데이트
    final chatRoomRef = _firestore.collection('personal_chats').doc(chatRoomId);
    batch.update(chatRoomRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

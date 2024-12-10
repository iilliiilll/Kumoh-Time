import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';

class ChatRoomProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, ChatRoom> _chatRooms = {};

  Map<String, ChatRoom> get chatRooms => _chatRooms;

  void initialize() {
    // 각 채팅방의 메시지 구독
    final rooms = ['year_1', 'year_2', 'year_3', 'year_4', 'year_5'];

    for (var roomId in rooms) {
      _firestore
          .collection('chatrooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final lastMessage = snapshot.docs.first.data()['message'] as String;
          updateLastMessage(roomId, lastMessage);
        }
      });
    }
  }

  void updateLastMessage(String roomId, String message) {
    if (_chatRooms.containsKey(roomId)) {
      _chatRooms[roomId]!.lastMessage = message;
    } else {
      _chatRooms[roomId] = ChatRoom(
        id: roomId,
        year: _getYearTitle(roomId),
        lastMessage: message,
        members: [],
      );
    }
    notifyListeners();
  }

  String _getYearTitle(String roomId) {
    switch (roomId) {
      case 'year_1':
        return '1학년';
      case 'year_2':
        return '2학년';
      case 'year_3':
        return '3학년';
      case 'year_4':
        return '4학년';
      case 'year_5':
        return '전체 채팅방';
      default:
        return '';
    }
  }
}

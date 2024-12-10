import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomScreen extends StatefulWidget {
  final String yearTitle;
  final String roomId;

  const ChatRoomScreen({
    super.key,
    required this.yearTitle,
    required this.roomId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.yearTitle} 채팅방'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (messages.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    final timestamp =
                        (message['timestamp'] as Timestamp).toDate();

                    return MessageBubble(
                      sender: message['senderName'],
                      message: message,
                      isMe: isMe,
                      time: DateFormat('HH:mm').format(timestamp),
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: () async {
              if (_messageController.text.trim().isNotEmpty) {
                await _chatService.sendMessage(
                    widget.roomId, _messageController.text);
                _messageController.clear();
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final Map<String, dynamic> message;
  final bool isMe;
  final String time;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.message,
    required this.isMe,
    required this.time,
  });

  Future<void> _sendFriendRequest(
      BuildContext context, String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final senderName = userDoc.data()?['name'] ?? '이름 없음';
      final senderDepartment = userDoc.data()?['department'] ?? '학과 정보 없음';
      final senderYear = userDoc.data()?['year'] ?? '학년 정보 없음';

      // 받는 사람의 received_requests 컬렉션에 추가
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('received_requests')
          .doc(currentUser.uid)
          .set({
        'id': currentUser.uid,
        'name': senderName,
        'department': senderDepartment,
        'year': senderYear,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 보낸 사람의 sent_requests 컬렉션에 추가
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('sent_requests')
          .doc(targetUserId)
          .set({
        'id': targetUserId,
        'name': sender,
        'department': message['senderDepartment'] ?? '학과 정보 없음',
        'year': message['senderYear'] ?? '학년 정보 없음',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 보냈습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String departmentYear =
        '${message['senderDepartment']} - ${message['senderYear']}학년';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              sender[0],
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            sender,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            departmentYear,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _sendFriendRequest(
                                context, message['senderId']),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('친구 추가'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(sender[0]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  departmentYear,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(message['message']),
              ),
              Text(time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

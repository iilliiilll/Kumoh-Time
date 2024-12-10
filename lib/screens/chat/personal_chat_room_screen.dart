import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String friendName;
  final String friendInfo;

  const PersonalChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.friendName,
    required this.friendInfo,
  });

  @override
  State<PersonalChatRoomScreen> createState() => _PersonalChatRoomScreenState();
}

class _PersonalChatRoomScreenState extends State<PersonalChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 초기 로드 시 스크롤을 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.friendName),
            Text(
              widget.friendInfo,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getPersonalMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                // 데이터가 로드되면 스크롤을 아래로 이동
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

                    // Timestamp null 체크 추가
                    final timestamp = message['timestamp'];
                    final timeString = timestamp != null
                        ? DateFormat('HH:mm')
                            .format((timestamp as Timestamp).toDate())
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(message['senderName'][0]),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message['senderName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(message['message']),
                              ),
                              if (timeString.isNotEmpty) // 시간이 있을 때만 표시
                                Text(
                                  timeString,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.trim().isNotEmpty) {
                      await _chatService.sendPersonalMessage(
                        widget.chatRoomId,
                        _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
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

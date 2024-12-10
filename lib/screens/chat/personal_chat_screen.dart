import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'personal_chat_room_screen.dart';
import 'package:intl/intl.dart';

class PersonalChatScreen extends StatelessWidget {
  const PersonalChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('personal_chats')
          .where('users', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('진행 중인 1:1 채팅이 없습니다.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatRoom = snapshot.data!.docs[index];
            final chatData = chatRoom.data() as Map<String, dynamic>;
            final users = List<String>.from(chatData['users'] ?? []);
            final otherUserId = users.firstWhere((id) => id != currentUserId);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? '이름 없음';
                final userDepartment = userData['department'] ?? '학과 정보 없음';
                final userYear = userData['year'] ?? '';
                final lastMessage = chatData['lastMessage'] ?? '';
                final lastMessageTime =
                    chatData['lastMessageTime'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(userName[0]),
                    ),
                    title: Text('$userName ($userDepartment $userYear학년)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lastMessage),
                        if (lastMessageTime != null)
                          Text(
                            DateFormat('MM/dd HH:mm')
                                .format(lastMessageTime.toDate()),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalChatRoomScreen(
                            chatRoomId: chatRoom.id,
                            friendName: userName,
                            friendInfo: '$userDepartment $userYear학년',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

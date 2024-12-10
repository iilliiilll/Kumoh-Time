import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_room_provider.dart';

class DepartmentChatScreen extends StatefulWidget {
  const DepartmentChatScreen({super.key});

  @override
  State<DepartmentChatScreen> createState() => _DepartmentChatScreenState();
}

class _DepartmentChatScreenState extends State<DepartmentChatScreen> {
  String _departmentName = '학과 로딩중...';

  @override
  void initState() {
    super.initState();
    _loadDepartmentInfo();
    Provider.of<ChatRoomProvider>(context, listen: false).initialize();
  }

  Future<void> _loadDepartmentInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _departmentName = userDoc.data()?['department'] ?? '학과 정보 없음';
          });
        }
      } catch (e) {
        print('학과 정보 로딩 오류: $e');
        setState(() {
          _departmentName = '학과 정보 오류';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.school, size: 24),
              const SizedBox(width: 8),
              Text(
                _departmentName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<ChatRoomProvider>(
            builder: (context, chatRoomProvider, child) {
              final rooms = chatRoomProvider.chatRooms;
              return ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final roomId = 'year_${index + 1}';
                  final room = rooms[roomId];
                  final yearTitle = _getYearTitle(index);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            yearTitle: yearTitle,
                            roomId: roomId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.blue[400],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  yearTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  room?.lastMessage ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getYearTitle(int index) {
    switch (index) {
      case 0:
        return '1학년';
      case 1:
        return '2학년';
      case 2:
        return '3학년';
      case 3:
        return '4학년';
      case 4:
        return '전체 채팅방';
      default:
        return '';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_fb/screens/chat/personal_chat_room_screen.dart';
import 'package:flutter_fb/services/chat_service.dart';
import 'package:intl/intl.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String selectedTab = 'friends';

// 친구 요청 수락하기
  Future<void> _acceptFriendRequest(
      String requestId, String name, String id) async {
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 상대방 정보 가져오기
      final otherUserDoc = await usersCollection.doc(id).get();
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>?;

      if (otherUserData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상대방 정보를 가져오는 데 실패했습니다.')),
        );
        return;
      }

      // 1. 현재 사용자의 friends 하위 컬렉션에 상대방 추가
      final currentUserFriend =
          usersCollection.doc(currentUser!.uid).collection('friends').doc(id);
      batch.set(currentUserFriend, {
        'name': name,
        'id': id,
        'department': otherUserData['department'] ?? '학과 정보 없음',
        'year': otherUserData['year'] ?? '학년 정보 없음',
      });

      // 2. 상대방의 friends 하위 컬렉션에 현재 사용자 추가
      final currentUserDoc = await usersCollection.doc(currentUser!.uid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

      final otherUserFriend =
          usersCollection.doc(id).collection('friends').doc(currentUser!.uid);
      batch.set(otherUserFriend, {
        'name': currentUserData?['name'] ?? '이름 없음',
        'id': currentUser!.uid,
        'department': currentUserData?['department'] ?? '학과 정보 없음',
        'year': currentUserData?['year'] ?? '학년 정보 없음',
      });

      // 3. 현재 사용자의 received_requests에서 요청 삭제
      final receivedRequestDoc = usersCollection
          .doc(currentUser!.uid)
          .collection('received_requests')
          .doc(id);
      batch.delete(receivedRequestDoc);

      // 4. 상대방의 sent_requests에서 요청 삭제
      final sentRequestDoc = usersCollection
          .doc(id)
          .collection('sent_requests')
          .doc(currentUser!.uid);
      batch.delete(sentRequestDoc);

      // 모든 작업을 한번에 실행
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 수락했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

// 친구 요청 거절하기
  Future<void> _rejectFriendRequest(String requestId) async {
    if (currentUser == null) return; // 사용자가 로그인하지 않은 경우

    try {
      // 친구 요청 삭제 전 확인 다이얼로그
      final bool? confirmReject = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('친구 요청 거절'),
            content: const Text('정말 이 친구 요청을 거절하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (confirmReject != true) return; // 거절 취소 시

      // 친구 요청 삭제
      await usersCollection
          .doc(currentUser!.uid)
          .collection('received_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 거절했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

// 친구 신청 취소하기
  Future<void> _cancelSentRequest(String requestId) async {
    if (currentUser == null) return; // 사용자가 로그인하지 않은 경우

    try {
      // 친구 요청 취소 전 확인 다이얼로그
      final bool? confirmCancel = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('친구 요청 취소'),
            content: const Text('정말 이 친구 요청을 취소하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (confirmCancel != true) return; // 취소 확인하지 않은 경우

      // 보낸 친구 요청 취소
      await usersCollection
          .doc(currentUser!.uid)
          .collection('sent_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 취소했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _removeFriend(String friendId) async {
    if (currentUser == null) return;

    try {
      final bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('친구 삭제'),
            content: const Text('정말 이 친구를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          );
        },
      );

      if (confirmDelete != true) return;

      // batch 작업 시작
      final batch = FirebaseFirestore.instance.batch();

      // 1. 내 friends 컬렉션에서 친구 삭제
      final myFriendDoc = usersCollection
          .doc(currentUser!.uid)
          .collection('friends')
          .doc(friendId);
      batch.delete(myFriendDoc);

      // 2. 상대방의 friends 컬렉션에서 나를 삭제
      final theirFriendDoc = usersCollection
          .doc(friendId)
          .collection('friends')
          .doc(currentUser!.uid);
      batch.delete(theirFriendDoc);

      // batch 작업 실행
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구를 삭제했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('로그인 상태를 확인해주세요.'));
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 'friends';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTab == 'friends'
                        ? Colors.pink[300]
                        : Colors.pink[100],
                  ),
                  child: const Text('친구'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 'sent_requests';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTab == 'sent_requests'
                        ? Colors.pink[300]
                        : Colors.pink[100],
                  ),
                  child: const Text('신청'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 'received_requests';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTab == 'received_requests'
                        ? Colors.pink[300]
                        : Colors.pink[100],
                  ),
                  child: const Text('요청'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (selectedTab == 'friends') {
                  return _buildFriendsList();
                } else if (selectedTab == 'sent_requests') {
                  return _buildSentRequestsList();
                } else if (selectedTab == 'received_requests') {
                  return _buildReceivedRequestsList();
                } else {
                  return const Center(child: Text('잘못된 탭 선택'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

// 친구 목록 리스트
  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersCollection
          .doc(currentUser!.uid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('친구가 없습니다.'),
          );
        }

        final friendsDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: friendsDocs.length,
          itemBuilder: (context, index) {
            final friendData =
                friendsDocs[index].data() as Map<String, dynamic>;
            final friendId = friendsDocs[index].id;

            return Card(
              color:
                  index % 2 == 0 ? Colors.lightBlue[50] : Colors.lightGreen[50],
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.primaries[index % Colors.primaries.length],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  friendData['name'] ?? '이름 없음',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${friendData['department'] ?? '학과 없음'} - ${friendData['year'] ?? '학년 없음'}학년',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFriend(friendId),
                ),
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
                                (friendData['name'] ?? '이름 없음')[0],
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              friendData['name'] ?? '이름 없음',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${friendData['department'] ?? '학과 없음'} - ${friendData['year'] ?? '학년 없음'}학년',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                // 채팅방 생성 또는 가져오기
                                final chatRoomId = await ChatService()
                                    .getOrCreatePersonalChatRoom(friendId);

                                Navigator.pop(context); // 다이얼로그 닫기
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PersonalChatRoomScreen(
                                      chatRoomId: chatRoomId,
                                      friendName: friendData['name'] ?? '이름 없음',
                                      friendInfo:
                                          '${friendData['department'] ?? '학과 없음'} - ${friendData['year'] ?? '학년 없음'}학년',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('1:1 채팅하기'),
                            ),
                          ],
                        ),
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
  }

// 친구 요청 보낸거
  Widget _buildSentRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersCollection
          .doc(currentUser!.uid)
          .collection('sent_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('보낸 친구 요청이 없습니다.'),
          );
        }

        final sentRequestDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: sentRequestDocs.length,
          itemBuilder: (context, index) {
            final requestData =
                sentRequestDocs[index].data() as Map<String, dynamic>;
            final requestId = sentRequestDocs[index].id;

            // Timestamp 변환
            final Timestamp? timestamp = requestData['timestamp'] as Timestamp?;
            final String formattedTimestamp = timestamp != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                : '시간 정보 없음';

            return Card(
              color: Colors.orange[50],
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: Text(requestData['name'] ?? '이름 없음',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formattedTimestamp),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _cancelSentRequest(requestId),
                ),
              ),
            );
          },
        );
      },
    );
  }

// 친구 요청 받은거
  Widget _buildReceivedRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersCollection
          .doc(currentUser!.uid)
          .collection('received_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('받은 친구 요청이 없습니다.'),
          );
        }

        final requestDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            final requestData =
                requestDocs[index].data() as Map<String, dynamic>;
            final requestId = requestDocs[index].id;

            // Timestamp 변환
            final Timestamp? timestamp = requestData['timestamp'] as Timestamp?;
            final String formattedTimestamp = timestamp != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                : '시간 정보 없음';

            return Card(
              color: Colors.pink[50],
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.pink,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(requestData['name'] ?? '이름 없음',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formattedTimestamp),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptFriendRequest(
                        requestId,
                        requestData['name'] ?? '이름 없음',
                        requestData['id'] ?? 'ID 없음',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('수락'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _rejectFriendRequest(requestId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('거절'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

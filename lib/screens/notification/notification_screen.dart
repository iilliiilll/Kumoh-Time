import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../board/post_detail_screen.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('알림을 불러오는 중 문제가 발생했습니다.'),
            );
          }

          return Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final notifications = notificationProvider.notifications;

              if (notifications.isEmpty) {
                return const Center(child: Text('알림이 없습니다.'));
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    title: Text(notification['title'] ?? ''),
                    subtitle: Text(notification['body'] ?? ''),
                    onTap: () async {
                      // 게시글 ID로 Firestore에서 데이터 가져오기
                      final postId = notification['postId'];
                      if (postId != null) {
                        final postSnapshot = await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .get();
                        if (postSnapshot.exists) {
                          final post = postSnapshot.data();
                          post?['id'] = postId; // ID 추가
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: post!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('게시글을 찾을 수 없습니다.')),
                          );
                        }
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        notificationProvider
                            .deleteNotification(notification['id']);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

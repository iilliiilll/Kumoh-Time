import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'post_create_screen.dart';
import 'post_detail_screen.dart';
import 'post_provider.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostProvider(),
      child: _BoardScreenContent(),
    );
  }
}

class _BoardScreenContent extends StatelessWidget {
  Future<void> _navigateToCreatePost(
      BuildContext context, PostProvider postProvider) async {
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostCreateScreen()),
    );

    if (newPost != null) {
      try {
        await postProvider.addPost(newPost);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 저장되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 저장에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (postProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: postProvider.setupPostsListener,
                        child: const Text('게시물'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          postProvider.sortByPopularity();
                        },
                        child: const Text('인기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: postProvider.filterMyPosts,
                        child: const Text('나의 글'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: postProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = postProvider.posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                post['title'] ?? '제목 없음',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post['department'] != null)
                              Text(
                                '${post['department']}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post['content'] ?? '내용 없음'),
                            if (post['createdAt'] != null)
                              Text(
                                '작성일: ${DateFormat('yyyy-MM-dd HH:mm').format((post['createdAt'] as Timestamp).toDate())}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            Text(
                              '추천: ${post['likes'] ?? 0}, 댓글: ${post['comments'] ?? 0}',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: post),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToCreatePost(context, postProvider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

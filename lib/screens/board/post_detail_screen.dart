import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late int _likes;
  late bool _hasLiked = false;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, Map<String, int>> _userDepartmentIndexMap = {};
  int _currentIndex = 1;

  int _getUserDepartmentIndex(String userId, String department) {
    if (!_userDepartmentIndexMap.containsKey(department)) {
      _userDepartmentIndexMap[department] = {};
    }
    if (!_userDepartmentIndexMap[department]!.containsKey(userId)) {
      _userDepartmentIndexMap[department]![userId] = _currentIndex++;
    }
    return _userDepartmentIndexMap[department]![userId]!;
  }

  @override
  void initState() {
    super.initState();
    _likes = widget.post['likes'] ?? 0;
    _checkIfUserHasLiked();
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      if (widget.post['location'] != null) {
        final nMapUrl =
            'nmap://place?lat=${widget.post['location']['latitude']}&lng=${widget.post['location']['longitude']}&name=${Uri.encodeComponent(widget.post['location']['address'])}';
        final webUrl =
            'https://map.naver.com/v5/search/${Uri.encodeComponent(widget.post['location']['address'])}/@${widget.post['location']['longitude']},${widget.post['location']['latitude']}';

        final nMapUri = Uri.parse(nMapUrl);
        if (!await launchUrl(nMapUri)) {
          final webUri = Uri.parse(webUrl);
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도를 열 수 없습니다.')),
      );
    }
  }

  Widget _buildContent(String content) {
    final List<String> parts = content.split('🔗 지도 링크: ');
    if (parts.length == 2) {
      final String mainContent = parts[0];
      final String urlPart = parts[1].trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(mainContent),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _launchUrl(urlPart),
            child: Text(
              '🔗 지도 링크: $urlPart',
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    return SelectableText(content);
  }

  Future<void> _checkIfUserHasLiked() async {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _hasLiked = false;
      });
      return;
    }

    final likeDoc = await _firestore
        .collection('posts')
        .doc(widget.post['id'])
        .collection('likes')
        .doc(userId)
        .get();

    setState(() {
      _hasLiked = likeDoc.exists;
    });
  }

  Future<void> _toggleLike() async {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (_hasLiked) {
      setState(() {
        _likes--;
        _hasLiked = false;
      });

      try {
        await _firestore.collection('posts').doc(widget.post['id']).update({
          'likes': _likes,
        });

        await _firestore
            .collection('posts')
            .doc(widget.post['id'])
            .collection('likes')
            .doc(userId)
            .delete();
      } catch (e) {
        print('추천 취소 실패: $e');
      }
    } else {
      setState(() {
        _likes++;
        _hasLiked = true;
      });

      try {
        await _firestore.collection('posts').doc(widget.post['id']).update({
          'likes': _likes,
        });

        await _firestore
            .collection('posts')
            .doc(widget.post['id'])
            .collection('likes')
            .doc(userId)
            .set({
          'likedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('추천 추가 실패: $e');
      }
    }
  }

  Future<void> _addComment(String comment) async {
    if (comment.isNotEmpty) {
      _commentController.clear();

      try {
        final userId = _auth.currentUser?.uid;

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 필요합니다.')),
          );
          return;
        }

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final department = userDoc.data()?['department'] ?? '학과 정보 없음';
        final departmentIndex = _getUserDepartmentIndex(userId, department);

        await _firestore
            .collection('posts')
            .doc(widget.post['id'])
            .collection('comments')
            .add({
          'content': comment,
          'authorId': userId,
          'department': department,
          'departmentIndex': departmentIndex,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('posts').doc(widget.post['id']).update({
          'comments': FieldValue.increment(1),
        });
      } catch (e) {
        print('댓글 추가 실패: $e');
      }
    }
  }

  Future<void> _confirmAndDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('게시글을 삭제하시겠습니까? 삭제된 게시글은 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePost();
    }
  }

  Future<void> _deletePost() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != widget.post['authorId']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 삭제 권한이 없습니다.')),
        );
        return;
      }

      await _firestore.collection('posts').doc(widget.post['id']).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('게시글 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _confirmAndDeleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('댓글 삭제'),
          content: const Text('댓글을 삭제하시겠습니까? 삭제된 댓글은 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteComment(commentId);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      await _firestore
          .collection('posts')
          .doc(widget.post['id'])
          .collection('comments')
          .doc(commentId)
          .delete();

      await _firestore.collection('posts').doc(widget.post['id']).update({
        'comments': FieldValue.increment(-1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } catch (e) {
      print('댓글 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.post['title'],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.post['department'] != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  widget.post['department'],
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          if (widget.post['authorId'] == _auth.currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmAndDeletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(widget.post['content']),
                    const SizedBox(height: 8),
                    if (widget.post['createdAt'] != null)
                      Text(
                        '작성일: ${DateFormat('yyyy-MM-dd HH:mm').format((widget.post['createdAt'] as Timestamp).toDate())}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            Icons.thumb_up,
                            color: _hasLiked ? Colors.blue : Colors.grey,
                          ),
                        ),
                        Text(
                          '$_likes',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text('댓글',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('posts')
                          .doc(widget.post['id'])
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final comments = snapshot.data!.docs;

                        return Column(
                          children: comments.map((doc) {
                            final commentData =
                                doc.data() as Map<String, dynamic>;
                            final commentId = doc.id;
                            final isAuthor = commentData['authorId'] ==
                                _auth.currentUser?.uid;
                            final department =
                                commentData['department'] ?? '학과 정보 없음';
                            final departmentIndex =
                                commentData['departmentIndex'] ?? 1;

                            return ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (commentData['department'] != null)
                                    Text(
                                      '$department$departmentIndex',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  Text(commentData['content'] ?? ''),
                                ],
                              ),
                              leading: const Icon(Icons.comment),
                              subtitle: Text(
                                commentData['timestamp'] != null
                                    ? DateFormat('yyyy-MM-dd HH:mm').format(
                                        (commentData['timestamp'] as Timestamp)
                                            .toDate())
                                    : '시간 정보 없음',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              trailing: isAuthor
                                  ? IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmAndDeleteComment(commentId),
                                    )
                                  : null,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addComment(_commentController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

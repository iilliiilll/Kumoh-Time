import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  StreamSubscription? _postsSubscription;

  List<Map<String, dynamic>> get posts => _posts;
  bool get isLoading => _isLoading;

  PostProvider() {
    setupPostsListener();
  }

  void setupPostsListener() {
    _postsSubscription?.cancel();
    _postsSubscription = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true) // 최신 글부터 정렬
        .snapshots()
        .listen((snapshot) {
      _posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  void sortByPopularity() {
    // Firestore 쿼리로 전체 게시글을 추천순으로 가져옴
    _firestore
        .collection('posts')
        .orderBy('likes', descending: true) // 추천 순으로 정렬
        .get()
        .then((snapshot) {
      _posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    }).catchError((e) {
      print('인기 게시글 불러오기 실패: $e');
    });
  }

  void filterMyPosts() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _posts =
          _posts.where((post) => post['authorId'] == currentUser.uid).toList();

      // 최신순으로 정렬
      _posts.sort((a, b) {
        final Timestamp aCreatedAt = a['createdAt'];
        final Timestamp bCreatedAt = b['createdAt'];
        return bCreatedAt.compareTo(aCreatedAt); // 내림차순 정렬
      });

      notifyListeners(); // UI 업데이트
    }
  }

  Future<void> addPost(Map<String, dynamic> post) async {
    try {
      await _firestore.collection('posts').add(post);
    } catch (e) {
      print('게시글 저장 실패: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }
}

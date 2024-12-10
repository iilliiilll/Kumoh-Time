import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'location_select_screen.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Map<String, dynamic>? _selectedLocation;

  void _savePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final department = userDoc.data()?['department'] ?? '학과 정보 없음';

      final postData = {
        'title': title,
        'content': content,
        'authorId': userId,
        'department': department,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      };

      if (_selectedLocation != null) {
        final location = _selectedLocation!['location'] as NLatLng;
        postData['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': _selectedLocation!['address'],
          'mapUrl': _selectedLocation!['mapUrl'],
        };

        postData['content'] = '''$content

      📍 위치: ${_selectedLocation!['address']}
      🔗 지도 링크: ${_selectedLocation!['mapUrl']}
      ''';
      }

      Navigator.pop(context, postData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelectScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedLocation != null
                        ? '선택된 위치: ${_selectedLocation!['address']}'
                        : '위치를 선택해주세요',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _selectLocation,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _savePost,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

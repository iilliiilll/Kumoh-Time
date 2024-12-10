import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../screens/login/login_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(
      msg: '로그아웃 되었습니다',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 2 / 3,
      child: Container(
        color: Colors.white,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userName = userData['name'] ?? '사용자 이름';
            final userEmail =
                FirebaseAuth.instance.currentUser?.email ?? 'user@email.com';
            final department = userData['department'] ?? '학과 정보 없음';
            final year = userData['year'] ?? '';

            return ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text("$userName ($department $year학년)"),
                  accountEmail: Text(userEmail),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0] : '?',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('설정'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('로그아웃'),
                  onTap: () => _handleLogout(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

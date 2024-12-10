import 'package:flutter/material.dart';
import '../board/board_screen.dart';
import '../chat/department_chat_screen.dart';
import '../chat/personal_chat_screen.dart';
import '../friends/friends_screen.dart';
import '../notification/notification_screen.dart';
import '../../widgets/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 화면별 타이틀 리스트 추가
  final List<String> _screenTitles = [
    '금오공대 게시판',
    '학과채팅',
    '개인채팅',
    '친구목록',
  ];

  final List<Widget> _screens = [
    const BoardScreen(),
    const DepartmentChatScreen(),
    const PersonalChatScreen(),
    const FriendsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '학과채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '개인채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '친구목록',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

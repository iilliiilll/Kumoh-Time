class ChatRoom {
  final String id;
  final String year;
  String lastMessage;
  final List<String> members;

  ChatRoom({
    required this.id,
    required this.year,
    this.lastMessage = '',
    required this.members,
  });
}

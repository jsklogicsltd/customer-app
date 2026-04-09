class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String timestamp;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      text: map['text'],
      timestamp: map['timestamp'],
      isMe: map['isMe'],
    );
  }
}

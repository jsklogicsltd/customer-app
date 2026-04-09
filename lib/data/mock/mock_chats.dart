import '../../models/chat_message.dart';

final Map<String, List<ChatMessage>> mockChatsData = {
  'chat_cust001_v001': [
    ChatMessage.fromMap({
      'id': 'msg001',
      'senderId': 'cust001',
      'text': "Salam! I'm interested in your Phulkari Dupatta.",
      'timestamp': '10:30 AM',
      'isMe': true,
    }),
    ChatMessage.fromMap({
      'id': 'msg002',
      'senderId': 'v001',
      'text': "Walaikum Salam! Yes it's available. What quantity do you need?",
      'timestamp': '10:32 AM',
      'isMe': false,
    }),
    ChatMessage.fromMap({
      'id': 'msg003',
      'senderId': 'cust001',
      'text': 'I need 5 pieces. Can you do custom colors?',
      'timestamp': '10:35 AM',
      'isMe': true,
    }),
    ChatMessage.fromMap({
      'id': 'msg004',
      'senderId': 'v001',
      'text': 'Yes, custom colors available! Please share your color reference. Delivery in 10 days.',
      'timestamp': '10:40 AM',
      'isMe': false,
    }),
  ],
};

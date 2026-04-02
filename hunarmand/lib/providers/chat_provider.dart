import 'package:flutter/material.dart';
import '../data/mock/mock_chats.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _chats = {};
  final Map<String, bool> _vendorTyping = {};
  int _msgCounter = 10;

  ChatProvider() {
    mockChatsData.forEach((key, messages) {
      _chats[key] = List.from(messages);
    });
  }

  List<ChatMessage> getMessages(String chatId) => _chats[chatId] ?? [];

  bool isVendorTyping(String chatId) => _vendorTyping[chatId] ?? false;

  void sendMessage(String chatId, String text) {
    _chats.putIfAbsent(chatId, () => []);
    _chats[chatId]!.add(ChatMessage(
      id: 'msg_${_msgCounter++}',
      senderId: 'cust001',
      text: text,
      timestamp: _formatTime(),
      isMe: true,
    ));
    notifyListeners();

    // Simulate vendor typing
    _vendorTyping[chatId] = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _vendorTyping[chatId] = false;
      notifyListeners();
    });
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

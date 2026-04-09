import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Map<String, List<ChatMessage>> _chats = {};
  final Map<String, bool> _vendorTyping = {};
  final Map<String, StreamSubscription?> _subs = {};

  List<ChatMessage> getMessages(String chatId) {
    if (!_subs.containsKey(chatId)) {
      _initChatListener(chatId);
    }
    return _chats[chatId] ?? [];
  }

  bool isVendorTyping(String chatId) => _vendorTyping[chatId] ?? false;

  void _initChatListener(String chatId) {
    _subs[chatId] = _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      _chats[chatId] = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Assume 'isMe' is derived from senderId == currentUser.uid
        data['isMe'] = data['senderId'] == _auth.currentUser?.uid;
        return ChatMessage.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    for (var sub in _subs.values) {
      sub?.cancel();
    }
    super.dispose();
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('messages').add({
      'chatId': chatId,
      'senderId': user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

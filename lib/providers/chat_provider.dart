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
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['isMe'] = data['senderId'] == _auth.currentUser?.uid;
        return ChatMessage.fromMap(data);
      }).toList();

      // Client-side sort: timestamp ascending
      messages.sort((a, b) {
        final aTime = (a.timestamp as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b.timestamp as Timestamp?)?.toDate() ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });

      _chats[chatId] = messages;
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

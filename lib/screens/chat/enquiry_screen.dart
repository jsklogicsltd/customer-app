import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/verified_badge.dart';

class EnquiryScreen extends StatefulWidget {
  final String vendorId;
  final String? productId;
  const EnquiryScreen({super.key, required this.vendorId, this.productId});

  @override
  State<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends State<EnquiryScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = 'chat_cust001_${widget.vendorId}';
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(_chatId, text);
    _messageCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.read<VendorProvider>().getById(widget.vendorId);
    final product = widget.productId != null ? context.read<ProductProvider>().getById(widget.productId!) : null;
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.getMessages(_chatId);
    final isTyping = chatProvider.isVendorTyping(_chatId);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(vendor?.avatar ?? 'https://i.pravatar.cc/150?img=5'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(vendor?.name ?? 'Vendor', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    if (vendor?.verified ?? false) const VerifiedBadge(small: true),
                  ]),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.statusActive, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Online', style: AppTypography.caption.copyWith(color: AppColors.statusActive)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product reference (if coming from product detail)
          if (product != null)
            Container(
              color: AppColors.primaryGreen.withAlpha(10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppCachedImage(url: product.images.first, width: 44, height: 44),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enquiry about:', style: AppTypography.caption.copyWith(color: AppColors.textMedium)),
                        Text(product.title, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                  return _TypingIndicator();
                }
                final msg = messages[index];
                return _ChatBubble(
                  text: msg.text,
                  isMe: msg.isMe,
                  timestamp: msg.timestamp,
                );
              },
            ),
          ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.textMedium),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text, timestamp;
  final bool isMe;
  const _ChatBubble({required this.text, required this.isMe, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: AppTypography.body.copyWith(color: isMe ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 4),
            Text(timestamp, style: AppTypography.caption.copyWith(color: isMe ? Colors.white60 : AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)],
        ),
        child: Text('Vendor is typing...', style: AppTypography.small.copyWith(color: AppColors.textMedium, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

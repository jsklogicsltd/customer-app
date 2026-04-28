import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String threadId;

  // Product context (Optional)
  final String? chatType;
  final String? productId;
  final String? productName;
  final String? vendorId;
  final String? vendorName;

  const ChatDetailScreen({
    super.key,
    this.orderId = '',
    this.orderNumber = '',
    required this.threadId,
    this.chatType,
    this.productId,
    this.productName,
    this.vendorId,
    this.vendorName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Start listener immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.getMessages(widget.threadId);
      // Mark messages as read
      chatProvider.markThreadRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send ─────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final userProvider = context.read<UserProvider>();
    final chatProvider = context.read<ChatProvider>();

    _messageCtrl.clear();
    setState(() => _isSending = true);

    if (widget.chatType == 'product' && widget.productId != null) {
      await chatProvider.sendProductMessage(
        productId: widget.productId!,
        productName: widget.productName ?? 'Product',
        vendorId: widget.vendorId ?? '',
        vendorName: widget.vendorName ?? 'Vendor',
        text: text,
        customerName: userProvider.user?.name ?? '',
      );
    } else {
      await chatProvider.sendMessage(
        orderId: widget.orderId,
        text: text,
        customerName: userProvider.user?.name ?? '',
        threadId: widget.threadId,
      );
    }

    setState(() => _isSending = false);

    // Scroll to bottom after optimistic insert
    _scrollToBottom(delay: 80);
  }

  void _scrollToBottom({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F2F5),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          // ── Messages list ───────────────────────────────────────────────────
          Expanded(child: _buildMessageList(isDark)),
          // ── Input bar ───────────────────────────────────────────────────────
          _buildInputBar(context, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkCard : Colors.white,
      elevation: 1,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Golden K Avatar
          const _KAvatar(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karsaazi Support',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  widget.chatType == 'product'
                      ? 'Re: ${widget.productName}'
                      : 'Order #${widget.orderNumber}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.getMessages(widget.threadId);

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _KAvatar(size: 56),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our support team typically\nreplies within a few hours.',
                  style: AppTypography.small
                      .copyWith(color: AppColors.textMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Auto-scroll when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];

            // Date separator
            final showDateSep = index == 0 ||
                _isDifferentDay(
                  messages[index - 1].sortKey,
                  msg.sortKey,
                );

            return Column(
              children: [
                if (showDateSep && msg.sortKey > 0)
                  _DateSeparator(sortKey: msg.sortKey),
                _ChatBubble(
                  text: msg.text,
                  isMe: msg.isMe,
                  timestamp: msg.timestamp,
                  isPending: msg.isPending,
                  senderLabel: msg.isMe ? null : msg.displayAsName,
                  isDark: isDark,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCard : Colors.white,
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Message Karsaazi Support...',
                filled: true,
                fillColor:
                    isDark ? AppColors.darkBg : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.textLight),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentDay(int prevMs, int currMs) {
    if (prevMs == 0 || currMs == 0) return false;
    final prev = DateTime.fromMillisecondsSinceEpoch(prevMs).toLocal();
    final curr = DateTime.fromMillisecondsSinceEpoch(currMs).toLocal();
    return prev.day != curr.day ||
        prev.month != curr.month ||
        prev.year != curr.year;
  }
}

// ---------------------------------------------------------------------------
// Golden "K" Avatar
// ---------------------------------------------------------------------------

class _KAvatar extends StatelessWidget {
  final double size;
  const _KAvatar({this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'K',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.44,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Bubble
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  final String text;
  final String timestamp;
  final bool isMe;
  final bool isPending;
  final String? senderLabel;   // shown for admin messages
  final bool isDark;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isPending = false,
    this.senderLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const goldBubble = Color(0xFFF9A825);
    final adminBgColor =
        isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final adminTextColor =
        isDark ? Colors.white : AppColors.textDark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender label for admin replies
            if (!isMe && senderLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  senderLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? goldBubble : adminBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: AppTypography.body.copyWith(
                      color: isMe ? Colors.white : adminTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: AppTypography.caption.copyWith(
                          color: isMe
                              ? Colors.white60
                              : AppColors.textLight,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isPending
                              ? Icons.access_time_rounded
                              : Icons.done_all_rounded,
                          size: 13,
                          color: isPending
                              ? Colors.white38
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date separator
// ---------------------------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  final int sortKey;
  const _DateSeparator({required this.sortKey});

  String _label() {
    if (sortKey == 0) return '';
    final dt =
        DateTime.fromMillisecondsSinceEpoch(sortKey).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _label();
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? Colors.white12 : AppColors.divider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? Colors.white12 : AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

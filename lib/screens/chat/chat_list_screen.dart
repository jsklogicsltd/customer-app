import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/chat_message.dart';
import '../../providers/user_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate().toLocal();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final customerId = userProvider.user?.id ?? '';

    // Gather all orders that belong to this customer
    final List<OrderModel> allOrders = orderProvider.allOrders;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text('Messages'),
        centerTitle: false,
      ),
      body: allOrders.isEmpty
          ? _EmptyState(isDark: isDark)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allOrders.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 80,
                color: isDark ? Colors.white10 : AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final order = allOrders[index];
                final threadId = ChatMessage.buildOrderThreadId(
                  orderId: order.id,
                  customerId: customerId,
                );
                return _ChatTile(
                  order: order,
                  threadId: threadId,
                  isDark: isDark,
                  formatTimestamp: _formatTimestamp,
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Tile — streams last message from Firestore
// ---------------------------------------------------------------------------

class _ChatTile extends StatelessWidget {
  final OrderModel order;
  final String threadId;
  final bool isDark;
  final String Function(dynamic) formatTimestamp;

  const _ChatTile({
    required this.order,
    required this.threadId,
    required this.isDark,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('threadId', isEqualTo: threadId)
          .where('visibleTo', arrayContains: 'customer')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        String lastMessage = 'Tap to chat with Karsaazi Support';
        dynamic lastTimestamp;
        int unread = 0;

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final data = snap.data!.docs.first.data() as Map<String, dynamic>;
          lastMessage = data['text'] ?? lastMessage;
          lastTimestamp = data['timestamp'];
        }

        // Unread count stream
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('threadId', isEqualTo: threadId)
              .where('visibleTo', arrayContains: 'customer')
              .where('senderType', isEqualTo: 'admin')
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, unreadSnap) {
            if (unreadSnap.hasData) {
              unread = unreadSnap.data!.docs.length;
            }

            return InkWell(
              onTap: () {
                context.push(
                  '/chat/order/${order.id}',
                  extra: {
                    'orderId': order.id,
                    'orderNumber': order.orderNumber.isNotEmpty
                        ? order.orderNumber
                        : order.id,
                    'threadId': threadId,
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // ── Golden "K" Avatar ──────────────────────────────
                    const _KAvatar(),
                    const SizedBox(width: 14),

                    // ── Text Content ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Karsaazi Support',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastTimestamp != null)
                                Text(
                                  formatTimestamp(lastTimestamp),
                                  style: AppTypography.caption.copyWith(
                                    color: unread > 0
                                        ? AppColors.gold
                                        : AppColors.textLight,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              // Order badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage,
                                  style: AppTypography.small.copyWith(
                                    color: unread > 0
                                        ? (isDark
                                            ? Colors.white
                                            : AppColors.textDark)
                                        : AppColors.textMedium,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Golden "K" Avatar — Karsaazi brand logo avatar
// ---------------------------------------------------------------------------

class _KAvatar extends StatelessWidget {
  const _KAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
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
      child: const Center(
        child: Text(
          'K',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'After placing an order, you can chat with\nKarsaazi Support here.',
              style: AppTypography.body.copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

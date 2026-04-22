import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.allNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(
                'Mark all read',
                style: AppTypography.small.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(notification: notif);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        color: notification.isRead ? Colors.white : const Color(0xFFFFF9E6), // Slightly golden for unread
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getRelativeTime(notification.createdAt),
                    style: AppTypography.caption.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'new_message':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.green;
        break;
      case 'new_quote':
        icon = Icons.assignment_outlined;
        color = const Color(0xFFFFD700); // Golden
        break;
      case 'new_order':
        icon = Icons.shopping_bag_outlined;
        color = Colors.blue;
        break;
      case 'quote_accepted':
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFFFFD700); // Golden
        break;
      case 'quote_declined':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      case 'order_update':
        icon = Icons.sync_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = Colors.grey;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _handleTap(BuildContext context) async {
    final provider = context.read<NotificationProvider>();
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    if (context.mounted) {
      switch (notification.type) {
        case 'new_message':
          // Extract orderId from referenceId if it's thread_orderId_customerId
          // or use referenceId as threadId and hope orderId is available.
          // Based on ChatDetailScreen, we NEED orderId and orderNumber.
          // Fallback to chat list if we don't have enough info.
          context.push('/chat');
          break;
        case 'new_quote':
          context.push('/quotes');
          break;
        case 'order_update':
        case 'quote_accepted':
          if (notification.referenceId != null) {
            context.push('/orders/${notification.referenceId}');
          } else {
            context.push('/orders-tab');
          }
          break;
        case 'new_order':
          context.push('/orders-tab');
          break;
        default:
          // Just mark as read
          break;
      }
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}

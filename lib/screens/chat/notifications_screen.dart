import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifs = provider.allNotifications;

    final today = notifs.where((n) => n.timeAgo.contains('hour')).toList();
    final thisWeek = notifs.where((n) => n.timeAgo.contains('day')).toList();
    final earlier = notifs.where((n) => n.timeAgo.contains('month')).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: provider.markAllRead,
            child: Text('Mark All Read', style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: notifs.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView(
              children: [
                if (today.isNotEmpty) ...[
                  const _SectionHeader(title: 'Today'),
                  ...today.map((n) => _NotifCard(notif: n, provider: provider)),
                ],
                if (thisWeek.isNotEmpty) ...[
                  const _SectionHeader(title: 'This Week'),
                  ...thisWeek.map((n) => _NotifCard(notif: n, provider: provider)),
                ],
                if (earlier.isNotEmpty) ...[
                  const _SectionHeader(title: 'Earlier'),
                  ...earlier.map((n) => _NotifCard(notif: n, provider: provider)),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: AppTypography.small.copyWith(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final dynamic notif;
  final NotificationProvider provider;
  const _NotifCard({required this.notif, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.markRead(notif.id);
        // Navigate based on actionRoute
        context.push(notif.actionRoute.startsWith('/') ? notif.actionRoute : '/home');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: notif.read ? Colors.white : AppColors.verifiedBlue.withAlpha(8),
          border: Border(left: BorderSide(
            color: notif.read ? Colors.transparent : AppColors.verifiedBlue,
            width: 3,
          )),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(notif.timeAgo, style: AppTypography.caption),
                ],
              ),
            ),
            if (!notif.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.verifiedBlue, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

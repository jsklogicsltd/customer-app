class AppNotification {
  final String id;
  final String type;
  final String icon;
  final String title;
  final String body;
  final String timeAgo;
  final dynamic timestamp;
  bool read;
  final String actionRoute;

  AppNotification({
    required this.id,
    required this.type,
    required this.icon,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.timestamp,
    required this.read,
    required this.actionRoute,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      type: map['type'] ?? 'info',
      icon: map['icon'] ?? '🔔',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timeAgo: map['timeAgo'] ?? 'Just now',
      timestamp: map['timestamp'] ?? map['createdAt'],
      read: map['read'] ?? false,
      actionRoute: map['actionRoute'] ?? '',
    );
  }
}

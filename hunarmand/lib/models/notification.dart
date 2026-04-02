class AppNotification {
  final String id;
  final String type;
  final String icon;
  final String title;
  final String body;
  final String timeAgo;
  bool read;
  final String actionRoute;

  AppNotification({
    required this.id,
    required this.type,
    required this.icon,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.read,
    required this.actionRoute,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      type: map['type'],
      icon: map['icon'],
      title: map['title'],
      body: map['body'],
      timeAgo: map['timeAgo'],
      read: map['read'],
      actionRoute: map['actionRoute'],
    );
  }
}

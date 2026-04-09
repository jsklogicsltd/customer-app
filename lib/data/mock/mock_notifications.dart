import '../../models/notification.dart';

final List<AppNotification> mockNotificationsData = [
  AppNotification.fromMap({
    'id': 'notif001',
    'type': 'order_delivered',
    'icon': '🎉',
    'title': 'Order #1048 Delivered!',
    'body': 'Your Blue Pottery Tea Set has been delivered. Rate now!',
    'timeAgo': '2 hours ago',
    'read': false,
    'actionRoute': '/orders/ORD-1048',
  }),
  AppNotification.fromMap({
    'id': 'notif002',
    'type': 'order_dispatched',
    'icon': '📦',
    'title': 'Order #1052 Dispatched',
    'body': 'Tracking: TCS12345. Expected: Tomorrow.',
    'timeAgo': '1 day ago',
    'read': false,
    'actionRoute': '/orders/ORD-1052',
  }),
  AppNotification.fromMap({
    'id': 'notif003',
    'type': 'vendor_reply',
    'icon': '✉️',
    'title': 'Vendor Replied',
    'body': 'Fatima Handicrafts sent you a message.',
    'timeAgo': '3 days ago',
    'read': true,
    'actionRoute': '/chat/chat_cust001_v001',
  }),
  AppNotification.fromMap({
    'id': 'notif004',
    'type': 'custom_request_update',
    'icon': '🤖',
    'title': 'Custom Request Update',
    'body': 'Quotes received from 3 vendors for REQ-089. Review now!',
    'timeAgo': '5 days ago',
    'read': true,
    'actionRoute': '/custom-requests/REQ-2026-089',
  }),
];

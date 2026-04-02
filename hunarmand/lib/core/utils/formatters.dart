import 'package:intl/intl.dart';

String formatPKR(int amount) {
  final formatter = NumberFormat('#,##,##0', 'en_IN');
  return 'PKR ${formatter.format(amount)}';
}

String formatPKRFromDouble(double amount) {
  return formatPKR(amount.toInt());
}

String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

String timeAgo(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inMinutes} minutes ago';
    }
  } catch (_) {
    return dateStr;
  }
}

String maskPhone(String phone) {
  if (phone.length < 7) return phone;
  return '${phone.substring(0, 4)} ${phone.substring(4, 6)}X XXX X${phone.substring(phone.length - 3)}';
}

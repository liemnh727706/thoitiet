import 'package:intl/intl.dart';

// Định dạng ngày/giờ tiếng Việt.
String formatHour(DateTime t) => DateFormat('HH:mm').format(t);

String formatDayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Ngày mai';
  const weekdays = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
  return weekdays[d.weekday];
}

String formatUpdated(DateTime t) {
  return 'Cập nhật ${DateFormat('HH:mm').format(t.toLocal())}';
}

String uvLabel(num? uv) {
  if (uv == null) return '--';
  if (uv < 3) return 'Thấp';
  if (uv < 6) return 'Trung bình';
  if (uv < 8) return 'Cao';
  if (uv < 11) return 'Rất cao';
  return 'Cực cao';
}

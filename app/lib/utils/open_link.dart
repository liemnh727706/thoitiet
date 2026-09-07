// Mở link bản tin gốc (NCHMF/JMA) ra trình duyệt ngoài.
// Thử lần lượt 3 chế độ của url_launcher; nếu máy không mở được thì hiện
// SnackBar kèm nút sao chép để người dùng tự dán vào trình duyệt.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSourceLink(BuildContext context, String? url) async {
  final messenger = ScaffoldMessenger.of(context);
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) {
    messenger.showSnackBar(
        const SnackBar(content: Text('Bản tin này không kèm link nguồn.')));
    return;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) {
    messenger.showSnackBar(SnackBar(content: Text('Link không hợp lệ: $raw')));
    return;
  }
  const modes = [
    LaunchMode.externalApplication,
    LaunchMode.inAppBrowserView,
    LaunchMode.platformDefault,
  ];
  for (final mode in modes) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (_) {
      // thử chế độ kế tiếp
    }
  }
  messenger.showSnackBar(SnackBar(
    content: Text('Không mở được trình duyệt. Link: $raw'),
    duration: const Duration(seconds: 10),
    action: SnackBarAction(
      label: 'Sao chép',
      onPressed: () => Clipboard.setData(ClipboardData(text: raw)),
    ),
  ));
}

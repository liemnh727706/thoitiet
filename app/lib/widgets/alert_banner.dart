import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/weather.dart';
import '../theme/weather_gradients.dart';
import '../utils/weather_icons.dart';

// TẦNG 1: Cảnh báo khẩn - luôn hiển thị trên cùng nếu có. Bấm để mở rộng
// xem toàn văn bản tin NCHMF + link nguồn.
class AlertBanner extends StatelessWidget {
  final List<WeatherAlert> alerts;
  const AlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: alerts.map((a) => _AlertTile(alert: a)).toList(),
    );
  }
}

class _AlertTile extends StatefulWidget {
  final WeatherAlert alert;
  const _AlertTile({required this.alert});
  @override
  State<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<_AlertTile> {
  bool _expanded = false;

  Future<void> _openSource() async {
    final url = widget.alert.sourceUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
    if (!ok) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được trình duyệt. Link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final bg = AlertColors.background(alert.severity);
    final fg = AlertColors.foreground(alert.severity);
    final canExpand = alert.fullText.isNotEmpty || (alert.sourceUrl?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(alertIcon(alert.kind), color: fg, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: fg.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(AlertColors.label(alert.severity),
                                style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(alert.title,
                                style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (canExpand)
                            Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: fg, size: 22),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_expanded && alert.fullText.isNotEmpty ? alert.fullText : alert.message,
                          style: TextStyle(color: fg.withValues(alpha: 0.95), fontSize: 13, height: 1.35)),
                      if (alert.official) _officialFooter(fg),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Link nguồn khi mở rộng
          if (_expanded && (alert.sourceUrl?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _openSource,
              child: Row(
                children: [
                  Icon(Icons.open_in_new_rounded, color: fg, size: 15),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('Xem bản tin gốc: ${alert.sourceUrl}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 11.5, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
          if (!_expanded && canExpand)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 42),
              child: Text('Chạm để xem chi tiết ▾',
                  style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _officialFooter(Color fg) {
    final alert = widget.alert;
    final parts = <String>['Nguồn chính thức: NCHMF'];
    if (alert.issuedAt != null) {
      parts.add('phát ${DateFormat('HH:mm dd/MM').format(alert.issuedAt!.toLocal())}');
    }
    if (alert.regions.isNotEmpty) {
      parts.add('ảnh hưởng: ${alert.regionsLabel}');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: fg.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(parts.join(' · '),
                style: TextStyle(color: fg.withValues(alpha: 0.9), fontSize: 11, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

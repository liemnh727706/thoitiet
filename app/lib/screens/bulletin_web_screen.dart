// Xem bản tin gốc (NCHMF/JMA) ngay trong app bằng WebView.
// Một số máy chặn hoặc không mở được trình duyệt ngoài từ app, nên đây là
// đường chắc ăn; vẫn giữ nút mở trình duyệt và sao chép link ở thanh trên.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/open_link.dart';

class BulletinWebScreen extends StatefulWidget {
  final String url;
  final String title;
  const BulletinWebScreen({super.key, required this.url, required this.title});

  @override
  State<BulletinWebScreen> createState() => _BulletinWebScreenState();
}

class _BulletinWebScreenState extends State<BulletinWebScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            if (err.isForMainFrame ?? true) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = false;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Mở bằng trình duyệt',
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => openSourceLink(context, widget.url),
          ),
          IconButton(
            tooltip: 'Sao chép link',
            icon: const Icon(Icons.link),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép link bản tin.')));
            },
          ),
        ],
      ),
      body: _error
          ? _errorView()
          : WebViewWidget(controller: _controller),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Không tải được bản tin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.url,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ]),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../services/api_service.dart';
import '../state/weather_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<PlaceResult> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.searchPlace(q.trim());
      setState(() => _results = r);
    } catch (e) {
      setState(() => _error = 'Không tìm được. Kiểm tra kết nối tới máy chủ.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm địa điểm'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<WeatherProvider>().useCurrentLocation();
            },
            icon: const Icon(Icons.my_location),
            label: const Text('GPS'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Nhập tên tỉnh/thành, quận, huyện...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _results[i];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(p.name),
                  subtitle: Text(p.label),
                  onTap: () async {
                    await context.read<WeatherProvider>().selectPlace(p);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

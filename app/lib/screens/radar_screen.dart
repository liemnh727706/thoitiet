import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/weather.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

// Bản đồ radar mưa (RainViewer) + vị trí/đường đi bão (NCHMF).
class RadarScreen extends StatefulWidget {
  final double? centerLat;
  final double? centerLon;
  const RadarScreen({super.key, this.centerLat, this.centerLon});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final _api = ApiService();
  RadarData? _radar;
  StormInfo? _storm;
  String? _error;
  int _index = 0;
  bool _playing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.getRadar(), _api.getStorm()]);
      setState(() {
        _radar = results[0] as RadarData;
        _storm = results[1] as StormInfo;
        _index = _radar!.frames.isEmpty ? 0 : _radar!.frames.length - 1; // frame mới nhất
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
        if (_radar == null || _radar!.frames.isEmpty) return;
        setState(() => _index = (_index + 1) % _radar!.frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.centerLat ?? 16.2, widget.centerLon ?? 107.8);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ mưa & bão'),
        backgroundColor: const Color(0xFF203A43),
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? _errorView()
          : _radar == null
              ? const Center(child: CircularProgressIndicator())
              : _buildMap(center),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () { setState(() => _error = null); _load(); },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );

  Widget _buildMap(LatLng center) {
    final frames = _radar!.frames;
    final frame = frames.isNotEmpty ? frames[_index] : null;
    final storm = _storm;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 5.2,
            minZoom: 3,
            maxZoom: 12,
          ),
          children: [
            // Nền bản đồ OSM
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vn_weather',
            ),
            // Lớp radar mưa (frame hiện tại)
            if (frame != null)
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate: frame.url,
                  userAgentPackageName: 'com.example.vn_weather',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
              ),
            // Đường đi bão
            if (storm != null && storm.active && storm.track.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: storm.track.map((p) => LatLng(p.lat, p.lon)).toList(),
                    color: Colors.redAccent,
                    strokeWidth: 3,
                  ),
                ],
              ),
            // Marker tâm bão
            if (storm != null && storm.active && storm.center != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(storm.center!.lat, storm.center!.lon),
                    width: 54,
                    height: 54,
                    child: const _StormMarker(),
                  ),
                ],
              ),
          ],
        ),
        // Bảng điều khiển thời gian
        Positioned(left: 0, right: 0, bottom: 0, child: _controlPanel(frame)),
        // Chú thích nguồn
        Positioned(
          top: 6,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white70,
            child: const Text('Radar: RainViewer · Bão: NCHMF',
                style: TextStyle(fontSize: 10, color: Colors.black87)),
          ),
        ),
        if (storm != null && storm.active) _stormBanner(storm),
      ],
    );
  }

  Widget _stormBanner(StormInfo s) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.cyclone_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(s.title ?? 'Bão/ATNĐ',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (s.intensity != null || s.movement != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (s.intensity != null) 'Gió cấp ${s.intensity}',
                    if (s.movement != null) 'hướng ${s.movement}',
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlPanel(RadarFrame? frame) {
    final frames = _radar!.frames;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: frames.isEmpty ? null : _togglePlay,
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white, size: 34),
              ),
              Expanded(
                child: Slider(
                  value: _index.toDouble(),
                  min: 0,
                  max: (frames.length - 1).clamp(0, 9999).toDouble(),
                  divisions: frames.length > 1 ? frames.length - 1 : null,
                  onChanged: frames.length < 2
                      ? null
                      : (v) => setState(() => _index = v.round()),
                ),
              ),
            ],
          ),
          if (frame != null)
            Text(
              '${frame.kind == 'nowcast' ? 'Dự báo' : 'Thực đo'} · ${formatHour(frame.dateTime)} ${_dayTag(frame.dateTime)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _dayTag(DateTime t) {
    final now = DateTime.now();
    if (t.day == now.day) return '';
    return '${t.day}/${t.month}';
  }
}

class _StormMarker extends StatelessWidget {
  const _StormMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Icon(Icons.cyclone_rounded, color: Colors.red, size: 30),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/weather.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

// Bản đồ radar mưa (RainViewer) + đường đi bão dự báo (JMA) & vị trí bão (NCHMF).
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
  List<Storm> _storms = [];
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
      final results = await Future.wait([_api.getRadar(), _api.getStorms()]);
      setState(() {
        _radar = results[0] as RadarData;
        _storms = results[1] as List<Storm>;
        _index = _radar!.frames.isEmpty ? 0 : _radar!.frames.length - 1;
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

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 5.0,
            minZoom: 3,
            maxZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vn_weather',
            ),
            if (frame != null)
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate: frame.url,
                  userAgentPackageName: 'com.example.vn_weather',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
              ),
            // Đường đã đi (xám) của từng cơn
            PolylineLayer(polylines: _pastPolylines()),
            // Đường đi dự báo (đỏ) của từng cơn
            PolylineLayer(polylines: _forecastPolylines()),
            // Marker: tâm hiện tại + các mốc dự báo
            MarkerLayer(markers: _stormMarkers()),
          ],
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _controlPanel(frame)),
        Positioned(
          top: 6,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white70,
            child: const Text('Radar: RainViewer · Bão: JMA/NCHMF',
                style: TextStyle(fontSize: 10, color: Colors.black87)),
          ),
        ),
        if (_storms.isNotEmpty) _stormBanner(),
      ],
    );
  }

  List<Polyline> _pastPolylines() {
    final out = <Polyline>[];
    for (final s in _storms) {
      if (s.past.length > 1) {
        out.add(Polyline(
          points: s.past.map((p) => LatLng(p.lat, p.lon)).toList(),
          color: Colors.white70,
          strokeWidth: 2,
        ));
      }
    }
    return out;
  }

  List<Polyline> _forecastPolylines() {
    final out = <Polyline>[];
    for (final s in _storms) {
      if (s.track.length > 1) {
        out.add(Polyline(
          points: s.track.map((p) => LatLng(p.lat, p.lon)).toList(),
          color: Colors.redAccent,
          strokeWidth: 3,
        ));
      }
    }
    return out;
  }

  List<Marker> _stormMarkers() {
    final markers = <Marker>[];
    for (final s in _storms) {
      for (final p in s.track) {
        final isNow = !p.forecast;
        markers.add(Marker(
          point: LatLng(p.lat, p.lon),
          width: isNow ? 50 : 42,
          height: isNow ? 50 : 42,
          child: isNow
              ? const _StormCenter()
              : _ForecastDot(label: p.advancedHours != null ? '+${p.advancedHours}h' : ''),
        ));
      }
    }
    return markers;
  }

  Widget _stormBanner() {
    return Positioned(
      top: 8,
      left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _storms.take(3).map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(maxWidth: 230),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cyclone_rounded, color: Colors.white, size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(s.label,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    [
                      'Nguồn ${s.source}',
                      if (s.intensity != null) 'gió ${s.intensity}',
                      if (s.movement != null) 'hướng ${s.movement}',
                    ].join(' · '),
                    style: const TextStyle(color: Colors.white, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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

// Tâm bão hiện tại
class _StormCenter extends StatelessWidget {
  const _StormCenter();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Icon(Icons.cyclone_rounded, color: Colors.red, size: 28),
    );
  }
}

// Điểm dự báo trên đường đi (kèm nhãn giờ)
class _ForecastDot extends StatelessWidget {
  final String label;
  const _ForecastDot({required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.redAccent, width: 3),
          ),
        ),
        if (label.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            color: Colors.redAccent,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
          ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/weather.dart';
import '../services/api_service.dart';
import '../data/vn_places.dart';
import '../utils/formatters.dart';

// Bản đồ radar mưa (RainViewer) + đường đi bão (JMA/NCHMF).
// - Base map KHÔNG nhãn (CartoDB) -> bỏ hết tên nước ngoài.
// - Nhãn địa danh tiếng Việt (đảo/quần đảo + thành phố) tự phủ lên.
// - Focus vào vị trí GPS người dùng.
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

  late final bool _hasGps = widget.centerLat != null && widget.centerLon != null;
  late final LatLng _center =
      LatLng(widget.centerLat ?? 16.2, widget.centerLon ?? 107.8);
  // Focus vào GPS nhưng vẫn đủ rộng để thấy vùng mưa xung quanh.
  late double _zoom = _hasGps ? 7.0 : 5.5;

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
              : _buildMap(),
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

  Widget _buildMap() {
    final frames = _radar!.frames;
    final frame = frames.isNotEmpty ? frames[_index] : null;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _zoom,
            minZoom: 3,
            maxZoom: 12, // radar thô, không cần zoom sâu -> tránh lỗi tile
            onPositionChanged: (camera, _) {
              if ((camera.zoom - _zoom).abs() > 0.25) {
                setState(() => _zoom = camera.zoom);
              }
            },
          ),
          children: [
            // Nền KHÔNG nhãn (bỏ tên nước ngoài)
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vn_weather',
              maxNativeZoom: 20,
            ),
            // Radar mưa (frame hiện tại). RainViewer phục vụ mọi zoom nên KHÔNG
            // đặt maxNativeZoom (từng làm radar không hiển thị). Lỗi "zoom not
            // supported" đã xử lý bằng base CartoDB + giới hạn maxZoom=12.
            if (frame != null)
              Opacity(
                opacity: 0.75,
                child: TileLayer(
                  urlTemplate: frame.url,
                  userAgentPackageName: 'com.example.vn_weather',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
              ),
            // Nhãn địa danh tiếng Việt
            MarkerLayer(markers: _placeLabels()),
            // Đường đã đi (xám) + đường dự báo (đỏ) của bão
            PolylineLayer(polylines: _pastPolylines()),
            PolylineLayer(polylines: _forecastPolylines()),
            MarkerLayer(markers: _stormMarkers()),
            // Vị trí GPS người dùng
            if (_hasGps)
              MarkerLayer(markers: [
                Marker(
                  point: _center,
                  width: 26,
                  height: 26,
                  child: const _UserDot(),
                ),
              ]),
          ],
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _controlPanel(frame)),
        Positioned(
          top: 6,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white70,
            child: const Text('Radar: RainViewer · Bão: JMA/NCHMF · Nền: CARTO',
                style: TextStyle(fontSize: 9, color: Colors.black87)),
          ),
        ),
        if (_storms.isNotEmpty) _stormBanner(),
      ],
    );
  }

  List<Marker> _placeLabels() {
    return vnPlaces.where((p) => _zoom >= p.minZoom).map((p) {
      return Marker(
        point: LatLng(p.lat, p.lon),
        width: 140,
        height: 26,
        child: _PlaceLabel(name: p.name, island: p.island),
      );
    }).toList();
  }

  List<Polyline> _pastPolylines() {
    final out = <Polyline>[];
    for (final s in _storms) {
      if (s.past.length > 1) {
        out.add(Polyline(
          points: s.past.map((p) => LatLng(p.lat, p.lon)).toList(),
          color: Colors.blueGrey,
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

// Nhãn địa danh tiếng Việt
class _PlaceLabel extends StatelessWidget {
  final String name;
  final bool island;
  const _PlaceLabel({required this.name, required this.island});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(island ? Icons.terrain_rounded : Icons.circle,
            size: island ? 12 : 7,
            color: island ? const Color(0xFF00695C) : const Color(0xFF1565C0)),
        const SizedBox(width: 2),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                    fontSize: island ? 11 : 10,
                    fontWeight: FontWeight.w600,
                    color: island ? const Color(0xFF004D40) : const Color(0xFF0D47A1))),
          ),
        ),
      ],
    );
  }
}

// Chấm vị trí người dùng
class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
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

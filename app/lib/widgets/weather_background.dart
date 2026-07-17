import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/weather_gradients.dart';

// Nền động theo thời tiết: gradient + hiệu ứng (mưa rơi dày/thưa theo cường độ,
// sao lấp lánh ban đêm trời quang, quầng nắng ban ngày). Vòng lặp liền mạch.
enum _Fx { none, rain, snow, stars, sun }

class WeatherBackground extends StatefulWidget {
  final String icon;
  final bool isDay;
  final num? precipitation;
  final Widget child;
  const WeatherBackground({
    super.key,
    required this.icon,
    required this.isDay,
    required this.child,
    this.precipitation,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late AnimationController _c;
  late _Fx _fx;
  int _intensity = 0;
  List<_P> _parts = [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(WeatherBackground old) {
    super.didUpdateWidget(old);
    if (old.icon != widget.icon || old.isDay != widget.isDay) {
      _c.dispose();
      _setup();
    }
  }

  void _setup() {
    _fx = _fxFor(widget.icon, widget.isDay);
    final dur = switch (_fx) {
      _Fx.rain => const Duration(milliseconds: 1100),
      _Fx.snow => const Duration(seconds: 6),
      _Fx.stars => const Duration(seconds: 3),
      _Fx.sun => const Duration(seconds: 4),
      _Fx.none => const Duration(seconds: 4),
    };
    _c = AnimationController(vsync: this, duration: dur)..repeat();
    _parts = _generate();
  }

  static _Fx _fxFor(String icon, bool isDay) {
    switch (icon) {
      case 'drizzle':
      case 'rain':
      case 'showers':
      case 'heavy_rain':
      case 'thunderstorm':
        return _Fx.rain;
      case 'snow':
      case 'sleet':
        return _Fx.snow;
      case 'clear':
      case 'mostly_clear':
        return isDay ? _Fx.sun : _Fx.stars;
      default:
        return _Fx.none;
    }
  }

  List<_P> _generate() {
    double r(double a, double b) => a + _rng.nextDouble() * (b - a);
    switch (_fx) {
      case _Fx.rain:
        // cường độ theo icon + lượng mưa thực
        _intensity = switch (widget.icon) {
          'drizzle' => 1,
          'rain' || 'showers' => 2,
          'heavy_rain' || 'thunderstorm' => 3,
          _ => 2,
        };
        if ((widget.precipitation ?? 0) >= 6 && _intensity < 3) _intensity++;
        final heavy = _intensity >= 3;
        final count = switch (_intensity) { 1 => 50, 2 => 95, _ => 160 };
        return List.generate(count, (_) {
          return _P(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            a: heavy ? r(0.05, 0.10) : r(0.02, 0.055), // độ dài (theo chiều cao)
            b: heavy ? r(0.35, 0.6) : r(0.18, 0.42), // độ mờ
            c: heavy ? r(4, 12) : r(2, 7), // độ nghiêng (px)
            k: 1 + _rng.nextInt(3), // tốc độ (1..3, liền mạch)
          );
        });
      case _Fx.snow:
        return List.generate(55, (_) {
          return _P(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            a: r(1.2, 3.2), // bán kính
            b: r(6, 16), // biên độ lắc ngang
            c: r(0, 2 * pi), // pha
            k: 1,
          );
        });
      case _Fx.stars:
        return List.generate(70, (_) {
          return _P(
            x: _rng.nextDouble(),
            y: r(0.02, 0.65), // sao ở nửa trên trời
            a: r(0.6, 1.8), // bán kính
            b: r(0.4, 0.95), // độ sáng nền
            c: r(0, 2 * pi), // pha nhấp nháy
            k: 1 + _rng.nextInt(3), // số chu kỳ nhấp nháy (liền mạch)
          );
        });
      case _Fx.sun:
      case _Fx.none:
        return const [];
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = WeatherGradients.forCondition(widget.icon, isDay: widget.isDay);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          if (_fx != _Fx.none)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) => CustomPaint(
                      painter: _WxPainter(_fx, _c.value, _parts, _intensity),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _P {
  final double x, y, a, b, c;
  final int k;
  const _P({required this.x, required this.y, required this.a, required this.b, required this.c, required this.k});
}

class _WxPainter extends CustomPainter {
  final _Fx fx;
  final double t; // 0..1
  final List<_P> parts;
  final int intensity;
  _WxPainter(this.fx, this.t, this.parts, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    switch (fx) {
      case _Fx.rain:
        _rain(canvas, size);
        break;
      case _Fx.snow:
        _snow(canvas, size);
        break;
      case _Fx.stars:
        _stars(canvas, size);
        break;
      case _Fx.sun:
        _sun(canvas, size);
        break;
      case _Fx.none:
        break;
    }
  }

  void _rain(Canvas canvas, Size size) {
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = intensity >= 3 ? 1.8 : (intensity == 2 ? 1.4 : 1.1);
    for (final d in parts) {
      final dy = (d.y + t * d.k) % 1.0;
      final x = d.x * size.width;
      final y = dy * size.height;
      final len = d.a * size.height;
      p.color = Colors.white.withValues(alpha: d.b);
      canvas.drawLine(Offset(x, y), Offset(x + d.c, y + len), p);
    }
  }

  void _snow(Canvas canvas, Size size) {
    final p = Paint();
    for (final f in parts) {
      final dy = (f.y + t) % 1.0;
      final sway = sin(t * 2 * pi * 2 + f.c) * f.b;
      final x = f.x * size.width + sway;
      final y = dy * size.height;
      p.color = Colors.white.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(x, y), f.a, p);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in parts) {
      final tw = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 2 * pi * s.k + s.c));
      p.color = Colors.white.withValues(alpha: (s.b * tw).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.a, p);
    }
  }

  void _sun(Canvas canvas, Size size) {
    final cx = size.width * 0.74;
    final cy = size.height * 0.15;
    final pulse = 1 + 0.05 * sin(t * 2 * pi);
    final r = size.width * 0.55 * pulse;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, glow);
    // lõi nắng
    canvas.drawCircle(Offset(cx, cy), size.width * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_WxPainter old) => old.t != t || old.fx != fx || old.parts != parts;
}

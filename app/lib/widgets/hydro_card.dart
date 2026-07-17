import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';

// Thẻ "Ngập lụt & Xâm nhập mặn" (nguồn Cục Thủy lợi VN).
class HydroCard extends StatelessWidget {
  final Hydro hydro;
  const HydroCard({super.key, required this.hydro});

  @override
  Widget build(BuildContext context) {
    final sal = hydro.salinity;
    final flood = hydro.flood;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('NGẬP LỤT & XÂM NHẬP MẶN',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),

          // Xâm nhập mặn (trạm gần nhất)
          if (sal != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧂', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trạm đo mặn gần nhất: ${sal.name ?? "--"}'
                          '${sal.distanceKm != null ? " (${sal.distanceKm} km)" : ""}',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        sal.salinityGl != null
                            ? 'Độ mặn: ${sal.salinityGl} g/l · ${sal.level}'
                            : 'Chưa có số liệu (ngoài mùa mặn — mùa khô T12–5)',
                        style: TextStyle(
                            color: _salColor(sal.salinityGl),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Ngập úng (theo tỉnh trong vùng)
          if (flood.isNotEmpty) ...[
            if (sal != null) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diện tích ngập (bản tin tuần):',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      ...flood.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text('• ${f.province}: ${f.floodedArea} ha',
                                style: const TextStyle(color: Color(0xFF9DD6FF), fontSize: 12.5)),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Text('Nguồn: ${hydro.source ?? "Cục Thủy lợi VN"}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Color _salColor(num? gl) {
    if (gl == null) return Colors.white70;
    if (gl < 1) return const Color(0xFF9DE29D);
    if (gl < 4) return const Color(0xFFFFE082);
    return const Color(0xFFFF8A80);
  }
}

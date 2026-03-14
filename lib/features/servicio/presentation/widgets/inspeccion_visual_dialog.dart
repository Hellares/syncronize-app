import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import 'siluetas/auto_superior_painter.dart';

class InspeccionVisualDialog extends StatelessWidget {
  final String jsonStr;

  const InspeccionVisualDialog({super.key, required this.jsonStr});

  static Future<void> show(BuildContext context, String jsonStr) {
    return showDialog(
      context: context,
      builder: (_) => InspeccionVisualDialog(jsonStr: jsonStr),
    );
  }

  static const _tiposDano = {
    'RAYON': {'label': 'Rayon', 'color': Colors.orange, 'icon': Icons.gesture},
    'ABOLLADURA': {'label': 'Abolladura', 'color': Colors.red, 'icon': Icons.circle},
    'ROTURA': {'label': 'Rotura', 'color': Colors.purple, 'icon': Icons.broken_image},
    'OXIDO': {'label': 'Oxido', 'color': Colors.brown, 'icon': Icons.water_drop},
    'FALTANTE': {'label': 'Faltante', 'color': Colors.grey, 'icon': Icons.remove_circle},
    'OTRO': {'label': 'Otro', 'color': Colors.blue, 'icon': Icons.flag},
  };

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    List<Map<String, dynamic>> puntos = [];
    String? silueta;

    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
      silueta = data['silueta'] as String?;
      if (data['puntos'] is List) {
        puntos = (data['puntos'] as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
      }
    } catch (_) {}

    final tipoSilueta = parseSilueta(silueta);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.car_crash_outlined, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: AppTitle('Inspeccion visual', fontSize: 14, color: AppColors.blue1),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Imagen con puntos
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = width * 1.6;

                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue1.withValues(alpha: 0.2)),
                  ),
                  child: Stack(
                    children: [
                      // Imagen del vehículo
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            siluetaAssets[tipoSilueta]!,
                            fit: BoxFit.contain,
                            opacity: const AlwaysStoppedAnimation(0.5),
                          ),
                        ),
                      ),
                      // Puntos de daño
                      ...puntos.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        final px = (p['x'] as num).toDouble() * width;
                        final py = (p['y'] as num).toDouble() * height;
                        final tipo = p['tipo'] as String? ?? 'OTRO';
                        final config = _tiposDano[tipo] ?? _tiposDano['OTRO']!;
                        final color = config['color'] as Color;

                        return Positioned(
                          left: px - 14,
                          top: py - 14,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            // Leyenda de puntos
            if (puntos.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: puntos.length,
                  itemBuilder: (context, index) {
                    final p = puntos[index];
                    final tipo = p['tipo'] as String? ?? 'OTRO';
                    final config = _tiposDano[tipo] ?? _tiposDano['OTRO']!;
                    final color = config['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withValues(alpha: 0.4)),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(config['icon'] as IconData, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            config['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Resumen
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${puntos.length} punto${puntos.length != 1 ? 's' : ''} de dano registrado${puntos.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

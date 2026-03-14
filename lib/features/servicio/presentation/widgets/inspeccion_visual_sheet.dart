import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import 'siluetas/auto_superior_painter.dart';

class InspeccionVisualSheet extends StatefulWidget {
  final String? initialValue;
  final String? silueta;

  const InspeccionVisualSheet({super.key, this.initialValue, this.silueta});

  static Future<String?> show(BuildContext context, {String? initialValue, String? silueta}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InspeccionVisualSheet(initialValue: initialValue, silueta: silueta),
    );
  }

  @override
  State<InspeccionVisualSheet> createState() => _InspeccionVisualSheetState();
}

class _InspeccionVisualSheetState extends State<InspeccionVisualSheet> {
  List<Map<String, dynamic>> _puntos = [];
  late TipoSilueta _tipoSilueta;
  String _tipoDanoSeleccionado = 'RAYON';

  static const _tiposDano = {
    'RAYON': {'label': 'Rayon', 'color': Colors.orange, 'icon': Icons.gesture},
    'ABOLLADURA': {'label': 'Abolladura', 'color': Colors.red, 'icon': Icons.circle},
    'ROTURA': {'label': 'Rotura', 'color': Colors.purple, 'icon': Icons.broken_image},
    'OXIDO': {'label': 'Oxido', 'color': Colors.brown, 'icon': Icons.water_drop},
    'FALTANTE': {'label': 'Faltante', 'color': Colors.grey, 'icon': Icons.remove_circle},
    'OTRO': {'label': 'Otro', 'color': Colors.blue, 'icon': Icons.flag},
  };

  @override
  void initState() {
    super.initState();
    _tipoSilueta = parseSilueta(widget.silueta);

    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        final data = jsonDecode(widget.initialValue!);
        if (data is Map && data['puntos'] is List) {
          _puntos = (data['puntos'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
        }
      } catch (_) {}
    }
  }

  bool get _hasPuntos => _puntos.isNotEmpty;

  void _addPunto(TapUpDetails details, BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxWidth * 1.6);
    final x = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (details.localPosition.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _puntos.add({
        'x': double.parse(x.toStringAsFixed(3)),
        'y': double.parse(y.toStringAsFixed(3)),
        'tipo': _tipoDanoSeleccionado,
      });
    });
  }

  void _removePunto(int index) {
    setState(() => _puntos.removeAt(index));
  }

  String _buildJsonResult() {
    return jsonEncode({
      'silueta': siluetaToString(_tipoSilueta),
      'puntos': _puntos,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppTitle('Inspeccion visual', fontSize: 15, color: AppColors.blue1),
                        AppLabelText(
                          'Toque sobre la imagen para marcar danos',
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                  if (_hasPuntos)
                    InkWell(
                      onTap: () => setState(() => _puntos.clear()),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 13, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text('Limpiar',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 12),

              // Selector tipo de daño
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _tiposDano.entries.map((entry) {
                    final selected = _tipoDanoSeleccionado == entry.key;
                    final config = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _tipoDanoSeleccionado = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? (config['color'] as Color).withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? (config['color'] as Color) : Colors.grey.shade300,
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(config['icon'] as IconData, size: 14,
                                  color: selected ? config['color'] as Color : Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                config['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? config['color'] as Color : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Canvas con imagen del vehículo
              GradientContainer(
                gradient: AppGradients.blueWhiteBlue(),
                shadowStyle: ShadowStyle.none,
                borderColor: _hasPuntos ? AppColors.blue1 : AppColors.blueborder,
                borderWidth: _hasPuntos ? 1.0 : 0.6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = constraints.maxWidth;
                    final canvasHeight = canvasWidth * 1.6;

                    return GestureDetector(
                      onTapUp: (d) => _addPunto(d, constraints),
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: Stack(
                          children: [
                            // Imagen de fondo
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  siluetaAssets[_tipoSilueta]!,
                                  fit: BoxFit.contain,
                                  opacity: const AlwaysStoppedAnimation(0.4),
                                ),
                              ),
                            ),
                            // Puntos de daño
                            ..._puntos.asMap().entries.map((entry) {
                              final i = entry.key;
                              final p = entry.value;
                              final px = (p['x'] as num).toDouble() * canvasWidth;
                              final py = (p['y'] as num).toDouble() * canvasHeight;
                              final tipo = p['tipo'] as String? ?? 'OTRO';
                              final config = _tiposDano[tipo] ?? _tiposDano['OTRO']!;
                              final color = config['color'] as Color;

                              return Positioned(
                                left: px - 12,
                                top: py - 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 10,
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
                      ),
                    );
                  },
                ),
              ),

              // Lista de puntos marcados
              if (_hasPuntos) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _puntos.length,
                    itemBuilder: (context, index) {
                      final p = _puntos[index];
                      final tipo = p['tipo'] as String? ?? 'OTRO';
                      final config = _tiposDano[tipo] ?? _tiposDano['OTRO']!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: (config['color'] as Color).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${index + 1}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: config['color'] as Color)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(config['icon'] as IconData, size: 12, color: config['color'] as Color),
                            const SizedBox(width: 4),
                            Text(config['label'] as String,
                              style: TextStyle(fontSize: 11, color: config['color'] as Color, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            InkWell(
                              onTap: () => _removePunto(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Cancelar',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      backgroundColor: AppColors.blue1,
                      text: 'Guardar inspeccion',
                      icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                      onPressed: () => Navigator.pop(context, _buildJsonResult()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

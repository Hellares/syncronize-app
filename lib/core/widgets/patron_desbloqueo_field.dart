import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PatronDesbloqueoField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final bool required;

  const PatronDesbloqueoField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.required = false,
  });

  @override
  State<PatronDesbloqueoField> createState() => _PatronDesbloqueoFieldState();
}

class _PatronDesbloqueoFieldState extends State<PatronDesbloqueoField> {
  List<int> _patron = [];
  Offset? _currentPos; // posición local dentro del widget

  static const double _gridSize = 220;
  static const double _nodeRadius = 20;
  static const double _hitRadius = 32; // radio de detección más generoso

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _patron = widget.initialValue!
          .split('-')
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n >= 0 && n <= 8)
          .cast<int>()
          .toList();
    }
  }

  // Centro de cada nodo en coordenadas locales del widget
  Offset _nodeCenter(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final spacing = _gridSize / 3;
    return Offset(
      spacing * col + spacing / 2,
      spacing * row + spacing / 2,
    );
  }

  int? _getNodeAt(Offset localPos) {
    for (int i = 0; i < 9; i++) {
      final center = _nodeCenter(i);
      if ((localPos - center).distance <= _hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _clear() {
    setState(() {
      _patron = [];
      _currentPos = null;
    });
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              const Icon(Icons.pattern, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              Text(
                '${widget.label}${widget.required ? " *" : ""}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
              const Spacer(),
              if (_patron.isNotEmpty)
                InkWell(
                  onTap: _clear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Limpiar',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Grid de patrón
          Center(
            child: Container(
              width: _gridSize,
              height: _gridSize,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _patron.isNotEmpty
                      ? AppColors.blue1.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: GestureDetector(
                onPanStart: (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  // No podemos usar box directamente porque el GestureDetector
                  // está dentro del Container. Necesitamos calcular relativo al Container.
                  setState(() {
                    _patron = [];
                    _currentPos = null;
                  });
                },
                onPanUpdate: (d) {
                  setState(() => _currentPos = d.localPosition);
                  final node = _getNodeAt(d.localPosition);
                  if (node != null && !_patron.contains(node)) {
                    setState(() => _patron.add(node));
                  }
                },
                onPanEnd: (_) {
                  setState(() => _currentPos = null);
                  if (_patron.isNotEmpty) {
                    widget.onChanged(_patron.join('-'));
                  }
                },
                child: CustomPaint(
                  painter: _PatronPainter(
                    patron: _patron,
                    currentPos: _currentPos,
                    nodeRadius: _nodeRadius,
                    gridSize: _gridSize,
                    lineColor: AppColors.blue1,
                  ),
                  size: const Size(_gridSize, _gridSize),
                ),
              ),
            ),
          ),

          // Resultado
          if (_patron.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Patron: ${_patron.map((n) => n + 1).join(" → ")}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatronPainter extends CustomPainter {
  final List<int> patron;
  final Offset? currentPos;
  final double nodeRadius;
  final double gridSize;
  final Color lineColor;

  _PatronPainter({
    required this.patron,
    this.currentPos,
    required this.nodeRadius,
    required this.gridSize,
    required this.lineColor,
  });

  Offset _nodeCenter(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final spacing = gridSize / 3;
    return Offset(
      spacing * col + spacing / 2,
      spacing * row + spacing / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar líneas entre nodos conectados
    if (patron.length >= 2) {
      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.4)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(_nodeCenter(patron[0]).dx, _nodeCenter(patron[0]).dy);
      for (int i = 1; i < patron.length; i++) {
        final center = _nodeCenter(patron[i]);
        path.lineTo(center.dx, center.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Línea desde último nodo al dedo
    if (currentPos != null && patron.isNotEmpty) {
      final lastCenter = _nodeCenter(patron.last);
      final dragPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.2)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(lastCenter, currentPos!, dragPaint);
    }

    // Dibujar nodos
    for (int i = 0; i < 9; i++) {
      final center = _nodeCenter(i);
      final isSelected = patron.contains(i);
      final order = isSelected ? patron.indexOf(i) + 1 : 0;

      if (isSelected) {
        // Glow
        final glowPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, nodeRadius + 4, glowPaint);

        // Círculo seleccionado
        final fillPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, nodeRadius, fillPaint);

        final borderPaint = Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, nodeRadius, borderPaint);

        // Número de orden
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$order',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: lineColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2,
          ),
        );
      } else {
        // Círculo no seleccionado
        final fillPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, nodeRadius, fillPaint);

        final borderPaint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, nodeRadius, borderPaint);

        // Punto central
        final dotPaint = Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatronPainter oldDelegate) {
    return oldDelegate.patron != patron || oldDelegate.currentPos != currentPos;
  }
}

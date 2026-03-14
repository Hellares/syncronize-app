import 'package:flutter/material.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';

class PatronDesbloqueoSheet extends StatefulWidget {
  final String? initialValue;

  const PatronDesbloqueoSheet({super.key, this.initialValue});

  /// Muestra el bottom sheet y retorna el patrón como "0-1-2-4-7" o null si cancela
  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PatronDesbloqueoSheet(initialValue: initialValue),
    );
  }

  @override
  State<PatronDesbloqueoSheet> createState() => _PatronDesbloqueoSheetState();
}

class _PatronDesbloqueoSheetState extends State<PatronDesbloqueoSheet> {
  List<int> _patron = [];
  Offset? _currentPos;

  static const double _gridSize = 260;
  static const double _nodeRadius = 24;
  static const double _hitRadius = 36;

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

  bool get _hasPatron => _patron.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
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
                  child: const Icon(Icons.pattern, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTitle('Patron de desbloqueo', fontSize: 15, color: AppColors.blue1),
                      AppLabelText(
                        'Dibuje el patron en la grilla',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                if (_hasPatron)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _patron = [];
                        _currentPos = null;
                      });
                    },
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
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
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
            const SizedBox(height: 16),

            // Grid de patrón
            GradientContainer(
              gradient: AppGradients.blueWhiteBlue(),
              shadowStyle: ShadowStyle.none,
              borderColor: _hasPatron ? AppColors.blue1 : AppColors.blueborder,
              borderWidth: _hasPatron ? 1.0 : 0.6,
              child: Center(
                child: SizedBox(
                  width: _gridSize,
                  height: _gridSize,
                  child: GestureDetector(
                    onPanStart: (d) {
                      setState(() {
                        _patron = [];
                        _currentPos = d.localPosition;
                      });
                      final node = _getNodeAt(d.localPosition);
                      if (node != null) {
                        setState(() => _patron.add(node));
                      }
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
                    },
                    child: CustomPaint(
                      painter: _PatronGridPainter(
                        patron: _patron,
                        currentPos: _currentPos,
                        nodeRadius: _nodeRadius,
                        gridSize: _gridSize,
                        lineColor: AppColors.blue1,
                      ),
                      size: Size(_gridSize, _gridSize),
                    ),
                  ),
                ),
              ),
            ),

            if (!_hasPatron) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Toque y arrastre para dibujar el patron',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ],
              ),
            ],

            if (_hasPatron) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Patron: ${_patron.map((n) => n + 1).join(" → ")}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

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
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                          ),
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
                    text: 'Guardar patron',
                    icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                    onPressed: _hasPatron
                        ? () => Navigator.pop(context, _patron.join('-'))
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatronGridPainter extends CustomPainter {
  final List<int> patron;
  final Offset? currentPos;
  final double nodeRadius;
  final double gridSize;
  final Color lineColor;

  _PatronGridPainter({
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
    // Líneas entre nodos
    if (patron.length >= 2) {
      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.4)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(_nodeCenter(patron[0]).dx, _nodeCenter(patron[0]).dy);
      for (int i = 1; i < patron.length; i++) {
        path.lineTo(_nodeCenter(patron[i]).dx, _nodeCenter(patron[i]).dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Línea al dedo
    if (currentPos != null && patron.isNotEmpty) {
      final lastCenter = _nodeCenter(patron.last);
      final dragPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.2)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(lastCenter, currentPos!, dragPaint);
    }

    // Nodos
    for (int i = 0; i < 9; i++) {
      final center = _nodeCenter(i);
      final isSelected = patron.contains(i);
      final order = isSelected ? patron.indexOf(i) + 1 : 0;

      if (isSelected) {
        // Glow
        canvas.drawCircle(
          center,
          nodeRadius + 5,
          Paint()..color = lineColor.withValues(alpha: 0.1),
        );
        // Fill
        canvas.drawCircle(
          center,
          nodeRadius,
          Paint()..color = lineColor.withValues(alpha: 0.15),
        );
        // Border
        canvas.drawCircle(
          center,
          nodeRadius,
          Paint()
            ..color = lineColor
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
        // Order number
        final tp = TextPainter(
          text: TextSpan(
            text: '$order',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: lineColor),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
      } else {
        // White fill
        canvas.drawCircle(center, nodeRadius, Paint()..color = Colors.white);
        // Border
        canvas.drawCircle(
          center,
          nodeRadius,
          Paint()
            ..color = Colors.grey.shade400
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
        // Center dot
        canvas.drawCircle(center, 4, Paint()..color = Colors.grey.shade400);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatronGridPainter oldDelegate) {
    return oldDelegate.patron != patron || oldDelegate.currentPos != currentPos;
  }
}

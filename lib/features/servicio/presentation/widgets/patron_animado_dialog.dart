import 'package:flutter/material.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';

class PatronAnimadoDialog extends StatefulWidget {
  final List<int> patron;

  const PatronAnimadoDialog({super.key, required this.patron});

  static Future<void> show(BuildContext context, String patronStr) {
    final nodos = patronStr
        .split('-')
        .map((s) => int.tryParse(s))
        .where((n) => n != null && n >= 0 && n <= 8)
        .cast<int>()
        .toList();

    return showDialog(
      context: context,
      builder: (_) => PatronAnimadoDialog(patron: nodos),
    );
  }

  @override
  State<PatronAnimadoDialog> createState() => _PatronAnimadoDialogState();
}

class _PatronAnimadoDialogState extends State<PatronAnimadoDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final duration = Duration(milliseconds: 400 * widget.patron.length);
    _controller = AnimationController(vsync: this, duration: duration);
    _animation = Tween<double>(begin: 0, end: widget.patron.length.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: const Icon(Icons.pattern, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: AppTitle('Patron de desbloqueo', fontSize: 14, color: AppColors.blue1),
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
            const SizedBox(height: 20),

            // Animated grid
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.blue1.withValues(alpha: 0.2)),
              ),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PatronAnimadoPainter(
                      patron: widget.patron,
                      progress: _animation.value,
                      color: AppColors.blue1,
                    ),
                    size: const Size(240, 240),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Info + replay
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Patron de ${widget.patron.length} puntos',
                    style: const TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _replay,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.replay, size: 18, color: AppColors.blue1),
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

class _PatronAnimadoPainter extends CustomPainter {
  final List<int> patron;
  final double progress; // 0.0 to patron.length
  final Color color;

  static const double _gridSize = 240;
  static const double _nodeRadius = 20;

  _PatronAnimadoPainter({
    required this.patron,
    required this.progress,
    required this.color,
  });

  Offset _nodeCenter(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final spacing = _gridSize / 3;
    return Offset(spacing * col + spacing / 2, spacing * row + spacing / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final completedNodes = progress.floor();
    final fraction = progress - completedNodes;

    // Draw lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < completedNodes - 1 && i < patron.length - 1; i++) {
      canvas.drawLine(_nodeCenter(patron[i]), _nodeCenter(patron[i + 1]), linePaint);
    }

    // Animated line segment (from last completed to next)
    if (completedNodes > 0 && completedNodes <= patron.length - 1) {
      final from = _nodeCenter(patron[completedNodes - 1]);
      final to = _nodeCenter(patron[completedNodes]);
      final current = Offset.lerp(from, to, fraction)!;

      final animLinePaint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, current, animLinePaint);

      // Moving dot
      canvas.drawCircle(
        current,
        7,
        Paint()..color = color.withValues(alpha: 0.3),
      );
      canvas.drawCircle(current, 4, Paint()..color = color);
    }

    // Draw all 9 nodes
    for (int i = 0; i < 9; i++) {
      final center = _nodeCenter(i);
      final nodeIndex = patron.indexOf(i);
      final isRevealed = nodeIndex != -1 && nodeIndex < completedNodes;
      final isAnimating = nodeIndex != -1 && nodeIndex == completedNodes && fraction > 0.5;

      if (isRevealed || isAnimating) {
        // Glow
        canvas.drawCircle(center, _nodeRadius + 4, Paint()..color = color.withValues(alpha: 0.1));
        // Fill
        canvas.drawCircle(center, _nodeRadius, Paint()..color = color.withValues(alpha: 0.15));
        // Border
        canvas.drawCircle(
          center, _nodeRadius,
          Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke,
        );
        // Number
        final order = nodeIndex + 1;
        final tp = TextPainter(
          text: TextSpan(
            text: '$order',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
      } else {
        // Inactive node
        canvas.drawCircle(center, _nodeRadius, Paint()..color = Colors.white);
        canvas.drawCircle(
          center, _nodeRadius,
          Paint()..color = Colors.grey.shade300..strokeWidth = 1.5..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(center, 4, Paint()..color = Colors.grey.shade300);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatronAnimadoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// class AnimatedNeonBorder extends StatefulWidget {
//   final Widget child;
//   final double borderRadius;
//   final double borderWidth;
//   final double glowSigma;
//   final bool enableGlow;
//   final List<Color> colors;
//   final Duration duration;
//   final EdgeInsets padding;
//   final bool enableHighlight;
// final double highlightWidth; // 0..1 (ancho de la franja)
// final double highlightOpacity; // 0..1

//   const AnimatedNeonBorder({
//     super.key,
//     required this.child,
//     required this.colors,
//     this.borderRadius = 16,
//     this.borderWidth = 0.6,         // mejor default para cards
//     this.glowSigma = 2.0,         // glow suave
//     this.enableGlow = false,      // en dialogs normalmente mejor apagado
//     this.duration = const Duration(seconds: 4),
//     this.padding = const EdgeInsets.all(1),
//     this.enableHighlight = true,
//   this.highlightWidth = 0.12,
//   this.highlightOpacity = 0.9,
//   });

//   @override
//   State<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
// }

// class _AnimatedNeonBorderState extends State<AnimatedNeonBorder>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: widget.duration)
//       ..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RepaintBoundary(
//       child: AnimatedBuilder(
//         animation: _controller,
//         builder: (_, __) {
//           return CustomPaint(
//             painter: _NeonBorderPainter(
//               progress: _controller.value,
//               colors: widget.colors,
//               borderRadius: widget.borderRadius,
//               borderWidth: widget.borderWidth,
//               glowSigma: widget.glowSigma,
//               enableGlow: widget.enableGlow,
//               enableHighlight: widget.enableHighlight,
//   highlightWidth: widget.highlightWidth,
//   highlightOpacity: widget.highlightOpacity,
//             ),
//             child: Padding(
//               padding: widget.padding,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(widget.borderRadius),
//                 child: widget.child,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _NeonBorderPainter extends CustomPainter {
//   final double progress;
//   final List<Color> colors;
//   final double borderRadius;
//   final double borderWidth;
//   final double glowSigma;
//   final bool enableGlow;

//   final bool enableHighlight;
//   final double highlightWidth;    // 0..1
//   final double highlightOpacity;  // 0..1

//   _NeonBorderPainter({
//     required this.progress,
//     required this.colors,
//     required this.borderRadius,
//     required this.borderWidth,
//     required this.glowSigma,
//     required this.enableGlow,
//     required this.enableHighlight,
//     required this.highlightWidth,
//     required this.highlightOpacity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rect = Offset.zero & size;

//     final baseShader = SweepGradient(
//       colors: colors,
//       stops: List.generate(colors.length, (i) => i / colors.length),
//       transform: GradientRotation(progress * 2 * 3.1415926535),
//     ).createShader(rect);

//     final rrect = RRect.fromRectAndRadius(
//       rect.deflate(borderWidth / 2),
//       Radius.circular(borderRadius),
//     );

//     // 1) Glow (opcional)
//     if (enableGlow) {
//       final glowPaint = Paint()
//         ..shader = baseShader
//         ..isAntiAlias = true
//         ..style = PaintingStyle.stroke
//         ..strokeJoin = StrokeJoin.round
//         ..strokeCap = StrokeCap.round
//         ..strokeWidth = borderWidth
//         ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSigma);

//       canvas.drawRRect(rrect, glowPaint);
//     }

//     // 2) Borde base nítido
//     final crispPaint = Paint()
//       ..shader = baseShader
//       ..isAntiAlias = true
//       ..style = PaintingStyle.stroke
//       ..strokeJoin = StrokeJoin.round
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = borderWidth;

//     canvas.drawRRect(rrect, crispPaint);

//     // 3) Highlight (franja brillante que viaja)
//     if (enableHighlight) {
//       final w = highlightWidth.clamp(0.02, 0.35);
//       final o = highlightOpacity.clamp(0.0, 1.0);

//       // Creamos un sweep gradient casi transparente con un pico brillante
//       // centrado en 0.0, y lo rotamos con progress.
//       final highlightShader = SweepGradient(
//         colors: [
//           Colors.transparent,
//           Colors.transparent,
//           Colors.white.withValues(alpha: o),
//           Colors.transparent,
//           Colors.transparent,
//         ],
//         stops: [
//           0.0,
//           (1.0 - w) / 2,
//           0.5,
//           (1.0 + w) / 2,
//           1.0,
//         ],
//         transform: GradientRotation(progress * 2 * 3.1415926535),
//       ).createShader(rect);

//       final highlightPaint = Paint()
//         ..shader = highlightShader
//         ..isAntiAlias = true
//         ..style = PaintingStyle.stroke
//         ..strokeJoin = StrokeJoin.round
//         ..strokeCap = StrokeCap.round
//         ..strokeWidth = borderWidth;

//       // Modo de mezcla para que "ilumine" el borde base sin ensuciar
//       highlightPaint.blendMode = BlendMode.screen;

//       canvas.drawRRect(rrect, highlightPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _NeonBorderPainter oldDelegate) {
//     return oldDelegate.progress != progress ||
//         oldDelegate.borderRadius != borderRadius ||
//         oldDelegate.borderWidth != borderWidth ||
//         oldDelegate.glowSigma != glowSigma ||
//         oldDelegate.enableGlow != enableGlow ||
//         oldDelegate.enableHighlight != enableHighlight ||
//         oldDelegate.highlightWidth != highlightWidth ||
//         oldDelegate.highlightOpacity != highlightOpacity ||
//         !listEquals(oldDelegate.colors, colors);
//   }
// }

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class AnimatedNeonBorder extends StatefulWidget {
  final Widget child;

  /// Visual
  final double borderRadius;
  final double borderWidth;
  final double glowSigma;
  final bool enableGlow;
  final List<Color> colors;

  /// Animación
  final Duration duration;

  /// Layout
  final EdgeInsets padding;

  /// Highlight
  final bool enableHighlight;
  final double highlightWidth;
  final double highlightOpacity;
  final Color backgroundColor;

  static const List<Color> _defaultColors = [
    Color(0xFF00E5FF),
    Color(0xFF2979FF),
    Color(0xFF00E676),
  ];

  const AnimatedNeonBorder({
    super.key,
    required this.child,
    this.colors = _defaultColors,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.glowSigma = 2.0,
    this.enableGlow = false,
    this.duration = const Duration(seconds: 4),
    this.padding = const EdgeInsets.all(1),
    this.enableHighlight = true,
    this.highlightWidth = 0.12,
    this.highlightOpacity = 0.9,
    this.backgroundColor = AppColors.blue
  });

  @override
  State<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
}

class _AnimatedNeonBorderState extends State<AnimatedNeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedNeonBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _NeonBorderPainter(
              progress: _controller.value,
              colors: widget.colors,
              borderRadius: widget.borderRadius,
              borderWidth: widget.borderWidth,
              glowSigma: widget.glowSigma,
              enableGlow: widget.enableGlow,
              enableHighlight: widget.enableHighlight,
              highlightWidth: widget.highlightWidth,
              highlightOpacity: widget.highlightOpacity,
            ),
            child: Padding(
              padding: widget.padding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NeonBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;
  final double glowSigma;
  final bool enableGlow;

  final bool enableHighlight;
  final double highlightWidth;
  final double highlightOpacity;

  _NeonBorderPainter({
    required this.progress,
    required this.colors,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowSigma,
    required this.enableGlow,
    required this.enableHighlight,
    required this.highlightWidth,
    required this.highlightOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final angle = progress * 2 * math.pi;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    // ===== Base gradient ROTADO (solo el shader, no el canvas) =====
    final baseShader = SweepGradient(
      colors: colors,
      stops: List.generate(colors.length, (i) => i / colors.length),
      transform: GradientRotation(angle),
    ).createShader(rect);

    // 1️⃣ Glow (opcional)
    if (enableGlow) {
      final glowPaint = Paint()
        ..shader = baseShader
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = borderWidth
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSigma);

      canvas.drawRRect(rrect, glowPaint);
    }

    // 2️⃣ Borde base
    final borderPaint = Paint()
      ..shader = baseShader
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, borderPaint);

    // 3️⃣ Highlight (franja brillante)
    if (enableHighlight) {
      final w = highlightWidth.clamp(0.02, 0.35);
      final o = highlightOpacity.clamp(0.0, 1.0);

      final highlightShader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.white.withValues(alpha: o),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [
          0.0,
          (1.0 - w) / 2,
          0.5,
          (1.0 + w) / 2,
          1.0,
        ],
        transform: GradientRotation(angle),
      ).createShader(rect);

      final highlightPaint = Paint()
        ..shader = highlightShader
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = borderWidth
        ..blendMode = BlendMode.screen;

      canvas.drawRRect(rrect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonBorderPainter old) {
    return old.progress != progress ||
        old.borderRadius != borderRadius ||
        old.borderWidth != borderWidth ||
        old.glowSigma != glowSigma ||
        old.enableGlow != enableGlow ||
        old.enableHighlight != enableHighlight ||
        old.highlightWidth != highlightWidth ||
        old.highlightOpacity != highlightOpacity ||
        !listEquals(old.colors, colors);
  }
}

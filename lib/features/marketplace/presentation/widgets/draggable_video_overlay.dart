import 'package:flutter/material.dart';
import 'producto_video_floating.dart';

/// Capa que posiciona y hace **arrastrable** el mini-player de video sobre el
/// detalle del producto.
///
/// Clave de la fluidez (estilo Temu): durante el arrastre NO se reconstruye el
/// reproductor. La posición vive en un [ValueNotifier] y solo el
/// [ValueListenableBuilder] (un [Stack] con un [Positioned]) se reconstruye por
/// frame; el [VideoPlayer] se construye una sola vez y se pasa como `child`, por
/// lo que conserva su controlador intacto y solo se reposiciona (sin jank).
///
/// Al soltar, se ancla con animación suave al borde lateral más cercano.
class DraggableVideoOverlay extends StatefulWidget {
  final String videoUrl;

  /// Poster (thumbnail) a mostrar mientras el video carga.
  final String? posterUrl;
  final VoidCallback? onClose;

  const DraggableVideoOverlay({
    super.key,
    required this.videoUrl,
    this.posterUrl,
    this.onClose,
  });

  @override
  State<DraggableVideoOverlay> createState() => _DraggableVideoOverlayState();
}

class _DraggableVideoOverlayState extends State<DraggableVideoOverlay>
    with SingleTickerProviderStateMixin {
  static const double _margin = 12;
  static const double _w = ProductoVideoFloating.width;
  static const double _h = ProductoVideoFloating.height;

  /// Posición del PiP (esquina superior-izquierda, en coords del overlay).
  final ValueNotifier<Offset> _pos = ValueNotifier(const Offset(-1, -1));

  /// Animación de "snap" al borde al soltar.
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() {
      final a = _snapAnim;
      if (a != null) _pos.value = a.value;
    });
  Animation<Offset>? _snapAnim;

  // Límites disponibles, recalculados en cada build del LayoutBuilder.
  double _maxX = 0;
  double _maxY = 0;
  bool _didInit = false;

  @override
  void dispose() {
    _snap.dispose();
    _pos.dispose();
    super.dispose();
  }

  void _animateTo(Offset target) {
    _snap.stop();
    _snapAnim = Tween<Offset>(begin: _pos.value, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    _snap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Se construye UNA vez por build del overlay (que ocurre rara vez, no por
    // frame de arrastre) y se pasa como `child` para que no se reconstruya al
    // mover el PiP. Así el VideoPlayer conserva su estado/controlador.
    final video = RepaintBoundary(
      child: ProductoVideoFloating(
        videoUrl: widget.videoUrl,
        posterUrl: widget.posterUrl,
        onClose: widget.onClose,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxX =
            (constraints.maxWidth - _w - _margin).clamp(0.0, double.infinity);
        _maxY =
            (constraints.maxHeight - _h - _margin).clamp(0.0, double.infinity);

        // Posición inicial: pegado a la DERECHA y centrado verticalmente. Se
        // fija una sola vez, en el primer build, antes de que el
        // ValueListenableBuilder se suscriba (sin listeners aún → seguro mutar
        // el notifier aquí). Al arrastrarlo se ancla al borde lateral como siempre.
        if (!_didInit) {
          _didInit = true;
          _pos.value = Offset(
            _maxX,
            ((constraints.maxHeight - _h) / 2).clamp(_margin, _maxY),
          );
        }

        return ValueListenableBuilder<Offset>(
          valueListenable: _pos,
          child: GestureDetector(
            // Cortar cualquier snap en curso al volver a tocar.
            onPanDown: (_) => _snap.stop(),
            onPanUpdate: (d) {
              _pos.value = Offset(
                (_pos.value.dx + d.delta.dx).clamp(_margin, _maxX),
                (_pos.value.dy + d.delta.dy).clamp(_margin, _maxY),
              );
            },
            onPanEnd: (_) {
              final center = _pos.value.dx + _w / 2;
              final snapX =
                  center < constraints.maxWidth / 2 ? _margin : _maxX;
              _animateTo(Offset(snapX, _pos.value.dy));
            },
            child: video,
          ),
          builder: (context, pos, child) {
            // Re-clamp visual por si cambió el espacio (rotación/teclado) sin
            // escribir de vuelta en el notifier durante el build.
            final shown = Offset(
              pos.dx.clamp(_margin, _maxX),
              pos.dy.clamp(_margin, _maxY),
            );
            // Stack + Positioned (con solo left/top) da constraints LOOSE al
            // hijo → el mini conserva su tamaño natural (104×150). El video va
            // por `child`, así que solo se reposiciona, no se reconstruye.
            return Stack(
              children: [
                Positioned(
                  left: shown.dx,
                  top: shown.dy,
                  child: child!,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Animación "vuela al carrito": una miniatura del producto sale del centro de
/// [fromKey] y viaja en arco hasta el centro de [toKey] (el ícono del carrito),
/// encogiéndose en el camino. Resuelve al llegar, para que el caller incremente
/// el badge justo cuando la miniatura "entra" al carrito.
///
/// Origen/destino: por [GlobalKey] (centro del widget) o por [Offset] global
/// explícito ([from]/[to]) como fallback — útil en páginas sin ícono de
/// carrito propio, donde se apunta a la esquina donde suele estar.
///
/// Devuelve false si no pudo correr (widgets desmontados / sin overlay) para
/// que el caller muestre un feedback alternativo.
Future<bool> flyToCart({
  required BuildContext context,
  GlobalKey? fromKey,
  Offset? from,
  GlobalKey? toKey,
  Offset? to,
  String? imageUrl,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final start = _centerOf(fromKey) ?? from;
  final end = _centerOf(toKey) ?? to;
  if (overlay == null || start == null || end == null) return false;

  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingThumb(
      start: start,
      end: end,
      imageUrl: imageUrl,
      onDone: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  await completer.future;
  return true;
}

Offset? _centerOf(GlobalKey? key) {
  final box = key?.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.attached) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

class _FlyingThumb extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String? imageUrl;
  final VoidCallback onDone;

  const _FlyingThumb({
    required this.start,
    required this.end,
    required this.imageUrl,
    required this.onDone,
  });

  @override
  State<_FlyingThumb> createState() => _FlyingThumbState();
}

class _FlyingThumbState extends State<_FlyingThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Punto de control del arco: el punto medio desplazado en perpendicular a la
  /// trayectoria (bow), sin salirse por arriba de la pantalla.
  late final Offset _control;

  @override
  void initState() {
    super.initState();
    final mid = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      (widget.start.dy + widget.end.dy) / 2,
    );
    final delta = widget.end - widget.start;
    final control = mid + Offset(-delta.dy, delta.dx) * 0.18;
    _control = Offset(control.dx, control.dy.clamp(30.0, double.infinity));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInQuad.transform(_controller.value);
          final u = 1 - t;
          // Bézier cuadrática: (1-t)²·start + 2(1-t)t·control + t²·end
          final pos = widget.start * (u * u) +
              _control * (2 * u * t) +
              widget.end * (t * t);
          final size = lerpDouble(54, 20, t)!;
          final opacity = t < 0.85 ? 1.0 : 1.0 - ((t - 0.85) / 0.15) * 0.5;
          return Stack(
            children: [
              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _ThumbFallback(),
                  )
                : const _ThumbFallback(),
          ),
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1565C0),
      alignment: Alignment.center,
      child: const FractionallySizedBox(
        widthFactor: 0.6,
        heightFactor: 0.6,
        child: FittedBox(
          child: Icon(Icons.shopping_bag, color: Colors.white),
        ),
      ),
    );
  }
}

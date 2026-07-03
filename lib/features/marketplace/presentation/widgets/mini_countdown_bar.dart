import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Franja compacta de cuenta regresiva ("EXPIRA EN:" + dígitos en cajitas
/// verdes con número negro, estilo Temu) que se ubica **debajo de la imagen**
/// de la card cuando el producto está en oferta con fecha de fin.
/// Tickea cada segundo; se oculta al terminar.
class MiniCountdownBar extends StatefulWidget {
  final DateTime fin;

  /// Si se provee, muestra un botón "Agregar al carrito" (alto 20px) centrado
  /// debajo del contador, dentro del mismo contenedor oscuro.
  final VoidCallback? onAddToCart;

  const MiniCountdownBar({super.key, required this.fin, this.onAddToCart});

  @override
  State<MiniCountdownBar> createState() => _MiniCountdownBarState();
}

class _MiniCountdownBarState extends State<MiniCountdownBar> {
  Timer? _timer;
  late Duration _restante;

  @override
  void initState() {
    super.initState();
    _restante = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = _calc();
      setState(() => _restante = r);
      if (r == Duration.zero) _timer?.cancel();
    });
  }

  Duration _calc() {
    final d = widget.fin.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Verde de oferta (mismo tono que el banner del detalle).
  static const Color _verde = Color(0xFF16B24A);

  String _dd(int n) => n.toString().padLeft(2, '0');

  /// Cajita verde con el número en negro (estilo Temu).
  Widget _box(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: _verde,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1.0,
          ),
        ),
      );

  Widget get _sep => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.5),
        child: Text(
          ':',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_restante == Duration.zero) return const SizedBox.shrink();
    final dias = _restante.inDays;
    final hh = _restante.inHours % 24;
    final mm = _restante.inMinutes % 60;
    final ss = _restante.inSeconds % 60;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FittedBox evita overflow en cards angostas: escala la fila si no cabe.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'EXPIRA EN:',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                if (dias > 0) ...[
                  _box('${_dd(dias)}d'),
                  _sep,
                ],
                _box(_dd(hh)),
                _sep,
                _box(_dd(mm)),
                _sep,
                _box(_dd(ss)),
              ],
            ),
          ),
          // Botón "Agregar al carrito" (alto 20px) centrado dentro del contenedor.
          if (widget.onAddToCart != null) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap: widget.onAddToCart,
              child: Container(
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // color: _verde,
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Añadir al carrito',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

import 'dart:async';

import 'package:flutter/material.dart';

/// Barra compacta semi-transparente con cuenta regresiva, para overlay al pie de
/// la imagen de la card cuando el producto está en oferta con fecha de fin
/// (estilo Temu). Tickea cada segundo; se oculta al terminar.
class MiniCountdownBar extends StatefulWidget {
  final DateTime fin;

  const MiniCountdownBar({super.key, required this.fin});

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

  String _dd(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_restante == Duration.zero) return const SizedBox.shrink();
    final dias = _restante.inDays;
    final hh = _restante.inHours % 24;
    final mm = _restante.inMinutes % 60;
    final ss = _restante.inSeconds % 60;
    final texto = dias > 0
        ? '${dias}d ${_dd(hh)}:${_dd(mm)}:${_dd(ss)}'
        : '${_dd(hh)}:${_dd(mm)}:${_dd(ss)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: Colors.black.withValues(alpha: 0.45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.access_time_rounded, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

/// Banner de oferta full-width con degradé verde (estilo Temu sobre la paleta de
/// ofertas de la app). Si la oferta tiene fecha de fin [fin], muestra una cuenta
/// regresiva en vivo (días/hrs/min/seg); si no, muestra una versión simple sin
/// reloj. Pensado para mostrarse cuando el producto está en oferta.
class OfertaCountdownBanner extends StatefulWidget {
  /// Fecha de fin de la oferta. Si es null, no hay cuenta regresiva.
  final DateTime? fin;

  /// Sede que ofrece la promoción (para "Oferta válida en [sede]").
  final String? sedeNombre;

  /// Dirección de la sede que ofrece la promoción.
  final String? sedeDireccion;

  const OfertaCountdownBanner({super.key, this.fin, this.sedeNombre, this.sedeDireccion});

  @override
  State<OfertaCountdownBanner> createState() => _OfertaCountdownBannerState();
}

class _OfertaCountdownBannerState extends State<OfertaCountdownBanner> {
  static const Color _verde = Color(0xFF0E8A3C);

  Timer? _timer;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.fin != null) {
      _restante = _calc();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final r = _calc();
        setState(() => _restante = r);
        if (r == Duration.zero) _timer?.cancel(); // se acabó: dejamos de tickear
      });
    }
  }

  Duration _calc() {
    final d = widget.fin!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtFecha(DateTime f) {
    final l = f.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${_meses[l.month - 1]} ${l.year}, $hh:$mm';
  }

  String _dd(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final tieneCountdown = widget.fin != null && _restante > Duration.zero;
    final dias = _restante.inDays;
    final horas = _restante.inHours % 24;
    final mins = _restante.inMinutes % 60;
    final segs = _restante.inSeconds % 60;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_verde, Color(0xFF16B24A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                tieneCountdown ? 'Oferta por tiempo limitado' : 'Oferta especial',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (widget.sedeNombre != null && widget.sedeNombre!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Oferta válida en ${widget.sedeNombre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (widget.sedeDireccion != null && widget.sedeDireccion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 17, top: 1),
                child: Text(
                  widget.sedeDireccion!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
          ],
          if (tieneCountdown) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Termina en', style: TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(width: 10),
                _box(_dd(dias), 'días'),
                const SizedBox(width: 6),
                _box(_dd(horas), 'hrs'),
                const SizedBox(width: 6),
                _box(_dd(mins), 'min'),
                const SizedBox(width: 6),
                _box(_dd(segs), 'seg'),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(Icons.event_outlined, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Válida hasta el ${_fmtFecha(widget.fin!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              '¡Aprovecha el precio rebajado!',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _box(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(color: _verde, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8.5)),
      ],
    );
  }
}

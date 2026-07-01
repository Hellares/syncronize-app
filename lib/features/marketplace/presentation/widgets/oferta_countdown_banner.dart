import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Banner de oferta estilo Temu: **header de color** con el título + la cuenta
/// regresiva adentro (a la derecha), y **body blanco** con la sede de la promo.
/// Si no hay fecha de fin, el header muestra solo "Oferta especial".
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
        if (r == Duration.zero) _timer?.cancel();
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
    final hh = _restante.inHours % 24;
    final mm = _restante.inMinutes % 60;
    final ss = _restante.inSeconds % 60;
    final countdown = '${_dd(dias)}:${_dd(hh)}:${_dd(mm)}:${_dd(ss)}';

    final tieneSede = widget.sedeNombre != null && widget.sedeNombre!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _verde, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header de color con título + countdown ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_verde, Color(0xFF16B24A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    tieneCountdown ? 'Oferta por tiempo limitado' : 'Oferta especial',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                if (tieneCountdown) ...[
                  const SizedBox(width: 8),
                  const Text('Termina en ', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                  Text(
                    countdown,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Body blanco: sede + dirección + validez ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tieneSede) ...[
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: _verde, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Oferta válida en: ${widget.sedeNombre}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.greendark, fontSize: 11, fontWeight: FontWeight.w600),
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
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                      ),
                    ),
                ] else
                  Text('¡Aprovecha el precio rebajado!',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                if (widget.fin != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, color: Colors.grey.shade400, size: 12),
                      const SizedBox(width: 4),
                      Text('Válida hasta el ${_fmtFecha(widget.fin!)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 9.5)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

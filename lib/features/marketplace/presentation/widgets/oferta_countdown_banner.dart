import 'dart:async';

import 'package:flutter/material.dart';

/// Banner de oferta por tiempo limitado con cuenta regresiva en vivo (días /
/// horas / min / seg) hasta [fin]. Full-width con degradé verde, estilo Temu
/// pero con la paleta de ofertas de la app.
class OfertaCountdownBanner extends StatefulWidget {
  final DateTime fin;

  const OfertaCountdownBanner({super.key, required this.fin});

  @override
  State<OfertaCountdownBanner> createState() => _OfertaCountdownBannerState();
}

class _OfertaCountdownBannerState extends State<OfertaCountdownBanner> {
  static const Color _verde = Color(0xFF0E8A3C);

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
      if (r == Duration.zero) _timer?.cancel(); // se acabó: dejamos de tickear
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
    final terminada = _restante == Duration.zero;
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
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Oferta por tiempo limitado',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (terminada)
            const Text(
              'La oferta ha finalizado',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            )
          else
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
                'Válida hasta el ${_fmtFecha(widget.fin)}',
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
            ],
          ),
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

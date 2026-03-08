import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../domain/entities/orden_servicio.dart';
import '../services/cronometro_servicio_calculator.dart';

class CronometroServicioWidget extends StatefulWidget {
  final OrdenServicio orden;
  final List<HistorialOrdenServicio> historial;

  const CronometroServicioWidget({
    super.key,
    required this.orden,
    required this.historial,
  });

  @override
  State<CronometroServicioWidget> createState() =>
      _CronometroServicioWidgetState();
}

class _CronometroServicioWidgetState extends State<CronometroServicioWidget> {
  Timer? _timer;

  bool get _isActive =>
      widget.orden.estado != 'FINALIZADO' &&
      widget.orden.estado != 'CANCELADO';

  @override
  void initState() {
    super.initState();
    if (_isActive) {
      _timer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiempoTotal =
        CronometroServicioCalculator.calcularTiempoTotal(widget.orden);
    final tiemposPorEstado =
        CronometroServicioCalculator.calcularTiempoPorEstado(
            widget.historial, widget.orden.creadoEn);

    final maxDuration = tiemposPorEstado.values.fold<Duration>(
      Duration.zero,
      (a, b) => a > b ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: AppColors.blue1),
            const SizedBox(width: 8),
            const AppSubtitle('CRONOMETRO', fontSize: 12),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _tiempoColor(tiempoTotal).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _tiempoColor(tiempoTotal),
                        ),
                      ),
                    ),
                  Text(
                    CronometroServicioCalculator.formatDuration(tiempoTotal),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _tiempoColor(tiempoTotal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (tiemposPorEstado.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...tiemposPorEstado.entries.map((entry) {
            final proportion = maxDuration.inSeconds > 0
                ? entry.value.inSeconds / maxDuration.inSeconds
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      _estadoLabel(entry.key),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: proportion.clamp(0.02, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        color: _estadoColor(entry.key),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 55,
                    child: Text(
                      CronometroServicioCalculator.formatDuration(
                          entry.value),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Color _tiempoColor(Duration d) {
    if (d.inDays >= 7) return Colors.red;
    if (d.inDays >= 3) return Colors.orange;
    return Colors.green;
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.blue;
      case 'EN_DIAGNOSTICO':
        return Colors.orange;
      case 'ESPERANDO_APROBACION':
        return Colors.amber;
      case 'EN_REPARACION':
        return Colors.indigo;
      case 'PENDIENTE_PIEZAS':
        return Colors.deepOrange;
      case 'REPARADO':
        return Colors.teal;
      case 'LISTO_ENTREGA':
        return Colors.green;
      case 'ENTREGADO':
        return Colors.green.shade700;
      case 'FINALIZADO':
        return Colors.grey;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _estadoLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'Diagnostico',
      'ESPERANDO_APROBACION': 'Aprobacion',
      'EN_REPARACION': 'Reparacion',
      'PENDIENTE_PIEZAS': 'Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }
}

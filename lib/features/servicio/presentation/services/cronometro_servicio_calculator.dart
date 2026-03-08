import '../../domain/entities/orden_servicio.dart';

class CronometroServicioCalculator {
  static Duration calcularTiempoTotal(OrdenServicio orden) {
    final inicio = orden.creadoEn;
    final fin = (orden.estado == 'FINALIZADO' || orden.estado == 'CANCELADO')
        ? orden.actualizadoEn
        : DateTime.now();
    return fin.difference(inicio);
  }

  static Map<String, Duration> calcularTiempoPorEstado(
      List<HistorialOrdenServicio> historial, DateTime creadoEn) {
    final tiempos = <String, Duration>{};

    if (historial.isEmpty) {
      // Sin historial, todo el tiempo es del estado inicial RECIBIDO
      tiempos['RECIBIDO'] = DateTime.now().difference(creadoEn);
      return tiempos;
    }

    // First state starts at creation time
    var prevTime = creadoEn;
    var prevEstado = 'RECIBIDO';

    for (final entry in historial) {
      final duration = entry.creadoEn.difference(prevTime);
      tiempos[prevEstado] =
          (tiempos[prevEstado] ?? Duration.zero) + duration;
      prevEstado = entry.estadoNuevo;
      prevTime = entry.creadoEn;
    }

    // Time in current/last state
    final now = DateTime.now();
    final lastDuration = now.difference(prevTime);
    tiempos[prevEstado] =
        (tiempos[prevEstado] ?? Duration.zero) + lastDuration;

    return tiempos;
  }

  static String formatDuration(Duration d) {
    if (d.inDays > 0) {
      final hours = d.inHours % 24;
      return '${d.inDays}d ${hours}h';
    }
    if (d.inHours > 0) {
      final mins = d.inMinutes % 60;
      return '${d.inHours}h ${mins}m';
    }
    return '${d.inMinutes}m';
  }
}

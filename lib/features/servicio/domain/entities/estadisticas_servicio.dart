import 'package:equatable/equatable.dart';

class EstadisticasServicio extends Equatable {
  final int totalOrdenes;
  final Map<String, int> ordenesPorEstado;
  final Map<String, int> ordenesPorTipo;
  final List<OrdenesMes> ordenesPorMes;
  final int tiempoPromedioResolucion; // hours
  final double ingresoTotal;

  const EstadisticasServicio({
    required this.totalOrdenes,
    required this.ordenesPorEstado,
    required this.ordenesPorTipo,
    required this.ordenesPorMes,
    required this.tiempoPromedioResolucion,
    required this.ingresoTotal,
  });

  int get enProgreso {
    const enProgresoEstados = [
      'RECIBIDO',
      'EN_DIAGNOSTICO',
      'ESPERANDO_APROBACION',
      'EN_REPARACION',
      'PENDIENTE_PIEZAS',
      'REPARADO',
      'LISTO_ENTREGA',
    ];
    return enProgresoEstados.fold<int>(
        0, (sum, e) => sum + (ordenesPorEstado[e] ?? 0));
  }

  int get completadas =>
      (ordenesPorEstado['ENTREGADO'] ?? 0) +
      (ordenesPorEstado['FINALIZADO'] ?? 0);

  @override
  List<Object?> get props => [
        totalOrdenes,
        ordenesPorEstado,
        ordenesPorTipo,
        ordenesPorMes,
        tiempoPromedioResolucion,
        ingresoTotal,
      ];
}

class OrdenesMes extends Equatable {
  final String mes;
  final int cantidad;

  const OrdenesMes({required this.mes, required this.cantidad});

  @override
  List<Object?> get props => [mes, cantidad];
}

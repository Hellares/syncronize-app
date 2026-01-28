import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_incidencia.dart';

abstract class ListarIncidenciasState extends Equatable {
  const ListarIncidenciasState();

  @override
  List<Object?> get props => [];
}

class ListarIncidenciasInitial extends ListarIncidenciasState {
  const ListarIncidenciasInitial();
}

class ListarIncidenciasLoading extends ListarIncidenciasState {
  const ListarIncidenciasLoading();
}

class ListarIncidenciasLoaded extends ListarIncidenciasState {
  final List<TransferenciaIncidencia> incidencias;
  final int totalPendientes;
  final int totalResueltas;

  const ListarIncidenciasLoaded({
    required this.incidencias,
    required this.totalPendientes,
    required this.totalResueltas,
  });

  /// Filtra incidencias pendientes
  List<TransferenciaIncidencia> get pendientes =>
      incidencias.where((i) => i.estaPendiente).toList();

  /// Filtra incidencias resueltas
  List<TransferenciaIncidencia> get resueltas =>
      incidencias.where((i) => i.resuelto).toList();

  /// Incidencias agrupadas por tipo
  Map<TipoIncidenciaTransferencia, List<TransferenciaIncidencia>>
      get agrupadasPorTipo {
    final map = <TipoIncidenciaTransferencia, List<TransferenciaIncidencia>>{};
    for (final incidencia in incidencias) {
      if (!map.containsKey(incidencia.tipo)) {
        map[incidencia.tipo] = [];
      }
      map[incidencia.tipo]!.add(incidencia);
    }
    return map;
  }

  @override
  List<Object?> get props => [incidencias, totalPendientes, totalResueltas];
}

class ListarIncidenciasError extends ListarIncidenciasState {
  final String message;
  final String? errorCode;

  const ListarIncidenciasError(
    this.message, {
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

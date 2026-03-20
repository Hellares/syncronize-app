import 'package:equatable/equatable.dart';
import '../../domain/entities/solicitud_cotizacion.dart';

/// Estados para la lista de solicitudes de cotizacion
abstract class MisSolicitudesState extends Equatable {
  const MisSolicitudesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MisSolicitudesInitial extends MisSolicitudesState {
  const MisSolicitudesInitial();
}

/// Estado de carga
class MisSolicitudesLoading extends MisSolicitudesState {
  const MisSolicitudesLoading();
}

/// Estado con datos cargados
class MisSolicitudesLoaded extends MisSolicitudesState {
  final List<SolicitudCotizacion> solicitudes;
  final EstadoSolicitudCotizacion? filtroEstado;

  const MisSolicitudesLoaded({
    required this.solicitudes,
    this.filtroEstado,
  });

  /// Solicitudes filtradas segun el estado seleccionado
  List<SolicitudCotizacion> get solicitudesFiltradas {
    if (filtroEstado == null) return solicitudes;
    return solicitudes
        .where((s) => s.estado == filtroEstado)
        .toList();
  }

  @override
  List<Object?> get props => [solicitudes, filtroEstado];
}

/// Estado de error
class MisSolicitudesError extends MisSolicitudesState {
  final String message;

  const MisSolicitudesError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/solicitud_cotizacion.dart';

/// Estados para el formulario de solicitud de cotizacion
abstract class SolicitudFormState extends Equatable {
  const SolicitudFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - editando items
class SolicitudFormEditing extends SolicitudFormState {
  final List<SolicitudItem> items;
  final String? observaciones;

  const SolicitudFormEditing({
    this.items = const [],
    this.observaciones,
  });

  SolicitudFormEditing copyWith({
    List<SolicitudItem>? items,
    String? observaciones,
  }) {
    return SolicitudFormEditing(
      items: items ?? this.items,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  List<Object?> get props => [items, observaciones];
}

/// Estado de envio en curso
class SolicitudFormSubmitting extends SolicitudFormState {
  const SolicitudFormSubmitting();
}

/// Solicitud creada exitosamente
class SolicitudFormSuccess extends SolicitudFormState {
  final SolicitudCotizacion solicitud;
  final String message;

  const SolicitudFormSuccess({
    required this.solicitud,
    required this.message,
  });

  @override
  List<Object?> get props => [solicitud, message];
}

/// Error en el formulario
class SolicitudFormError extends SolicitudFormState {
  final String message;
  final List<SolicitudItem> items;
  final String? observaciones;

  const SolicitudFormError({
    required this.message,
    this.items = const [],
    this.observaciones,
  });

  @override
  List<Object?> get props => [message, items, observaciones];
}

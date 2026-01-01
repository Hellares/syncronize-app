import 'package:equatable/equatable.dart';
import '../../../domain/entities/atributo_plantilla.dart';
import '../../../domain/repositories/plantilla_repository.dart';

abstract class AtributoPlantillaState extends Equatable {
  const AtributoPlantillaState();

  @override
  List<Object?> get props => [];
}

class AtributoPlantillaInitial extends AtributoPlantillaState {}

class AtributoPlantillaLoading extends AtributoPlantillaState {}

class AtributoPlantillaLoaded extends AtributoPlantillaState {
  final List<AtributoPlantilla> plantillas;
  final PlanLimitsInfo? limitsInfo;

  const AtributoPlantillaLoaded({
    required this.plantillas,
    this.limitsInfo,
  });

  @override
  List<Object?> get props => [plantillas, limitsInfo];

  AtributoPlantillaLoaded copyWith({
    List<AtributoPlantilla>? plantillas,
    PlanLimitsInfo? limitsInfo,
  }) {
    return AtributoPlantillaLoaded(
      plantillas: plantillas ?? this.plantillas,
      limitsInfo: limitsInfo ?? this.limitsInfo,
    );
  }

  /// Verificar si se puede crear más plantillas
  bool get puedeCrearMas {
    if (limitsInfo == null) return true;
    return !limitsInfo!.plantillasAtributos.alcanzado;
  }

  /// Obtener mensaje de límite
  String? get mensajeLimite {
    if (limitsInfo == null) return null;
    final detail = limitsInfo!.plantillasAtributos;

    if (detail.esIlimitado) {
      return 'Plan ${limitsInfo!.plan}: Plantillas ilimitadas';
    }

    return 'Plan ${limitsInfo!.plan}: ${detail.actual} de ${detail.limite} plantillas utilizadas';
  }
}

/// Estado para una plantilla individual (al ver detalles)
class AtributoPlantillaDetail extends AtributoPlantillaState {
  final AtributoPlantilla plantilla;

  const AtributoPlantillaDetail({required this.plantilla});

  @override
  List<Object?> get props => [plantilla];
}

/// Estado mientras se crea/actualiza una plantilla
class AtributoPlantillaSubmitting extends AtributoPlantillaState {
  final String? message;

  const AtributoPlantillaSubmitting({this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado después de crear/actualizar exitosamente
class AtributoPlantillaSuccess extends AtributoPlantillaState {
  final String message;
  final AtributoPlantilla? plantilla;

  const AtributoPlantillaSuccess({
    required this.message,
    this.plantilla,
  });

  @override
  List<Object?> get props => [message, plantilla];
}

/// Estado mientras se aplica una plantilla a producto/variante
class AtributoPlantillaAplicando extends AtributoPlantillaState {
  final String plantillaNombre;

  const AtributoPlantillaAplicando({
    required this.plantillaNombre,
  });

  @override
  List<Object?> get props => [plantillaNombre];
}

/// Estado después de aplicar plantilla exitosamente
class AtributoPlantillaAplicada extends AtributoPlantillaState {
  final String message;
  final int atributosCreados;

  const AtributoPlantillaAplicada({
    required this.message,
    required this.atributosCreados,
  });

  @override
  List<Object?> get props => [message, atributosCreados];
}

class AtributoPlantillaError extends AtributoPlantillaState {
  final String message;

  const AtributoPlantillaError(this.message);

  @override
  List<Object?> get props => [message];
}

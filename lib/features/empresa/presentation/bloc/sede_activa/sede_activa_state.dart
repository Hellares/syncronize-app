import 'package:equatable/equatable.dart';
import '../../../domain/entities/sede.dart';

/// Estado del contexto "sede activa" global (el POS opera sobre `activa`).
class SedeActivaState extends Equatable {
  /// Sede sobre la que se opera ahora mismo (null = sin contexto aún).
  final Sede? activa;

  /// Sedes sobre las que el usuario puede operar (para el selector).
  final List<Sede> operables;

  const SedeActivaState({this.activa, this.operables = const []});

  bool get tieneSede => activa != null;
  bool get puedeElegir => operables.length > 1;

  SedeActivaState copyWith({Sede? activa, List<Sede>? operables}) {
    return SedeActivaState(
      activa: activa ?? this.activa,
      operables: operables ?? this.operables,
    );
  }

  @override
  List<Object?> get props => [activa, operables];
}

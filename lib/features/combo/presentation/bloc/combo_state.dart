import 'package:equatable/equatable.dart';
import '../../domain/entities/combo.dart';
import '../../domain/entities/componente_combo.dart';

/// Estados base del Combo Cubit
abstract class ComboState extends Equatable {
  const ComboState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ComboInitial extends ComboState {}

/// Estado de carga
class ComboLoading extends ComboState {}

/// Estado de lista de combos cargados
class CombosLoaded extends ComboState {
  final List<Combo> combos;

  const CombosLoaded(this.combos);

  @override
  List<Object?> get props => [combos];
}

/// Estado de combo cargado exitosamente
class ComboLoaded extends ComboState {
  final Combo combo;
  final int reservacionCantidad;

  const ComboLoaded(this.combo, {this.reservacionCantidad = 0});

  @override
  List<Object?> get props => [combo, reservacionCantidad];
}

/// Estado de lista de componentes cargados
class ComponentesLoaded extends ComboState {
  final List<ComponenteCombo> componentes;

  const ComponentesLoaded(this.componentes);

  @override
  List<Object?> get props => [componentes];
}

/// Estado de operación exitosa (crear, actualizar, eliminar)
class ComboOperationSuccess extends ComboState {
  final String message;
  final Combo? combo;

  const ComboOperationSuccess(this.message, {this.combo});

  @override
  List<Object?> get props => [message, combo];
}

/// Estado de componente agregado exitosamente
class ComponenteAdded extends ComboState {
  final ComponenteCombo componente;
  final String message;

  const ComponenteAdded(this.componente, this.message);

  @override
  List<Object?> get props => [componente, message];
}

/// Estado de múltiples componentes agregados en batch
class ComponentesBatchAdded extends ComboState {
  final List<ComponenteCombo> componentes;
  final String message;

  const ComponentesBatchAdded(this.componentes, this.message);

  @override
  List<Object?> get props => [componentes, message];
}

/// Estado de componente actualizado
class ComponenteUpdated extends ComboState {
  final ComponenteCombo componente;
  final String message;

  const ComponenteUpdated(this.componente, this.message);

  @override
  List<Object?> get props => [componente, message];
}

/// Estado de componente eliminado
class ComponenteDeleted extends ComboState {
  final String message;

  const ComponenteDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de múltiples componentes eliminados en batch
class ComponentesBatchDeleted extends ComboState {
  final int count;
  final String message;

  const ComponentesBatchDeleted(this.count, this.message);

  @override
  List<Object?> get props => [count, message];
}

/// Estado de error
class ComboError extends ComboState {
  final String message;
  final String? errorCode;

  const ComboError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Estado de stock validado
class StockValidated extends ComboState {
  final bool tieneStock;
  final int stockDisponible;

  const StockValidated(this.tieneStock, this.stockDisponible);

  @override
  List<Object?> get props => [tieneStock, stockDisponible];
}

/// Estado de reservación actualizada exitosamente
class ReservacionUpdated extends ComboState {
  final int cantidad;
  final String message;

  const ReservacionUpdated(this.cantidad, this.message);

  @override
  List<Object?> get props => [cantidad, message];
}

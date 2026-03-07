import 'package:equatable/equatable.dart';
import '../../../../empresa/domain/entities/sede.dart';
import '../../../domain/entities/precio_historial_sede.dart';

abstract class HistorialPreciosState extends Equatable {
  const HistorialPreciosState();

  @override
  List<Object?> get props => [];
}

class HistorialPreciosInitial extends HistorialPreciosState {}

class HistorialPreciosLoading extends HistorialPreciosState {}

class HistorialPreciosLoaded extends HistorialPreciosState {
  final List<PrecioHistorialSede> items;
  final List<Sede> sedes;
  final bool hasMore;

  const HistorialPreciosLoaded({
    required this.items,
    required this.sedes,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [items, sedes, hasMore];
}

class HistorialPreciosError extends HistorialPreciosState {
  final String message;

  const HistorialPreciosError(this.message);

  @override
  List<Object?> get props => [message];
}

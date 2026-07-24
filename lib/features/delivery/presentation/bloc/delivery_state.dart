import 'package:equatable/equatable.dart';
import '../../domain/entities/delivery_local.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();
  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

class DeliveryLoaded extends DeliveryState {
  final List<DeliveryLocal> disponibles;
  final List<DeliveryLocal> misEntregas;

  const DeliveryLoaded({
    required this.disponibles,
    required this.misEntregas,
  });

  /// Entregas activas del repartidor (TOMADO/EN_CAMINO) — van arriba.
  List<DeliveryLocal> get activas =>
      misEntregas.where((d) => d.esActivo).toList();

  List<DeliveryLocal> get historial =>
      misEntregas.where((d) => !d.esActivo).toList();

  @override
  List<Object?> get props => [disponibles, misEntregas];
}

class DeliveryError extends DeliveryState {
  final String message;
  const DeliveryError(this.message);
  @override
  List<Object?> get props => [message];
}

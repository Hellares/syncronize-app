import 'package:equatable/equatable.dart';
import '../../domain/entities/prestamo.dart';

abstract class PrestamoState extends Equatable {
  const PrestamoState();

  @override
  List<Object?> get props => [];
}

class PrestamoInitial extends PrestamoState {
  const PrestamoInitial();
}

class PrestamoLoading extends PrestamoState {
  const PrestamoLoading();
}

class PrestamoLoaded extends PrestamoState {
  final List<Prestamo> prestamos;
  final ResumenPrestamos? resumen;

  const PrestamoLoaded({
    required this.prestamos,
    this.resumen,
  });

  @override
  List<Object?> get props => [prestamos, resumen];
}

class PrestamoError extends PrestamoState {
  final String message;

  const PrestamoError(this.message);

  @override
  List<Object?> get props => [message];
}

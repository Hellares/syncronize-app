import 'package:equatable/equatable.dart';
import '../../../domain/entities/precio_nivel.dart';

/// Estados para gestión de niveles de precio
abstract class PrecioNivelState extends Equatable {
  const PrecioNivelState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PrecioNivelInitial extends PrecioNivelState {
  const PrecioNivelInitial();
}

/// Estado de carga
class PrecioNivelLoading extends PrecioNivelState {
  const PrecioNivelLoading();
}

/// Estado con niveles cargados
class PrecioNivelLoaded extends PrecioNivelState {
  final List<PrecioNivel> niveles;
  final bool isLoading; // Para operaciones en progreso
  final String? errorMessage;

  const PrecioNivelLoaded({
    required this.niveles,
    this.isLoading = false,
    this.errorMessage,
  });

  PrecioNivelLoaded copyWith({
    List<PrecioNivel>? niveles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PrecioNivelLoaded(
      niveles: niveles ?? this.niveles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [niveles, isLoading, errorMessage];
}

/// Estado de error
class PrecioNivelError extends PrecioNivelState {
  final String message;

  const PrecioNivelError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/atributo_valor.dart';

abstract class VarianteAtributoState extends Equatable {
  const VarianteAtributoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class VarianteAtributoInitial extends VarianteAtributoState {
  const VarianteAtributoInitial();
}

/// Estado de carga
class VarianteAtributoLoading extends VarianteAtributoState {
  const VarianteAtributoLoading();
}

/// Estado de éxito con lista de atributo valores
class VarianteAtributoLoaded extends VarianteAtributoState {
  final List<AtributoValor> atributoValores;
  final bool isLoading;
  final String? errorMessage;

  const VarianteAtributoLoaded({
    required this.atributoValores,
    this.isLoading = false,
    this.errorMessage,
  });

  VarianteAtributoLoaded copyWith({
    List<AtributoValor>? atributoValores,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VarianteAtributoLoaded(
      atributoValores: atributoValores ?? this.atributoValores,
      isLoading: isLoading ?? false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [atributoValores, isLoading, errorMessage];
}

/// Estado de error
class VarianteAtributoError extends VarianteAtributoState {
  final String message;

  const VarianteAtributoError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de operación exitosa (después de guardar)
class VarianteAtributoSaved extends VarianteAtributoState {
  final String message;
  final List<AtributoValor> atributoValores;

  const VarianteAtributoSaved({
    required this.message,
    required this.atributoValores,
  });

  @override
  List<Object?> get props => [message, atributoValores];
}

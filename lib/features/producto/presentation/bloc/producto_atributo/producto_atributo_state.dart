import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_atributo.dart';

abstract class ProductoAtributoState extends Equatable {
  const ProductoAtributoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoAtributoInitial extends ProductoAtributoState {
  const ProductoAtributoInitial();
}

/// Estado de carga
class ProductoAtributoLoading extends ProductoAtributoState {
  const ProductoAtributoLoading();
}

/// Estado de éxito con lista de atributos
class ProductoAtributoLoaded extends ProductoAtributoState {
  final List<ProductoAtributo> atributos;

  const ProductoAtributoLoaded(this.atributos);

  @override
  List<Object?> get props => [atributos];
}

/// Estado de error
class ProductoAtributoError extends ProductoAtributoState {
  final String message;

  const ProductoAtributoError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de operación exitosa (crear, actualizar, eliminar)
class ProductoAtributoOperationSuccess extends ProductoAtributoState {
  final String message;
  final List<ProductoAtributo> atributos;

  const ProductoAtributoOperationSuccess(this.message, this.atributos);

  @override
  List<Object?> get props => [message, atributos];
}

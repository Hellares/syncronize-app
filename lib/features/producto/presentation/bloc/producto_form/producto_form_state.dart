import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto.dart';

/// Estados del formulario de producto
sealed class ProductoFormState extends Equatable {
  const ProductoFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - formulario listo para usar
class ProductoFormInitial extends ProductoFormState {
  const ProductoFormInitial();
}

/// Estado de carga - operación en progreso
class ProductoFormLoading extends ProductoFormState {
  final String? message;

  const ProductoFormLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito - operación completada
class ProductoFormSuccess extends ProductoFormState {
  final Producto producto;
  final bool isEditing;
  final String message;

  const ProductoFormSuccess({
    required this.producto,
    required this.isEditing,
    required this.message,
  });

  @override
  List<Object?> get props => [producto, isEditing, message];
}

/// Estado de error - operación fallida
class ProductoFormError extends ProductoFormState {
  final String message;
  final ProductoFormErrorType type;

  const ProductoFormError({
    required this.message,
    this.type = ProductoFormErrorType.general,
  });

  @override
  List<Object?> get props => [message, type];
}

/// Estado de validación fallida
class ProductoFormValidationError extends ProductoFormState {
  final String message;
  final String? fieldName;

  const ProductoFormValidationError({
    required this.message,
    this.fieldName,
  });

  @override
  List<Object?> get props => [message, fieldName];
}

/// Estado de subida de imágenes en progreso
class ProductoFormUploadingImages extends ProductoFormState {
  final int current;
  final int total;

  const ProductoFormUploadingImages({
    required this.current,
    required this.total,
  });

  double get progress => total > 0 ? current / total : 0;

  @override
  List<Object?> get props => [current, total];
}

/// Tipos de error específicos
enum ProductoFormErrorType {
  general,
  network,
  validation,
  imageUpload,
  attributeSave,
  unauthorized,
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/proveedor.dart';

/// Estados para el formulario de proveedor
abstract class ProveedorFormState extends Equatable {
  const ProveedorFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProveedorFormInitial extends ProveedorFormState {
  const ProveedorFormInitial();
}

/// Estado de carga
class ProveedorFormLoading extends ProveedorFormState {
  const ProveedorFormLoading();
}

/// Estado de éxito al crear/actualizar
class ProveedorFormSuccess extends ProveedorFormState {
  final Proveedor proveedor;
  final bool isUpdate; // true si fue actualización, false si fue creación

  const ProveedorFormSuccess(this.proveedor, {this.isUpdate = false});

  @override
  List<Object?> get props => [proveedor, isUpdate];
}

/// Estado de error
class ProveedorFormError extends ProveedorFormState {
  final String message;

  const ProveedorFormError(this.message);

  @override
  List<Object?> get props => [message];
}

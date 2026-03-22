import 'package:equatable/equatable.dart';
import '../../domain/entities/ubicacion_almacen.dart';

abstract class UbicacionAlmacenState extends Equatable {
  const UbicacionAlmacenState();
  @override
  List<Object?> get props => [];
}

class UbicacionAlmacenInitial extends UbicacionAlmacenState {
  const UbicacionAlmacenInitial();
}

class UbicacionAlmacenLoading extends UbicacionAlmacenState {
  const UbicacionAlmacenLoading();
}

class UbicacionAlmacenLoaded extends UbicacionAlmacenState {
  final List<UbicacionAlmacen> ubicaciones;

  const UbicacionAlmacenLoaded({required this.ubicaciones});

  @override
  List<Object?> get props => [ubicaciones];
}

class UbicacionAlmacenError extends UbicacionAlmacenState {
  final String message;
  const UbicacionAlmacenError(this.message);
  @override
  List<Object?> get props => [message];
}

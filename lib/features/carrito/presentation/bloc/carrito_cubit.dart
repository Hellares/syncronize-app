import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/carrito.dart';
import '../../domain/repositories/carrito_repository.dart';
import '../../domain/usecases/get_carrito_usecase.dart';
import '../../domain/usecases/agregar_item_usecase.dart';
import '../../domain/usecases/actualizar_cantidad_usecase.dart';
import '../../domain/usecases/eliminar_item_usecase.dart';
import '../../domain/usecases/vaciar_carrito_usecase.dart';
import '../../domain/usecases/get_contador_usecase.dart';

part 'carrito_state.dart';

@injectable
class CarritoCubit extends Cubit<CarritoState> {
  final GetCarritoUseCase _getCarritoUseCase;
  final AgregarItemUseCase _agregarItemUseCase;
  final ActualizarCantidadUseCase _actualizarCantidadUseCase;
  final EliminarItemUseCase _eliminarItemUseCase;
  final VaciarCarritoUseCase _vaciarCarritoUseCase;
  final GetContadorUseCase _getContadorUseCase;

  CarritoContador? _contador;

  CarritoCubit(
    this._getCarritoUseCase,
    this._agregarItemUseCase,
    this._actualizarCantidadUseCase,
    this._eliminarItemUseCase,
    this._vaciarCarritoUseCase,
    this._getContadorUseCase,
  ) : super(const CarritoInitial());

  CarritoContador? get contador => _contador;

  Future<void> loadCarrito() async {
    emit(const CarritoLoading());
    final result = await _getCarritoUseCase();
    if (result is Success<Carrito>) {
      emit(CarritoLoaded(result.data));
    } else if (result is Error<Carrito>) {
      emit(CarritoError(result.message));
    }
  }

  Future<void> agregarItem({
    required String productoId,
    String? varianteId,
    int cantidad = 1,
  }) async {
    final result = await _agregarItemUseCase(
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
    );
    if (result is Success<Carrito>) {
      emit(CarritoLoaded(result.data));
      _actualizarContadorDesdeCarrito(result.data);
    } else if (result is Error<Carrito>) {
      emit(CarritoError(result.message));
    }
  }

  Future<void> actualizarCantidad({
    required String itemId,
    required int cantidad,
  }) async {
    final result = await _actualizarCantidadUseCase(
      itemId: itemId,
      cantidad: cantidad,
    );
    if (result is Success<Carrito>) {
      emit(CarritoLoaded(result.data));
      _actualizarContadorDesdeCarrito(result.data);
    } else if (result is Error<Carrito>) {
      emit(CarritoError(result.message));
    }
  }

  Future<void> eliminarItem({required String itemId}) async {
    final result = await _eliminarItemUseCase(itemId: itemId);
    if (result is Success<Carrito>) {
      emit(CarritoLoaded(result.data));
      _actualizarContadorDesdeCarrito(result.data);
    } else if (result is Error<Carrito>) {
      emit(CarritoError(result.message));
    }
  }

  Future<void> vaciarCarrito() async {
    final result = await _vaciarCarritoUseCase();
    if (result is Success<Carrito>) {
      emit(CarritoLoaded(result.data));
      _actualizarContadorDesdeCarrito(result.data);
    } else if (result is Error<Carrito>) {
      emit(CarritoError(result.message));
    }
  }

  Future<void> loadContador() async {
    final result = await _getContadorUseCase();
    if (result is Success<CarritoContador>) {
      _contador = result.data;
    }
  }

  void _actualizarContadorDesdeCarrito(Carrito carrito) {
    _contador = CarritoContador(
      totalItems: carrito.totalItems,
      totalCantidad: carrito.totalCantidad,
    );
  }
}

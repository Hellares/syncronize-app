import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/categoria_gasto.dart';
import '../../domain/usecases/get_categorias_gasto_usecase.dart';
import '../../domain/usecases/crear_categoria_gasto_usecase.dart';
import '../../domain/usecases/actualizar_categoria_gasto_usecase.dart';
import '../../domain/usecases/eliminar_categoria_gasto_usecase.dart';
import 'categoria_gasto_state.dart';

@injectable
class CategoriaGastoCubit extends Cubit<CategoriaGastoState> {
  final GetCategoriasGastoUseCase _getCategoriasGastoUseCase;
  final CrearCategoriaGastoUseCase _crearCategoriaGastoUseCase;
  final ActualizarCategoriaGastoUseCase _actualizarCategoriaGastoUseCase;
  final EliminarCategoriaGastoUseCase _eliminarCategoriaGastoUseCase;

  CategoriaGastoCubit(
    this._getCategoriasGastoUseCase,
    this._crearCategoriaGastoUseCase,
    this._actualizarCategoriaGastoUseCase,
    this._eliminarCategoriaGastoUseCase,
  ) : super(const CategoriaGastoInitial());

  Future<void> loadCategorias({String? tipo}) async {
    emit(const CategoriaGastoLoading());

    final result = await _getCategoriasGastoUseCase(tipo: tipo);
    if (isClosed) return;

    if (result is Success<List<CategoriaGasto>>) {
      emit(CategoriaGastoLoaded(categorias: result.data));
    } else if (result is Error<List<CategoriaGasto>>) {
      emit(CategoriaGastoError(result.message));
    }
  }

  Future<void> crear({
    required String nombre,
    required String tipo,
    String? color,
    String? icono,
  }) async {
    final result = await _crearCategoriaGastoUseCase(
      nombre: nombre,
      tipo: tipo,
      color: color,
      icono: icono,
    );
    if (isClosed) return;

    if (result is Error<CategoriaGasto>) {
      emit(CategoriaGastoError(result.message));
      return;
    }

    await loadCategorias();
  }

  Future<void> actualizar({
    required String id,
    String? nombre,
    String? color,
    String? icono,
  }) async {
    final result = await _actualizarCategoriaGastoUseCase(
      id: id,
      nombre: nombre,
      color: color,
      icono: icono,
    );
    if (isClosed) return;

    if (result is Error<CategoriaGasto>) {
      emit(CategoriaGastoError(result.message));
      return;
    }

    await loadCategorias();
  }

  Future<void> eliminar({required String id}) async {
    final result = await _eliminarCategoriaGastoUseCase(id: id);
    if (isClosed) return;

    if (result is Error<void>) {
      emit(CategoriaGastoError(result.message));
      return;
    }

    await loadCategorias();
  }
}

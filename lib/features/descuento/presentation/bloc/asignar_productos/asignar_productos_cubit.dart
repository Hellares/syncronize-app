import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/asignar_productos.dart';
import '../../../domain/usecases/asignar_categorias.dart';
import 'asignar_productos_state.dart';

@injectable
class AsignarProductosCubit extends Cubit<AsignarProductosState> {
  final AsignarProductos _asignarProductos;
  final AsignarCategorias _asignarCategorias;

  AsignarProductosCubit(
    this._asignarProductos,
    this._asignarCategorias,
  ) : super(const AsignarProductosInitial());

  Future<void> asignarProductos({
    required String politicaId,
    required List<Map<String, dynamic>> productos,
  }) async {
    emit(const AsignarProductosLoading());

    final result = await _asignarProductos(
      politicaId: politicaId,
      productos: productos,
    );

    if (result is Success<List<Map<String, dynamic>>>) {
      emit(const AsignarProductosSuccess('Productos asignados correctamente'));
    } else if (result is Error<List<Map<String, dynamic>>>) {
      emit(AsignarProductosError(result.message));
    }
  }

  Future<void> asignarCategorias({
    required String politicaId,
    required List<Map<String, dynamic>> categorias,
  }) async {
    emit(const AsignarProductosLoading());

    final result = await _asignarCategorias(
      politicaId: politicaId,
      categorias: categorias,
    );

    if (result is Success<List<Map<String, dynamic>>>) {
      emit(const AsignarProductosSuccess('Categorías asignadas correctamente'));
    } else if (result is Error<List<Map<String, dynamic>>>) {
      emit(AsignarProductosError(result.message));
    }
  }

  void reset() {
    emit(const AsignarProductosInitial());
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/producto_stock_model.dart';
import '../../../domain/usecases/get_alertas_stock_bajo_usecase.dart';
import 'alertas_stock_state.dart';

@injectable
class AlertasStockCubit extends Cubit<AlertasStockState> {
  final GetAlertasStockBajoUseCase _getAlertasStockBajoUseCase;

  AlertasStockCubit(
    this._getAlertasStockBajoUseCase,
  ) : super(const AlertasStockInitial());

  /// Carga las alertas de stock bajo
  Future<void> loadAlertas({
    required String empresaId,
    String? sedeId,
  }) async {
    emit(const AlertasStockLoading());

    final result = await _getAlertasStockBajoUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
    );

    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final total = data['total'] as int;
      final criticos = data['criticos'] as int;

      // Si no hay alertas
      if (total == 0) {
        emit(const AlertasStockEmpty());
        return;
      }

      // Parse productos
      final productos = (data['productos'] as List)
          .map((e) => ProductoStockModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Separar críticos de bajo mínimo
      final productosCriticos =
          productos.where((p) => p.esCritico).toList();
      final productosBajoMinimo =
          productos.where((p) => p.esBajoMinimo && !p.esCritico).toList();

      emit(AlertasStockLoaded(
        productosBajoMinimo: productosBajoMinimo,
        productosCriticos: productosCriticos,
        total: total,
        criticos: criticos,
        sedeId: sedeId,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(AlertasStockError(result.message, errorCode: result.errorCode));
    }
  }

  /// Recarga las alertas
  Future<void> reload({
    required String empresaId,
    String? sedeId,
  }) async {
    await loadAlertas(empresaId: empresaId, sedeId: sedeId);
  }

  /// Limpia el estado
  void clear() {
    emit(const AlertasStockInitial());
  }
}

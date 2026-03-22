import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/monitor_productos.dart';
import '../../domain/usecases/get_monitor_productos_usecase.dart';
import '../../domain/usecases/bulk_marketplace_usecase.dart';
import '../../domain/usecases/bulk_ubicacion_usecase.dart';
import '../../domain/usecases/bulk_precio_igv_usecase.dart';
import 'monitor_productos_state.dart';

@injectable
class MonitorProductosCubit extends Cubit<MonitorProductosState> {
  final GetMonitorProductosUseCase _getMonitorUseCase;
  final BulkMarketplaceUseCase _bulkMarketplaceUseCase;
  final BulkUbicacionUseCase _bulkUbicacionUseCase;
  final BulkPrecioIgvUseCase _bulkPrecioIgvUseCase;

  String? _lastSedeId;

  MonitorProductosCubit(
    this._getMonitorUseCase,
    this._bulkMarketplaceUseCase,
    this._bulkUbicacionUseCase,
    this._bulkPrecioIgvUseCase,
  ) : super(const MonitorProductosInitial());

  Future<void> loadMonitor({String? sedeId}) async {
    _lastSedeId = sedeId;
    emit(const MonitorProductosLoading());

    final result = await _getMonitorUseCase(sedeId: sedeId);
    if (isClosed) return;

    if (result is Success<MonitorProductos>) {
      emit(MonitorProductosLoaded(result.data));
    } else if (result is Error<MonitorProductos>) {
      emit(MonitorProductosError(result.message));
    }
  }

  Future<bool> bulkMarketplace(List<String> ids, bool visible) async {
    final result = await _bulkMarketplaceUseCase(ids, visible);
    if (result is Success) {
      await loadMonitor(sedeId: _lastSedeId);
      return true;
    }
    return false;
  }

  Future<bool> bulkUbicacion(List<String> ids, String ubicacion) async {
    final result = await _bulkUbicacionUseCase(ids, ubicacion);
    if (result is Success) {
      await loadMonitor(sedeId: _lastSedeId);
      return true;
    }
    return false;
  }

  Future<bool> bulkPrecioIgv(List<String> ids, bool incluyeIgv) async {
    final result = await _bulkPrecioIgvUseCase(ids, incluyeIgv);
    if (result is Success) {
      await loadMonitor(sedeId: _lastSedeId);
      return true;
    }
    return false;
  }
}

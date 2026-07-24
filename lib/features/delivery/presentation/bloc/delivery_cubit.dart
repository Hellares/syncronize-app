import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/delivery_local.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_state.dart';

@injectable
class DeliveryCubit extends Cubit<DeliveryState> {
  final DeliveryRepository _repository;

  String _empresaId = '';

  DeliveryCubit(this._repository) : super(const DeliveryInitial());

  Future<void> loadAll(String empresaId) async {
    _empresaId = empresaId;
    emit(const DeliveryLoading());
    await _cargar();
  }

  /// Garantiza datos frescos para ESTA empresa: carga completa si nunca
  /// cargó (o cambió la empresa / quedó a medias), refresh silencioso si ya
  /// hay datos. Lo llama la página al volver del background (resume) y
  /// cuando el contexto de empresa termina de cargar.
  Future<void> asegurarCarga(String empresaId) async {
    if (empresaId.isEmpty) return;
    if (_empresaId != empresaId || state is! DeliveryLoaded) {
      await loadAll(empresaId);
    } else {
      await refresh();
    }
  }

  /// Recarga sin pasar por Loading (pull-to-refresh / push realtime).
  Future<void> refresh() => _cargar();

  Future<void> _cargar() async {
    if (_empresaId.isEmpty) return;
    final results = await Future.wait([
      _repository.getDisponibles(_empresaId),
      _repository.getMisEntregas(_empresaId),
    ]);
    if (isClosed) return;

    final disponibles = results[0];
    final misEntregas = results[1];

    if (disponibles is Success<List<DeliveryLocal>> &&
        misEntregas is Success<List<DeliveryLocal>>) {
      emit(DeliveryLoaded(
        disponibles: disponibles.data,
        misEntregas: misEntregas.data,
      ));
    } else if (disponibles is Error<List<DeliveryLocal>>) {
      emit(DeliveryError(disponibles.message));
    } else if (misEntregas is Error<List<DeliveryLocal>>) {
      emit(DeliveryError(misEntregas.message));
    }
  }

  /// Acciones del repartidor. Devuelven el MENSAJE de error (null = éxito)
  /// para que la página SIEMPRE dé feedback — nunca fallar en silencio.
  Future<String?> tomar(String deliveryId) =>
      _accion((id) => _repository.tomar(id, _empresaId), deliveryId);

  Future<String?> marcarEnCamino(String deliveryId) =>
      _accion((id) => _repository.marcarEnCamino(id, _empresaId), deliveryId);

  Future<String?> marcarEntregado(String deliveryId) =>
      _accion((id) => _repository.marcarEntregado(id, _empresaId), deliveryId);

  Future<String?> _accion(
    Future<Resource<DeliveryLocal>> Function(String id) fn,
    String deliveryId,
  ) async {
    final result = await fn(deliveryId);
    if (isClosed) return null;
    if (result is Success<DeliveryLocal>) {
      await _cargar();
      return null;
    }
    // El delivery pudo cambiar de estado (ej. otro lo tomó) → refrescar igual.
    await _cargar();
    return result is Error<DeliveryLocal>
        ? result.message
        : 'No se pudo completar la acción';
  }
}

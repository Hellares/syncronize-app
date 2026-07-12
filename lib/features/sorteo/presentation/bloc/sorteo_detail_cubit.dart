import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/sorteo.dart';
import '../../domain/repositories/sorteo_repository.dart';

part 'sorteo_detail_state.dart';

/// Detalle de un sorteo: premios, registro de ganadores, transición de
/// estados y subida del ticket de envío. Las acciones devuelven el
/// mensaje de error (null = éxito) para feedback puntual en la UI sin
/// perder el estado Loaded.
@injectable
class SorteoDetailCubit extends Cubit<SorteoDetailState> {
  final SorteoRepository _repository;

  SorteoDetailCubit(this._repository) : super(const SorteoDetailLoading());

  String? _sorteoId;

  Future<void> load(String sorteoId) async {
    _sorteoId = sorteoId;
    emit(const SorteoDetailLoading());
    final result = await _repository.getSorteoDetalle(sorteoId);
    if (isClosed) return;
    if (result is Success<Sorteo>) {
      emit(SorteoDetailLoaded(result.data));
    } else if (result is Error<Sorteo>) {
      emit(SorteoDetailError(result.message));
    }
  }

  Future<void> reload() async {
    final id = _sorteoId;
    if (id == null) return;
    final result = await _repository.getSorteoDetalle(id);
    if (isClosed) return;
    if (result is Success<Sorteo>) emit(SorteoDetailLoaded(result.data));
  }

  Future<String?> registrarPremio({
    required String ganadorDni,
    required String ganadorNombre,
    String? ganadorCelular,
    required String descripcion,
    String? productoId,
    String? varianteId,
    int cantidad = 1,
    double? montoParticipacion,
    required ModalidadEntregaPremio modalidad,
    String? agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
    String? observaciones,
    String? sedeId,
  }) async {
    final id = _sorteoId;
    if (id == null) return 'Sorteo no cargado';
    final result = await _repository.registrarPremio(
      sorteoId: id,
      ganadorDni: ganadorDni,
      ganadorNombre: ganadorNombre,
      ganadorCelular: ganadorCelular,
      descripcion: descripcion,
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
      montoParticipacion: montoParticipacion,
      modalidad: modalidad,
      agenciaNombre: agenciaNombre,
      destinoDepartamento: destinoDepartamento,
      destinoProvincia: destinoProvincia,
      agenciaDireccion: agenciaDireccion,
      observaciones: observaciones,
      sedeId: sedeId,
    );
    if (isClosed) return null;
    if (result is Error<SorteoPremio>) return result.message;
    await reload();
    return null;
  }

  /// Última entrega por agencia del DNI — best-effort para prellenar el
  /// registro de ganadores repetidos; si falla, se registra sin prellenar.
  Future<EntregaPreviaGanador?> getEntregaPrevia(String dni) async {
    final result = await _repository.getUltimaEntregaGanador(dni);
    return result is Success<EntregaPreviaGanador?> ? result.data : null;
  }

  Future<String?> cambiarEstadoPremio({
    required String premioId,
    required EstadoPremioSorteo estado,
    String? observaciones,
    String? envioNumeroOrden,
    String? envioCodigo,
    String? envioClave,
  }) async {
    final result = await _repository.cambiarEstadoPremio(
      premioId: premioId,
      estado: estado,
      observaciones: observaciones,
      envioNumeroOrden: envioNumeroOrden,
      envioCodigo: envioCodigo,
      envioClave: envioClave,
    );
    if (isClosed) return null;
    if (result is Error<SorteoPremio>) return result.message;
    await reload();
    return null;
  }

  /// Corrige la entrega del premio (modalidad y/o agencia) — p.ej.
  /// quedó en retiro en tienda por error al registrar.
  Future<String?> editarEntregaPremio({
    required String premioId,
    required ModalidadEntregaPremio modalidad,
    String? agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
  }) async {
    final result = await _repository.editarEntregaPremio(
      premioId: premioId,
      modalidad: modalidad,
      agenciaNombre: agenciaNombre,
      destinoDepartamento: destinoDepartamento,
      destinoProvincia: destinoProvincia,
      agenciaDireccion: agenciaDireccion,
    );
    if (isClosed) return null;
    if (result is Error<SorteoPremio>) return result.message;
    await reload();
    return null;
  }

  /// Marca los rótulos como impresos tras un print exitoso (batch:
  /// "2 por hoja" imprime varios premios de una vez).
  Future<void> marcarRotulosImpresos(List<String> premioIds) async {
    for (final id in premioIds) {
      await _repository.marcarRotuloImpreso(id);
      if (isClosed) return;
    }
    await reload();
  }

  Future<String?> subirTicketEnvio(String premioId, File file) async {
    final result = await _repository.subirTicketEnvio(premioId, file);
    if (isClosed) return null;
    if (result is Error<void>) return result.message;
    await reload();
    return null;
  }

  Future<String?> subirFotoPremio(String premioId, File file) async {
    final result = await _repository.subirFotoPremio(premioId, file);
    if (isClosed) return null;
    if (result is Error<void>) return result.message;
    await reload();
    return null;
  }

  Future<String?> subirImagenSorteo(File file) async {
    final id = _sorteoId;
    if (id == null) return 'Sorteo no cargado';
    final result = await _repository.subirImagenSorteo(id, file);
    if (isClosed) return null;
    if (result is Error<void>) return result.message;
    await reload();
    return null;
  }

  Future<String?> cerrarSorteo() async {
    final id = _sorteoId;
    if (id == null) return 'Sorteo no cargado';
    final result =
        await _repository.actualizarSorteo(id, estado: EstadoSorteo.cerrado);
    if (isClosed) return null;
    if (result is Error<Sorteo>) return result.message;
    await reload();
    return null;
  }
}

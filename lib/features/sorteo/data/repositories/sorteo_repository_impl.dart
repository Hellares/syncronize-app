import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/sorteo.dart';
import '../../domain/repositories/sorteo_repository.dart';
import '../datasources/sorteo_remote_datasource.dart';

@LazySingleton(as: SorteoRepository)
class SorteoRepositoryImpl implements SorteoRepository {
  final SorteoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  SorteoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  Future<Resource<T>> _guard<T>(Future<T> Function() body) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      return Success(await body());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Sorteos');
    }
  }

  @override
  Future<Resource<List<Sorteo>>> getSorteos({EstadoSorteo? estado}) =>
      _guard(() async {
        final models =
            await _remoteDataSource.getSorteos(estado: estado?.apiValue);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Resource<Sorteo>> crearSorteo({
    required String titulo,
    String? descripcion,
    CanalSorteo? canal,
    TipoSorteo? tipo,
    DateTime? fechaSorteo,
    DateTime? ventaDesde,
    DateTime? ventaHasta,
    String? sedeId,
    double? precioParticipacion,
  }) =>
      _guard(() async {
        final model = await _remoteDataSource.crearSorteo({
          'titulo': titulo,
          if (descripcion != null && descripcion.isNotEmpty)
            'descripcion': descripcion,
          if (canal != null) 'canal': canal.apiValue,
          if (tipo != null) 'tipo': tipo.apiValue,
          if (fechaSorteo != null)
            'fechaSorteo': fechaSorteo.toIso8601String(),
          if (ventaDesde != null)
            'ventaDesde': ventaDesde.toIso8601String(),
          if (ventaHasta != null)
            'ventaHasta': ventaHasta.toIso8601String(),
          if (sedeId != null) 'sedeId': sedeId,
          if (precioParticipacion != null)
            'precioParticipacion': precioParticipacion,
        });
        return model.toEntity();
      });

  @override
  Future<Resource<Sorteo>> getSorteoDetalle(String id) =>
      _guard(() async =>
          (await _remoteDataSource.getSorteoDetalle(id)).toEntity());

  @override
  Future<Resource<Sorteo>> actualizarSorteo(
    String id, {
    String? titulo,
    String? descripcion,
    CanalSorteo? canal,
    EstadoSorteo? estado,
    List<LiveLinkSorteo>? liveLinks,
  }) =>
      _guard(() async {
        final model = await _remoteDataSource.actualizarSorteo(id, {
          if (titulo != null) 'titulo': titulo,
          if (descripcion != null) 'descripcion': descripcion,
          if (canal != null) 'canal': canal.apiValue,
          if (estado != null) 'estado': estado.apiValue,
          // Lista vacía = quitar los links (por eso no se filtra).
          if (liveLinks != null)
            'liveLinks': liveLinks
                .map((l) => {'plataforma': l.plataforma, 'url': l.url})
                .toList(),
        });
        return model.toEntity();
      });

  @override
  Future<Resource<SorteoPremio>> registrarPremio({
    required String sorteoId,
    String? participanteId,
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
    bool esEfectivo = false,
  }) =>
      _guard(() async {
        final model = await _remoteDataSource.registrarPremio(sorteoId, {
          'esEfectivo': esEfectivo,
          if (participanteId != null) 'participanteId': participanteId,
          'ganadorDni': ganadorDni,
          'ganadorNombre': ganadorNombre,
          if (ganadorCelular != null && ganadorCelular.isNotEmpty)
            'ganadorCelular': ganadorCelular,
          'descripcion': descripcion,
          if (productoId != null) 'productoId': productoId,
          if (varianteId != null) 'varianteId': varianteId,
          'cantidad': cantidad,
          if (montoParticipacion != null)
            'montoParticipacion': montoParticipacion,
          'modalidad': modalidad.apiValue,
          if (agenciaNombre != null && agenciaNombre.isNotEmpty)
            'agenciaNombre': agenciaNombre,
          if (destinoDepartamento != null && destinoDepartamento.isNotEmpty)
            'destinoDepartamento': destinoDepartamento,
          if (destinoProvincia != null && destinoProvincia.isNotEmpty)
            'destinoProvincia': destinoProvincia,
          if (agenciaDireccion != null && agenciaDireccion.isNotEmpty)
            'agenciaDireccion': agenciaDireccion,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (sedeId != null) 'sedeId': sedeId,
        });
        return model.toEntity();
      });

  @override
  Future<Resource<SorteoPremio>> cambiarEstadoPremio({
    required String premioId,
    required EstadoPremioSorteo estado,
    String? observaciones,
    String? envioNumeroOrden,
    String? envioCodigo,
    String? envioClave,
  }) =>
      _guard(() async {
        final model = await _remoteDataSource.cambiarEstadoPremio(premioId, {
          'estado': estado.apiValue,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (envioNumeroOrden != null && envioNumeroOrden.isNotEmpty)
            'envioNumeroOrden': envioNumeroOrden,
          if (envioCodigo != null && envioCodigo.isNotEmpty)
            'envioCodigo': envioCodigo,
          if (envioClave != null && envioClave.isNotEmpty)
            'envioClave': envioClave,
        });
        return model.toEntity();
      });

  @override
  Future<Resource<SorteoPremio>> editarEntregaPremio({
    required String premioId,
    required ModalidadEntregaPremio modalidad,
    String? agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
  }) =>
      _guard(() async {
        final model = await _remoteDataSource.editarEntregaPremio(premioId, {
          'modalidad': modalidad.apiValue,
          if (agenciaNombre != null && agenciaNombre.isNotEmpty)
            'agenciaNombre': agenciaNombre,
          if (destinoDepartamento != null && destinoDepartamento.isNotEmpty)
            'destinoDepartamento': destinoDepartamento,
          if (destinoProvincia != null && destinoProvincia.isNotEmpty)
            'destinoProvincia': destinoProvincia,
          if (agenciaDireccion != null && agenciaDireccion.isNotEmpty)
            'agenciaDireccion': agenciaDireccion,
        });
        return model.toEntity();
      });

  @override
  Future<Resource<EntregaPreviaGanador?>> getUltimaEntregaGanador(
          String dni) =>
      _guard(() async {
        final json = await _remoteDataSource.getUltimaEntregaGanador(dni);
        if (json == null) return null;
        return EntregaPreviaGanador(
          agenciaNombre: json['agenciaNombre'] as String?,
          destinoDepartamento: json['destinoDepartamento'] as String?,
          destinoProvincia: json['destinoProvincia'] as String?,
          agenciaDireccion: json['agenciaDireccion'] as String?,
        );
      });

  @override
  Future<Resource<void>> cambiarEstadoParticipante({
    required String participanteId,
    required EstadoParticipanteSorteo estado,
  }) =>
      _guard(() => _remoteDataSource.cambiarEstadoParticipante(
          participanteId, estado.apiValue));

  @override
  Future<Resource<void>> marcarRotuloImpreso(String premioId) =>
      _guard(() => _remoteDataSource.marcarRotuloImpreso(premioId));

  @override
  Future<Resource<bool>> subirTicketEnvio(String premioId, File file) =>
      _guard(() => _remoteDataSource.subirTicketEnvio(premioId, file));

  @override
  Future<Resource<void>> subirFotoPremio(String premioId, File file) =>
      _guard(() => _remoteDataSource.subirFotoPremio(premioId, file));

  @override
  Future<Resource<void>> subirImagenSorteo(String sorteoId, File file) =>
      _guard(() => _remoteDataSource.subirImagenSorteo(sorteoId, file));
}

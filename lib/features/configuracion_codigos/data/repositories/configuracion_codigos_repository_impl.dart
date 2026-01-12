import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_codigos.dart';
import '../../domain/repositories/configuracion_codigos_repository.dart';
import '../datasources/configuracion_codigos_remote_datasource.dart';

@LazySingleton(as: ConfiguracionCodigosRepository)
class ConfiguracionCodigosRepositoryImpl
    implements ConfiguracionCodigosRepository {
  final ConfiguracionCodigosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ConfiguracionCodigosRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<ConfiguracionCodigos>> getConfiguracion(
    String empresaId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final configuracion = await _remoteDataSource.getConfiguracion(empresaId);
      return Success(configuracion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'GET_CONFIG_ERROR',
      );
    }
  }

  @override
  Future<Resource<ConfiguracionCodigos>> updateConfigProductos({
    required String empresaId,
    String? productoCodigo,
    String? productoSeparador,
    int? productoLongitud,
    bool? productoIncluirSede,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (productoCodigo != null) 'productoCodigo': productoCodigo,
        if (productoSeparador != null) 'productoSeparador': productoSeparador,
        if (productoLongitud != null) 'productoLongitud': productoLongitud,
        if (productoIncluirSede != null)
          'productoIncluirSede': productoIncluirSede,
      };

      final configuracion = await _remoteDataSource.updateConfigProductos(
        empresaId: empresaId,
        data: data,
      );
      return Success(configuracion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'UPDATE_CONFIG_PRODUCTOS_ERROR',
      );
    }
  }

  @override
  Future<Resource<ConfiguracionCodigos>> updateConfigVariantes({
    required String empresaId,
    String? varianteCodigo,
    String? varianteSeparador,
    int? varianteLongitud,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (varianteCodigo != null) 'varianteCodigo': varianteCodigo,
        if (varianteSeparador != null) 'varianteSeparador': varianteSeparador,
        if (varianteLongitud != null) 'varianteLongitud': varianteLongitud,
      };

      final configuracion = await _remoteDataSource.updateConfigVariantes(
        empresaId: empresaId,
        data: data,
      );
      return Success(configuracion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'UPDATE_CONFIG_VARIANTES_ERROR',
      );
    }
  }

  @override
  Future<Resource<ConfiguracionCodigos>> updateConfigServicios({
    required String empresaId,
    String? servicioCodigo,
    String? servicioSeparador,
    int? servicioLongitud,
    bool? servicioIncluirSede,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (servicioCodigo != null) 'servicioCodigo': servicioCodigo,
        if (servicioSeparador != null) 'servicioSeparador': servicioSeparador,
        if (servicioLongitud != null) 'servicioLongitud': servicioLongitud,
        if (servicioIncluirSede != null)
          'servicioIncluirSede': servicioIncluirSede,
      };

      final configuracion = await _remoteDataSource.updateConfigServicios(
        empresaId: empresaId,
        data: data,
      );
      return Success(configuracion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'UPDATE_CONFIG_SERVICIOS_ERROR',
      );
    }
  }

  @override
  Future<Resource<ConfiguracionCodigos>> updateConfigVentas({
    required String empresaId,
    String? ventaCodigo,
    String? ventaSeparador,
    int? ventaLongitud,
    bool? ventaIncluirSede,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (ventaCodigo != null) 'ventaCodigo': ventaCodigo,
        if (ventaSeparador != null) 'ventaSeparador': ventaSeparador,
        if (ventaLongitud != null) 'ventaLongitud': ventaLongitud,
        if (ventaIncluirSede != null) 'ventaIncluirSede': ventaIncluirSede,
      };

      final configuracion = await _remoteDataSource.updateConfigVentas(
        empresaId: empresaId,
        data: data,
      );
      return Success(configuracion.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'UPDATE_CONFIG_VENTAS_ERROR',
      );
    }
  }

  @override
  Future<Resource<PreviewCodigo>> previewCodigo({
    required String empresaId,
    required TipoCodigo tipo,
    String? sedeId,
    int? numero,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        'tipo': tipo.toJson(),
        if (sedeId != null) 'sedeId': sedeId,
        if (numero != null) 'numero': numero,
      };

      final preview = await _remoteDataSource.previewCodigo(
        empresaId: empresaId,
        data: data,
      );
      return Success(preview);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'PREVIEW_CODIGO_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> sincronizarContador({
    required String empresaId,
    required String tipo,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.sincronizarContador(
        empresaId: empresaId,
        tipo: tipo,
      );
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SINCRONIZAR_CONTADOR_ERROR',
      );
    }
  }
}

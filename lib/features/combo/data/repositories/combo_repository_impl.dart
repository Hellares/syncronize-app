import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/combo.dart';
import '../../domain/entities/componente_combo.dart';
import '../../domain/repositories/combo_repository.dart';
import '../datasources/combo_remote_datasource.dart';
// import '../models/combo_model.dart';
import '../models/create_combo_dto.dart';

@LazySingleton(as: ComboRepository)
class ComboRepositoryImpl implements ComboRepository {
  final ComboRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ComboRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<Combo>> createCombo({
    required CreateComboDto dto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final combo = await _remoteDataSource.createCombo(dto: dto);
      return Success(combo.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Combo>>> getCombos({
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final combos = await _remoteDataSource.getCombos();
      return Success(combos.map((combo) => combo.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Combo>> getComboCompleto({
    required String comboId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final combo = await _remoteDataSource.getComboCompleto(
        comboId: comboId,
      );
      return Success(combo.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<ComponenteCombo>> agregarComponente({
    required String comboId,
    required String empresaId,
    String? componenteProductoId,
    String? componenteVarianteId,
    required int cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (componenteProductoId != null)
          'componenteProductoId': componenteProductoId,
        if (componenteVarianteId != null)
          'componenteVarianteId': componenteVarianteId,
        'cantidad': cantidad,
        if (esPersonalizable != null) 'esPersonalizable': esPersonalizable,
        if (categoriaComponente != null)
          'categoriaComponente': categoriaComponente,
        if (orden != null) 'orden': orden,
      };

      final componente = await _remoteDataSource.agregarComponente(
        comboId: comboId,
        data: data,
      );
      return Success(componente.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<ComponenteCombo>>> agregarComponentesBatch({
    required String comboId,
    required String empresaId,
    required List<Map<String, dynamic>> componentes,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final componentesAgregados = await _remoteDataSource.agregarComponentesBatch(
        comboId: comboId,
        componentes: componentes,
      );
      return Success(componentesAgregados.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<ComponenteCombo>>> getComponentes({
    required String comboId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final componentes = await _remoteDataSource.getComponentes(
        comboId: comboId,
      );
      return Success(componentes.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<ComponenteCombo>> actualizarComponente({
    required String componenteId,
    required String empresaId,
    int? cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        if (cantidad != null) 'cantidad': cantidad,
        if (esPersonalizable != null) 'esPersonalizable': esPersonalizable,
        if (categoriaComponente != null)
          'categoriaComponente': categoriaComponente,
        if (orden != null) 'orden': orden,
      };

      final componente = await _remoteDataSource.actualizarComponente(
        componenteId: componenteId,
        data: data,
      );
      return Success(componente.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> eliminarComponente({
    required String componenteId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarComponente(
        componenteId: componenteId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<int>> getStockDisponible({
    required String comboId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.getStockDisponible(
        comboId: comboId,
      );
      return Success(stock);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<double>> getPrecioCalculado({
    required String comboId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final precio = await _remoteDataSource.getPrecioCalculado(
        comboId: comboId,
      );
      return Success(precio);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<bool>> validarStock({
    required String comboId,
    required int cantidad,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final tieneStock = await _remoteDataSource.validarStock(
        comboId: comboId,
        cantidad: cantidad,
      );
      return Success(tieneStock);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/categoria_maestra.dart';
import '../../domain/entities/empresa_categoria.dart';
import '../../domain/entities/empresa_marca.dart';
import '../../domain/entities/marca_maestra.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../datasources/catalogo_remote_datasource.dart';

@LazySingleton(as: CatalogoRepository)
class CatalogoRepositoryImpl implements CatalogoRepository {
  final CatalogoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  CatalogoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  // ============================================
  // CATEGORÍAS MAESTRAS
  // ============================================

  @override
  Future<Resource<List<CategoriaMaestra>>> getCategoriasMaestras({
    bool incluirHijos = false,
    bool soloPopulares = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final categorias = await _remoteDataSource.getCategoriasMaestras(
        incluirHijos: incluirHijos,
        soloPopulares: soloPopulares,
      );
      return Success(categorias.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  // ============================================
  // MARCAS MAESTRAS
  // ============================================

  @override
  Future<Resource<List<MarcaMaestra>>> getMarcasMaestras({
    bool soloPopulares = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final marcas = await _remoteDataSource.getMarcasMaestras(
        soloPopulares: soloPopulares,
      );
      return Success(marcas.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  // ============================================
  // CATEGORÍAS POR EMPRESA
  // ============================================

  @override
  Future<Resource<List<EmpresaCategoria>>> getCategoriasEmpresa(
    String empresaId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final categorias =
          await _remoteDataSource.getCategoriasEmpresa(empresaId);
      return Success(categorias.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<EmpresaCategoria>> activarCategoria({
    required String empresaId,
    String? categoriaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
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
        'empresaId': empresaId,
        if (categoriaMaestraId != null)
          'categoriaMaestraId': categoriaMaestraId,
        if (nombrePersonalizado != null)
          'nombrePersonalizado': nombrePersonalizado,
        if (descripcionPersonalizada != null)
          'descripcionPersonalizada': descripcionPersonalizada,
        if (nombreLocal != null) 'nombreLocal': nombreLocal,
        if (orden != null) 'orden': orden,
      };

      final categoria = await _remoteDataSource.activarCategoria(data);
      return Success(categoria.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> desactivarCategoria({
    required String empresaId,
    required String empresaCategoriaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.desactivarCategoria(
        empresaId: empresaId,
        empresaCategoriaId: empresaCategoriaId,
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
  Future<Resource<List<EmpresaCategoria>>> activarCategoriasPopulares(
    String empresaId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final categorias =
          await _remoteDataSource.activarCategoriasPopulares(empresaId);
      return Success(categorias.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  // ============================================
  // MARCAS POR EMPRESA
  // ============================================

  @override
  Future<Resource<List<EmpresaMarca>>> getMarcasEmpresa(
    String empresaId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final marcas = await _remoteDataSource.getMarcasEmpresa(empresaId);
      return Success(marcas.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<EmpresaMarca>> activarMarca({
    required String empresaId,
    String? marcaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
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
        'empresaId': empresaId,
        if (marcaMaestraId != null) 'marcaMaestraId': marcaMaestraId,
        if (nombrePersonalizado != null)
          'nombrePersonalizado': nombrePersonalizado,
        if (descripcionPersonalizada != null)
          'descripcionPersonalizada': descripcionPersonalizada,
        if (nombreLocal != null) 'nombreLocal': nombreLocal,
        if (orden != null) 'orden': orden,
      };

      final marca = await _remoteDataSource.activarMarca(data);
      return Success(marca.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> desactivarMarca({
    required String empresaId,
    required String empresaMarcaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.desactivarMarca(
        empresaId: empresaId,
        empresaMarcaId: empresaMarcaId,
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
  Future<Resource<List<EmpresaMarca>>> activarMarcasPopulares(
    String empresaId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final marcas = await _remoteDataSource.activarMarcasPopulares(empresaId);
      return Success(marcas.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}

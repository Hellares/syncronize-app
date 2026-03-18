import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/campana.dart';
import '../../domain/repositories/promocion_repository.dart';
import '../datasources/promocion_remote_datasource.dart';
import '../models/campana_model.dart';

@LazySingleton(as: PromocionRepository)
class PromocionRepositoryImpl implements PromocionRepository {
  final PromocionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  PromocionRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Resource<CampanasPaginadas>> getCampanas({
    int page = 1,
    int limit = 20,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getCampanas(
        page: page,
        limit: limit,
      );
      final data = (result['data'] as List)
          .map((e) => CampanaModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return Success(CampanasPaginadas(
        data: data,
        total: result['total'] as int? ?? 0,
        page: result['page'] as int? ?? page,
        totalPages: result['totalPages'] as int? ?? 1,
      ));
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<Campana>> crearCampana({
    required String titulo,
    required String mensaje,
    List<String>? productosIds,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'titulo': titulo,
        'mensaje': mensaje,
      };
      if (productosIds != null && productosIds.isNotEmpty) {
        data['productosIds'] = productosIds;
      }
      final result = await _remoteDataSource.crearCampana(data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<List<ProductoEnOferta>>> getProductosEnOferta() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getProductosEnOferta();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }
}

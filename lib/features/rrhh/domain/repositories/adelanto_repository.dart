import '../../../../core/utils/resource.dart';
import '../entities/adelanto.dart';

abstract class AdelantoRepository {
  Future<Resource<Adelanto>> create(Map<String, dynamic> data);

  Future<Resource<List<Adelanto>>> getAll({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<Adelanto>> aprobar(String id);

  Future<Resource<Adelanto>> rechazar(String id, String motivoRechazo);

  Future<Resource<Adelanto>> pagar(String id, Map<String, dynamic> data);
}

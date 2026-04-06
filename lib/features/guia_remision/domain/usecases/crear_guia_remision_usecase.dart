import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/guia_remision.dart';
import '../repositories/guia_remision_repository.dart';

@lazySingleton
class CrearGuiaRemisionUseCase {
  final GuiaRemisionRepository _repository;
  CrearGuiaRemisionUseCase(this._repository);

  Future<Resource<GuiaRemision>> call(Map<String, dynamic> data) {
    return _repository.crear(data);
  }
}

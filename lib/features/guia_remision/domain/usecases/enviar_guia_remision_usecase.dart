import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/guia_remision_repository.dart';

@lazySingleton
class EnviarGuiaRemisionUseCase {
  final GuiaRemisionRepository _repository;
  EnviarGuiaRemisionUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call(String id) {
    return _repository.enviar(id);
  }
}

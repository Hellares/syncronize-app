import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/consulta_ruc.dart';
import '../repositories/consultas_repository.dart';

@lazySingleton
class ConsultarRucUseCase {
  final ConsultasRepository _repository;

  ConsultarRucUseCase(this._repository);

  Future<Resource<ConsultaRuc>> call(String ruc) {
    return _repository.consultarRuc(ruc);
  }
}

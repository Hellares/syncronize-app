import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/consulta_placa.dart';
import '../repositories/consultas_repository.dart';

@lazySingleton
class ConsultarPlacaUseCase {
  final ConsultasRepository _repository;

  ConsultarPlacaUseCase(this._repository);

  Future<Resource<ConsultaPlaca>> call(String placa) {
    return _repository.consultarPlaca(placa);
  }
}

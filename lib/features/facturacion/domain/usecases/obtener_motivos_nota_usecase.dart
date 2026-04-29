import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/motivo_nota.dart';
import '../entities/tipo_nota.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class ObtenerMotivosNotaUseCase {
  final FacturacionRepository _repository;
  ObtenerMotivosNotaUseCase(this._repository);

  Future<Resource<List<MotivoNota>>> call(TipoNota tipo) {
    return _repository.obtenerMotivosNota(tipo);
  }
}

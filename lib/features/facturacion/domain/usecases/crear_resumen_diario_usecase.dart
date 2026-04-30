import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/crear_resumen_diario_request.dart';
import '../entities/resumen_diario.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class CrearResumenDiarioUseCase {
  final FacturacionRepository _repository;
  CrearResumenDiarioUseCase(this._repository);

  Future<Resource<ResumenDiario>> call(CrearResumenDiarioRequest req) {
    return _repository.crearResumenDiario(req);
  }
}

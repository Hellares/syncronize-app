import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/flujo_proyectado.dart';
import '../repositories/flujo_proyectado_repository.dart';

@injectable
class GetFlujoProyectadoUseCase {
  final FlujoProyectadoRepository _repository;

  GetFlujoProyectadoUseCase(this._repository);

  Future<Resource<List<PeriodoFlujo>>> call({int? meses}) {
    return _repository.getProyeccion(meses: meses);
  }
}

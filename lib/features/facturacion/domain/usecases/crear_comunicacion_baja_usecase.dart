import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/comunicacion_baja.dart';
import '../entities/crear_comunicacion_baja_request.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class CrearComunicacionBajaUseCase {
  final FacturacionRepository _repository;
  CrearComunicacionBajaUseCase(this._repository);

  Future<Resource<ComunicacionBaja>> call(CrearComunicacionBajaRequest req) {
    return _repository.crearComunicacionBaja(req);
  }
}

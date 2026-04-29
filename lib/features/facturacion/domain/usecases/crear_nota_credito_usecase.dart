import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/crear_nota_request.dart';
import '../entities/nota_emitida.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class CrearNotaCreditoUseCase {
  final FacturacionRepository _repository;
  CrearNotaCreditoUseCase(this._repository);

  Future<Resource<NotaEmitida>> call({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) {
    return _repository.crearNotaCredito(
      comprobanteOrigenId: comprobanteOrigenId,
      request: request,
    );
  }
}

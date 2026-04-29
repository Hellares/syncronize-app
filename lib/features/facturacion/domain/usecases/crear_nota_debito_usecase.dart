import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/crear_nota_request.dart';
import '../entities/nota_emitida.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class CrearNotaDebitoUseCase {
  final FacturacionRepository _repository;
  CrearNotaDebitoUseCase(this._repository);

  Future<Resource<NotaEmitida>> call({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) {
    return _repository.crearNotaDebito(
      comprobanteOrigenId: comprobanteOrigenId,
      request: request,
    );
  }
}

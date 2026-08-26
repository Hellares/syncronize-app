import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

/// Editar una compra que todavía está en BORRADOR.
///
/// El backend hace un MERGE: manda solo lo que cambió. El caso que motivó
/// esto es el flete que se registró después de guardar la compra, que se
/// arregla con `data: {'gastos': [...]}` sin reenviar las líneas.
@injectable
class ActualizarCompraUseCase {
  final CompraRepository _repository;

  ActualizarCompraUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.actualizarCompra(
      empresaId: empresaId,
      id: id,
      data: data,
    );
  }
}

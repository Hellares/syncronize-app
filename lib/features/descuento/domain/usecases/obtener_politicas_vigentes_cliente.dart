import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener las políticas de precio especial vigentes de un
/// cliente (B2C o B2B). Usado por Venta Rápida para el preview de precio VIP.
@injectable
class ObtenerPoliticasVigentesCliente {
  final DescuentoRepository _repository;

  ObtenerPoliticasVigentesCliente(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call({
    String? clienteId,
    String? clienteEmpresaId,
  }) async {
    return await _repository.obtenerPoliticasVigentesCliente(
      clienteId: clienteId,
      clienteEmpresaId: clienteEmpresaId,
    );
  }
}

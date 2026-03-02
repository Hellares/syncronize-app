import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class CrearCompraDesdeOcUseCase {
  final CompraRepository _repository;

  CrearCompraDesdeOcUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.crearCompraDesdeOc(
      empresaId: empresaId,
      data: data,
    );
  }
}

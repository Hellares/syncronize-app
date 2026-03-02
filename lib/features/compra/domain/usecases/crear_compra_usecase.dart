import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra.dart';
import '../repositories/compra_repository.dart';

@injectable
class CrearCompraUseCase {
  final CompraRepository _repository;

  CrearCompraUseCase(this._repository);

  Future<Resource<Compra>> call({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.crearCompra(
      empresaId: empresaId,
      data: data,
    );
  }
}

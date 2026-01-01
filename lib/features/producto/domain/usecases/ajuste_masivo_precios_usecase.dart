import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_repository.dart';

@injectable
class AjusteMasivoPreciosUseCase {
  final ProductoRepository _repository;

  AjusteMasivoPreciosUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    return await _repository.ajusteMasivoPrecios(
      empresaId: empresaId,
      dto: dto,
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener lista de políticas de descuento con filtros
@injectable
class GetPoliticasDescuento {
  final DescuentoRepository _repository;

  GetPoliticasDescuento(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    return await _repository.getPoliticas(
      tipoDescuento: tipoDescuento,
      isActive: isActive,
      page: page,
      limit: limit,
    );
  }
}

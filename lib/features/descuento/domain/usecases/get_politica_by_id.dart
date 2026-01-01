import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/politica_descuento.dart';
import '../repositories/descuento_repository.dart';

/// Use case para obtener una política de descuento por ID
@injectable
class GetPoliticaById {
  final DescuentoRepository _repository;

  GetPoliticaById(this._repository);

  Future<Resource<PoliticaDescuento>> call(String id) async {
    return await _repository.getPoliticaById(id);
  }
}

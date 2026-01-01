import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/politica_descuento.dart';
import '../repositories/descuento_repository.dart';

/// Use case para agregar un familiar a un trabajador
@injectable
class AgregarFamiliar {
  final DescuentoRepository _repository;

  AgregarFamiliar(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String trabajadorId,
    required String familiarUsuarioId,
    required Parentesco parentesco,
    int? limiteMensualUsos,
    String? documentoVerificacion,
  }) async {
    return await _repository.agregarFamiliar(
      trabajadorId: trabajadorId,
      familiarUsuarioId: familiarUsuarioId,
      parentesco: parentesco,
      limiteMensualUsos: limiteMensualUsos,
      documentoVerificacion: documentoVerificacion,
    );
  }
}

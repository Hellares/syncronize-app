import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/politica_descuento.dart';
import '../repositories/descuento_repository.dart';

/// Use case para crear una nueva política de descuento
@injectable
class CreatePolitica {
  final DescuentoRepository _repository;

  CreatePolitica(this._repository);

  Future<Resource<PoliticaDescuento>> call({
    required String nombre,
    String? descripcion,
    required TipoDescuento tipoDescuento,
    required TipoCalculoDescuento tipoCalculo,
    required double valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
  }) async {
    return await _repository.createPolitica(
      nombre: nombre,
      descripcion: descripcion,
      tipoDescuento: tipoDescuento,
      tipoCalculo: tipoCalculo,
      valorDescuento: valorDescuento,
      descuentoMaximo: descuentoMaximo,
      montoMinCompra: montoMinCompra,
      cantidadMaxUsos: cantidadMaxUsos,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      aplicarATodos: aplicarATodos,
      prioridad: prioridad,
      maxFamiliaresPorTrabajador: maxFamiliaresPorTrabajador,
    );
  }
}

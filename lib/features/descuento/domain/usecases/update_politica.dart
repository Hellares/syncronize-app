import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/politica_descuento.dart';
import '../repositories/descuento_repository.dart';

/// Use case para actualizar una política de descuento existente
@injectable
class UpdatePolitica {
  final DescuentoRepository _repository;

  UpdatePolitica(this._repository);

  Future<Resource<PoliticaDescuento>> call({
    required String id,
    String? nombre,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    TipoCalculoDescuento? tipoCalculo,
    double? valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
    bool? isActive,
  }) async {
    return await _repository.updatePolitica(
      id: id,
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
      isActive: isActive,
    );
  }
}

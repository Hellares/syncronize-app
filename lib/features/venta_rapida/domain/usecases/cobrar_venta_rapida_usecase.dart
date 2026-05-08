import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../repositories/venta_rapida_repository.dart';

/// Cobra una venta del flujo Venta Rápida.
@lazySingleton
class CobrarVentaRapidaUseCase {
  final VentaRapidaRepository _repository;

  CobrarVentaRapidaUseCase(this._repository);

  Future<Resource<Venta>> call({required Map<String, dynamic> data}) {
    return _repository.cobrar(data: data);
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/meta_financiera.dart';
import '../repositories/meta_financiera_repository.dart';

@injectable
class CrearMetaFinancieraUseCase {
  final MetaFinancieraRepository _repository;

  CrearMetaFinancieraUseCase(this._repository);

  Future<Resource<MetaFinanciera>> call({
    required String tipo,
    required String nombre,
    required double montoMeta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    return _repository.crear(
      tipo: tipo,
      nombre: nombre,
      montoMeta: montoMeta,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}

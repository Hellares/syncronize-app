import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/arqueo_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class CrearArqueoUseCase {
  final CajaRepository _repository;

  CrearArqueoUseCase(this._repository);

  Future<Resource<ArqueoCaja>> call({
    required String cajaId,
    required TipoArqueoCaja tipo,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
    String? autorizadoPorId,
    String? turnoEntregadoAId,
  }) {
    return _repository.crearArqueo(
      cajaId: cajaId,
      tipo: tipo,
      conteos: conteos,
      observaciones: observaciones,
      autorizadoPorId: autorizadoPorId,
      turnoEntregadoAId: turnoEntregadoAId,
    );
  }
}

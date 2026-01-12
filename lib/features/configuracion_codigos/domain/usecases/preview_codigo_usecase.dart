import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para obtener vista previa de un código
@injectable
class PreviewCodigoUseCase {
  final ConfiguracionCodigosRepository _repository;

  PreviewCodigoUseCase(this._repository);

  Future<Resource<PreviewCodigo>> call({
    required String empresaId,
    required TipoCodigo tipo,
    String? sedeId,
    int? numero,
  }) {
    return _repository.previewCodigo(
      empresaId: empresaId,
      tipo: tipo,
      sedeId: sedeId,
      numero: numero,
    );
  }
}

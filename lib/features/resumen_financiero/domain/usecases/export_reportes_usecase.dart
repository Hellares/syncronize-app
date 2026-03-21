import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/resumen_financiero_repository.dart';

@injectable
class ExportLibroContableUseCase {
  final ResumenFinancieroRepository _repository;
  ExportLibroContableUseCase(this._repository);

  Future<Resource<List<int>>> call({
    required int mes,
    required int anio,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _repository.exportLibroContable(
      mes: mes,
      anio: anio,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

@injectable
class ExportCuentasCobrarUseCase {
  final ResumenFinancieroRepository _repository;
  ExportCuentasCobrarUseCase(this._repository);

  Future<Resource<List<int>>> call({
    void Function(int, int)? onReceiveProgress,
  }) {
    return _repository.exportCuentasCobrar(onReceiveProgress: onReceiveProgress);
  }
}

@injectable
class ExportCuentasPagarUseCase {
  final ResumenFinancieroRepository _repository;
  ExportCuentasPagarUseCase(this._repository);

  Future<Resource<List<int>>> call({
    void Function(int, int)? onReceiveProgress,
  }) {
    return _repository.exportCuentasPagar(onReceiveProgress: onReceiveProgress);
  }
}

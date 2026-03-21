import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja_monitor.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetMonitorUseCase {
  final CajaRepository _repository;

  GetMonitorUseCase(this._repository);

  Future<Resource<CajaMonitorData>> call({String? sedeId}) {
    return _repository.getMonitor(sedeId: sedeId);
  }
}

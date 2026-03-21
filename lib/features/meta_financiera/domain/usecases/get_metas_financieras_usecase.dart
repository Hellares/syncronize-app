import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/meta_financiera.dart';
import '../repositories/meta_financiera_repository.dart';

@injectable
class GetMetasFinancierasUseCase {
  final MetaFinancieraRepository _repository;

  GetMetasFinancierasUseCase(this._repository);

  Future<Resource<List<MetaFinanciera>>> call() {
    return _repository.getResumen();
  }
}

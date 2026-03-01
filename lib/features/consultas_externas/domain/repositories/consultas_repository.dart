import '../../../../core/utils/resource.dart';
import '../entities/consulta_dni.dart';
import '../entities/consulta_ruc.dart';

abstract class ConsultasRepository {
  Future<Resource<ConsultaRuc>> consultarRuc(String ruc);
  Future<Resource<ConsultaDni>> consultarDni(String dni);
}

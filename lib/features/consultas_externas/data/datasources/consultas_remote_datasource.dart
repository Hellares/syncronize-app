import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../models/consulta_dni_model.dart';
import '../models/consulta_licencia_model.dart';
import '../models/consulta_placa_model.dart';
import '../models/consulta_ruc_model.dart';

abstract class ConsultasRemoteDataSource {
  Future<ConsultaRucModel> consultarRuc(String ruc);
  Future<ConsultaDniModel> consultarDni(String dni);
  Future<ConsultaLicenciaModel> consultarLicencia(String dni);
  Future<ConsultaPlacaModel> consultarPlaca(String placa);
}

@LazySingleton(as: ConsultasRemoteDataSource)
class ConsultasRemoteDataSourceImpl implements ConsultasRemoteDataSource {
  final DioClient _client;

  ConsultasRemoteDataSourceImpl(this._client);

  @override
  Future<ConsultaRucModel> consultarRuc(String ruc) async {
    final response = await _client.get('/consultas/ruc/$ruc');
    return ConsultaRucModel.fromJson(response.data);
  }

  @override
  Future<ConsultaDniModel> consultarDni(String dni) async {
    final response = await _client.get('/consultas/dni/$dni');
    return ConsultaDniModel.fromJson(response.data);
  }

  @override
  Future<ConsultaLicenciaModel> consultarLicencia(String dni) async {
    final response = await _client.get('/consultas/licencia/$dni');
    return ConsultaLicenciaModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ConsultaPlacaModel> consultarPlaca(String placa) async {
    final response = await _client.get('/consultas/placa/$placa');
    return ConsultaPlacaModel.fromJson(response.data as Map<String, dynamic>);
  }
}

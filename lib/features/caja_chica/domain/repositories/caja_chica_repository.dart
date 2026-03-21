import '../../../../core/utils/resource.dart';
import '../entities/caja_chica.dart';
import '../entities/gasto_caja_chica.dart';
import '../entities/rendicion_caja_chica.dart';

abstract class CajaChicaRepository {
  Future<Resource<CajaChica>> crearCajaChica({
    required String sedeId,
    required String nombre,
    required double fondoFijo,
    double? umbralAlerta,
    required String responsableId,
  });

  Future<Resource<List<CajaChica>>> listarCajasChicas({String? sedeId});

  Future<Resource<CajaChica>> getCajaChica({required String id});

  Future<Resource<void>> actualizarEstado({
    required String id,
    required String estado,
  });

  Future<Resource<GastoCajaChica>> registrarGasto({
    required String cajaChicaId,
    required double monto,
    required String descripcion,
    required String categoriaGastoId,
    String? comprobanteUrl,
  });

  Future<Resource<List<GastoCajaChica>>> listarGastos({
    required String cajaChicaId,
    bool? pendientes,
  });

  Future<Resource<RendicionCajaChica>> crearRendicion({
    required String cajaChicaId,
    required List<String> gastoIds,
    String? observaciones,
  });

  Future<Resource<List<RendicionCajaChica>>> listarRendiciones({
    String? cajaChicaId,
    String? estado,
  });

  Future<Resource<RendicionCajaChica>> getRendicion({
    required String rendicionId,
  });

  Future<Resource<void>> aprobarRendicion({
    required String rendicionId,
    String? observaciones,
  });

  Future<Resource<void>> rechazarRendicion({
    required String rendicionId,
    required String observaciones,
  });
}

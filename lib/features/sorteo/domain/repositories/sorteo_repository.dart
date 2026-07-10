import 'dart:io';

import '../../../../core/utils/resource.dart';
import '../entities/sorteo.dart';

abstract class SorteoRepository {
  Future<Resource<List<Sorteo>>> getSorteos({EstadoSorteo? estado});

  Future<Resource<Sorteo>> crearSorteo({
    required String titulo,
    String? descripcion,
    CanalSorteo? canal,
    DateTime? fechaSorteo,
    String? sedeId,
    double? precioParticipacion,
  });

  Future<Resource<Sorteo>> getSorteoDetalle(String id);

  Future<Resource<Sorteo>> actualizarSorteo(
    String id, {
    String? titulo,
    String? descripcion,
    CanalSorteo? canal,
    EstadoSorteo? estado,
  });

  Future<Resource<SorteoPremio>> registrarPremio({
    required String sorteoId,
    required String ganadorDni,
    required String ganadorNombre,
    String? ganadorCelular,
    required String descripcion,
    String? productoId,
    String? varianteId,
    int cantidad = 1,
    double? montoParticipacion,
    required ModalidadEntregaPremio modalidad,
    String? agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
    String? observaciones,
    String? sedeId,
  });

  Future<Resource<SorteoPremio>> cambiarEstadoPremio({
    required String premioId,
    required EstadoPremioSorteo estado,
    String? observaciones,
    String? envioNumeroOrden,
    String? envioCodigo,
    String? envioClave,
  });

  Future<Resource<void>> subirTicketEnvio(String premioId, File file);

  Future<Resource<void>> subirFotoPremio(String premioId, File file);

  Future<Resource<void>> subirImagenSorteo(String sorteoId, File file);
}

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

  /// Corrige la entrega del premio (modalidad y/o agencia) — solo antes
  /// del despacho.
  Future<Resource<SorteoPremio>> editarEntregaPremio({
    required String premioId,
    required ModalidadEntregaPremio modalidad,
    String? agenciaNombre,
    String? destinoDepartamento,
    String? destinoProvincia,
    String? agenciaDireccion,
  });

  /// Última entrega por agencia registrada para el DNI — null si nunca
  /// tuvo un envío (prellenado de ganadores repetidos).
  Future<Resource<EntregaPreviaGanador?>> getUltimaEntregaGanador(String dni);

  /// Valida/rechaza un participante captado por el bot de WhatsApp.
  Future<Resource<void>> cambiarEstadoParticipante({
    required String participanteId,
    required EstadoParticipanteSorteo estado,
  });

  Future<Resource<void>> marcarRotuloImpreso(String premioId);

  /// true = el backend además envió el ticket por WhatsApp al ganador.
  Future<Resource<bool>> subirTicketEnvio(String premioId, File file);

  Future<Resource<void>> subirFotoPremio(String premioId, File file);

  Future<Resource<void>> subirImagenSorteo(String sorteoId, File file);
}

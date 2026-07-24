import '../../../../core/utils/resource.dart';
import '../entities/delivery_local.dart';

abstract class DeliveryRepository {
  Future<Resource<DeliveryLocal>> solicitar(Map<String, dynamic> data);

  Future<Resource<List<DeliveryLocal>>> getDisponibles(
    String empresaId, {
    String? sedeId,
  });

  Future<Resource<List<DeliveryLocal>>> getMisEntregas(String empresaId);

  Future<Resource<DeliveryLocal>> tomar(String id, String empresaId);

  Future<Resource<DeliveryLocal>> marcarEnCamino(String id, String empresaId);

  Future<Resource<DeliveryLocal>> marcarEntregado(String id, String empresaId);

  // ── Pool externo (freelance) ──

  Future<Resource<List<DeliveryLocal>>> getExternoDisponibles();

  Future<Resource<List<DeliveryLocal>>> getExternoMisEntregas();

  Future<Resource<DeliveryLocal>> tomarExterno(String id);
}

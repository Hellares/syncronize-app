import '../../../../core/utils/resource.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';

/// Contrato del repository de cotización rápida.
///
/// Reutiliza la entidad `Cotizacion` del módulo cotización compartido
/// (mismo dominio de negocio); solo cambia el flujo de UX (POS-style).
/// Las operaciones de listado/duplicado/anulación siguen viviendo en
/// el repository del módulo `cotizacion`.
abstract class CotizacionRapidaRepository {
  /// POST /cotizaciones — crea una cotización en estado BORRADOR.
  Future<Resource<Cotizacion>> crear({
    required Map<String, dynamic> data,
  });

  /// PUT /cotizaciones/:id — actualiza una cotización (solo BORRADOR).
  /// Aquí solo se editan items; cliente/condiciones quedan al stepper viejo.
  Future<Resource<Cotizacion>> actualizar({
    required String cotizacionId,
    required Map<String, dynamic> data,
  });

  /// GET /cotizaciones/:id — usado al entrar a la pantalla de edición
  /// para cargar los items existentes al cubit.
  Future<Resource<Cotizacion>> obtener({
    required String cotizacionId,
  });
}

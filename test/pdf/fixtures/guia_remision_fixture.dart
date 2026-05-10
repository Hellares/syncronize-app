import 'package:syncronize/features/guia_remision/domain/entities/guia_remision.dart';

/// Fixture determinístico de GuiaRemision para golden tests.
class GuiaRemisionFixture {
  GuiaRemisionFixture._();

  static final _fechaEmision = DateTime.utc(2026, 1, 15, 10, 0, 0);
  static final _fechaTraslado = DateTime.utc(2026, 1, 16, 8, 0, 0);
  static final _creadoEn = DateTime.utc(2026, 1, 15, 10, 0, 5);

  /// Guía REMITENTE básica con 2 detalles.
  static GuiaRemision build() {
    return GuiaRemision(
      id: 'gr_test_001',
      empresaId: 'emp_test',
      tipo: 'REMITENTE',
      serie: 'T001',
      correlativo: 1,
      codigoGenerado: 'T001-00000001',
      estado: 'ENVIADA',
      sunatStatus: 'ACEPTADO',
      fechaEmision: _fechaEmision,
      fechaInicioTraslado: _fechaTraslado,
      motivoTraslado: '01', // Venta
      pesoBrutoTotal: 25.5,
      numeroBultos: 3,
      tipoTransporte: 'PRIVADO',
      clienteTipoDocumento: '6',
      clienteNumeroDocumento: '20987654321',
      clienteDenominacion: 'Cliente Empresa SAC',
      clienteDireccion: 'Av. Cliente 123',
      puntoPartidaUbigeo: '150101',
      puntoPartidaDireccion: 'Av. Origen 999',
      puntoLlegadaUbigeo: '150103',
      puntoLlegadaDireccion: 'Av. Destino 555',
      transportistaPlacaNumero: 'ABC-123',
      conductorNombre: 'Pedro',
      conductorApellidos: 'Conductor Test',
      conductorNumeroLicencia: 'Q12345678',
      sunatHash: 'TEST-HASH-GR-001',
      cadenaQR:
          '20111111111|09|T001|1|25.5|15/01/2026|6|20987654321|TEST-HASH-GR-001|',
      creadoEn: _creadoEn,
      detalles: const [
        GuiaRemisionDetalle(
          id: 'grd_001',
          productoId: 'p_001',
          unidadMedida: 'NIU',
          codigo: 'P-A-001',
          descripcion: 'Producto A para traslado',
          cantidad: 10,
        ),
        GuiaRemisionDetalle(
          id: 'grd_002',
          productoId: 'p_002',
          unidadMedida: 'NIU',
          codigo: 'P-B-002',
          descripcion: 'Producto B para traslado',
          cantidad: 5,
        ),
      ],
      documentosRelacionados: const [],
    );
  }
}

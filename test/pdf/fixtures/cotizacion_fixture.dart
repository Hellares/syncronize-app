import 'package:syncronize/features/cotizacion/domain/entities/cotizacion.dart';
import 'package:syncronize/features/cotizacion/domain/entities/cotizacion_detalle.dart';

/// Fixture determinístico de Cotización para golden tests.
///
/// IDs y fechas hardcoded para que el output del PDF sea reproducible.
/// El timestamp del PDF metadata es separado y se ignora en la firma.
class CotizacionFixture {
  CotizacionFixture._();

  static final _fechaEmision = DateTime.utc(2026, 1, 15, 10, 30, 0);
  static final _fechaVencimiento = DateTime.utc(2026, 2, 15, 10, 30, 0);
  static final _creadoEn = DateTime.utc(2026, 1, 15, 10, 30, 5);
  static final _actualizadoEn = DateTime.utc(2026, 1, 15, 10, 30, 5);

  static Cotizacion build() {
    return Cotizacion(
      id: 'cot_test_001',
      empresaId: 'emp_test',
      sedeId: 'sede_test',
      vendedorId: 'vendedor_test',
      clienteId: 'cli_test',
      codigo: 'COT-2026-00001',
      nombre: 'Cotización de prueba',
      nombreCliente: 'Cliente de Prueba SAC',
      documentoCliente: '20123456789',
      emailCliente: 'cliente@test.com',
      telefonoCliente: '999888777',
      direccionCliente: 'Av. Test 123, Lima',
      moneda: 'PEN',
      tipoCambio: null,
      subtotal: 169.49,
      descuento: 5.00,
      impuestos: 30.51,
      total: 200.00,
      fechaEmision: _fechaEmision,
      fechaVencimiento: _fechaVencimiento,
      estado: EstadoCotizacion.aprobada,
      observaciones: 'Cotización para validación de PDF.',
      condiciones: 'Pago: 50% adelanto, 50% contra entrega.',
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      sedeNombre: 'Sede Principal',
      vendedorNombre: 'Vendedor Test',
      detalles: [
        CotizacionDetalle(
          id: 'det_001',
          cotizacionId: 'cot_test_001',
          productoId: 'prod_001',
          descripcion: 'Producto de prueba A',
          cantidad: 2,
          precioUnitario: 50.00,
          descuento: 0,
          subtotal: 84.75,
          igv: 15.25,
          total: 100.00,
          orden: 0,
          productoNombre: 'Producto A',
          productoCodigo: 'P-A-001',
        ),
        CotizacionDetalle(
          id: 'det_002',
          cotizacionId: 'cot_test_001',
          productoId: 'prod_002',
          descripcion: 'Producto de prueba B',
          cantidad: 1,
          precioUnitario: 100.00,
          descuento: 5.00,
          subtotal: 80.51,
          igv: 14.49,
          total: 95.00,
          orden: 1,
          productoNombre: 'Producto B',
          productoCodigo: 'P-B-002',
        ),
      ],
    );
  }
}

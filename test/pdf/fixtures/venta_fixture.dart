import 'package:syncronize/features/venta/domain/entities/venta.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle.dart';

/// Fixture determinístico de Venta para golden tests.
class VentaFixture {
  VentaFixture._();

  static final _fechaVenta = DateTime.utc(2026, 1, 15, 11, 0, 0);
  static final _creadoEn = DateTime.utc(2026, 1, 15, 11, 0, 5);
  static final _actualizadoEn = DateTime.utc(2026, 1, 15, 11, 0, 5);

  /// Boleta básica (sin SUNAT) para ticket térmico.
  static Venta buildBoletaTicket() {
    return Venta(
      id: 'vta_test_001',
      empresaId: 'emp_test',
      sedeId: 'sede_test',
      vendedorId: 'vendedor_test',
      codigo: 'V-2026-00001',
      canalVenta: 'POS',
      nombreCliente: 'Cliente de Prueba',
      documentoCliente: '12345678',
      moneda: 'PEN',
      subtotal: 84.75,
      descuento: 0,
      impuestos: 15.25,
      total: 100.00,
      estado: EstadoVenta.pagadaCompleta,
      tipoComprobante: 'BOLETA',
      codigoComprobante: 'B001-00000001',
      fechaVenta: _fechaVenta,
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      sedeNombre: 'Sede Principal',
      vendedorNombre: 'Vendedor Test',
      detalles: [
        VentaDetalle(
          id: 'vd_001',
          ventaId: 'vta_test_001',
          productoId: 'prod_001',
          descripcion: 'Producto Boleta A',
          cantidad: 2,
          precioUnitario: 50.00,
          subtotal: 84.75,
          igv: 15.25,
          total: 100.00,
          orden: 0,
          productoNombre: 'Producto A',
        ),
      ],
    );
  }

  /// Factura SUNAT con desglose tributario (Op. Gravada).
  static Venta buildFacturaA4() {
    return Venta(
      id: 'vta_test_002',
      empresaId: 'emp_test',
      sedeId: 'sede_test',
      vendedorId: 'vendedor_test',
      codigo: 'V-2026-00002',
      canalVenta: 'POS',
      nombreCliente: 'Empresa Cliente SAC',
      documentoCliente: '20987654321',
      moneda: 'PEN',
      subtotal: 169.49,
      descuento: 0,
      impuestos: 30.51,
      total: 200.00,
      estado: EstadoVenta.pagadaCompleta,
      tipoComprobante: 'FACTURA',
      codigoComprobante: 'F001-00000001',
      comprobanteGravada: 169.49,
      comprobanteIgv: 30.51,
      comprobanteSunatHash: 'TEST-HASH-001',
      comprobanteCadenaQR:
          '20111111111|01|F001|1|30.51|200.00|15/01/2026|6|20987654321|TEST-HASH-001|',
      fechaVenta: _fechaVenta,
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      sedeNombre: 'Sede Principal',
      vendedorNombre: 'Vendedor Test',
      detalles: [
        VentaDetalle(
          id: 'vd_002',
          ventaId: 'vta_test_002',
          productoId: 'prod_002',
          descripcion: 'Servicio profesional',
          cantidad: 1,
          precioUnitario: 169.49,
          subtotal: 169.49,
          igv: 30.51,
          total: 200.00,
          orden: 0,
          productoNombre: 'Servicio',
        ),
      ],
    );
  }
}

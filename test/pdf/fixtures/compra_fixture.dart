import 'package:syncronize/features/compra/domain/entities/compra.dart';

/// Fixture determinístico de Compra para golden tests.
class CompraFixture {
  CompraFixture._();

  static final _fechaRecepcion = DateTime.utc(2026, 1, 15, 14, 0, 0);
  static final _creadoEn = DateTime.utc(2026, 1, 15, 14, 0, 5);
  static final _actualizadoEn = DateTime.utc(2026, 1, 15, 14, 0, 5);

  static Compra build() {
    return Compra(
      id: 'cmp_test_001',
      empresaId: 'emp_test',
      sedeId: 'sede_test',
      proveedorId: 'prov_test',
      codigo: 'C-2026-00001',
      nombreProveedor: 'Proveedor Test SAC',
      documentoProveedor: '20999888777',
      tipoDocumentoProveedor: 'FACTURA',
      serieDocumentoProveedor: 'F001',
      numeroDocumentoProveedor: '00012345',
      terminosPago: 'CONTADO',
      moneda: 'PEN',
      subtotal: 423.73,
      descuento: 0,
      impuestos: 76.27,
      total: 500.00,
      fechaRecepcion: _fechaRecepcion,
      estado: EstadoCompra.CONFIRMADA,
      observaciones: 'Compra de prueba para validación de PDF.',
      creadoPor: 'admin_test',
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      detalles: [
        CompraDetalle(
          id: 'cd_001',
          compraId: 'cmp_test_001',
          productoId: 'prod_001',
          descripcion: 'Insumo A',
          cantidad: 10,
          precioUnitario: 30.00,
          subtotal: 254.24,
          igv: 45.76,
          total: 300.00,
          orden: 0,
        ),
        CompraDetalle(
          id: 'cd_002',
          compraId: 'cmp_test_001',
          productoId: 'prod_002',
          descripcion: 'Insumo B',
          cantidad: 5,
          precioUnitario: 40.00,
          subtotal: 169.49,
          igv: 30.51,
          total: 200.00,
          orden: 1,
        ),
      ],
    );
  }
}

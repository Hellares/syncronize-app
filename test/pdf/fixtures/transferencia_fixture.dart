import 'package:syncronize/features/producto/domain/entities/transferencia_stock.dart';

/// Fixture determinístico de TransferenciaStock para golden tests.
class TransferenciaFixture {
  TransferenciaFixture._();

  static final _creadoEn = DateTime.utc(2026, 1, 15, 10, 0, 0);
  static final _actualizadoEn = DateTime.utc(2026, 1, 15, 10, 0, 5);

  static TransferenciaStock build() {
    return TransferenciaStock(
      id: 'tr_test_001',
      empresaId: 'emp_test',
      sedeOrigenId: 'sede_origen',
      sedeDestinoId: 'sede_destino',
      codigo: 'TR-2026-00001',
      estado: EstadoTransferencia.aprobada,
      totalItems: 2,
      itemsAprobados: 2,
      motivo: 'Reabastecimiento sucursal',
      observaciones: 'Transferencia de prueba',
      solicitadoPor: 'Solicitante Test',
      aprobadoPor: 'Aprobador Test',
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      sedeOrigen: const SedeTransferencia(
        id: 'sede_origen',
        nombre: 'Sede Central',
        codigo: 'SC',
      ),
      sedeDestino: const SedeTransferencia(
        id: 'sede_destino',
        nombre: 'Sucursal Norte',
        codigo: 'SN',
      ),
      items: [
        TransferenciaStockItem(
          id: 'tri_001',
          transferenciaId: 'tr_test_001',
          empresaId: 'emp_test',
          productoId: 'p_001',
          cantidadSolicitada: 10,
          cantidadAprobada: 10,
          estado: EstadoItemTransferencia.aprobado,
          creadoEn: _creadoEn,
          actualizadoEn: _actualizadoEn,
          producto: const ProductoTransferenciaInfo(
            id: 'p_001',
            nombre: 'Producto A',
            codigoEmpresa: 'P-A-001',
          ),
        ),
        TransferenciaStockItem(
          id: 'tri_002',
          transferenciaId: 'tr_test_001',
          empresaId: 'emp_test',
          productoId: 'p_002',
          cantidadSolicitada: 5,
          cantidadAprobada: 5,
          estado: EstadoItemTransferencia.aprobado,
          creadoEn: _creadoEn,
          actualizadoEn: _actualizadoEn,
          producto: const ProductoTransferenciaInfo(
            id: 'p_002',
            nombre: 'Producto B',
            codigoEmpresa: 'P-B-002',
          ),
        ),
      ],
    );
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/deposito_cliente.dart';
import '../../domain/entities/estado_cuenta_cliente.dart';
import '../models/cuenta_cobrar_model.dart';

@lazySingleton
class CuentasCobrarRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/cuentas-por-cobrar';

  CuentasCobrarRemoteDataSource(this._dioClient);

  Future<List<CuentaCobrarModel>> listar({String? estado, String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (estado != null) queryParams['estado'] = estado;
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => CuentaCobrarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenCuentasCobrarModel> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return ResumenCuentasCobrarModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Registra un abono del cliente sobre una venta a crédito (CxC, simétrico a
  /// CxP). El backend valida saldo (rechaza sobre-pago), rutea el INGRESO a la
  /// fuente (Tesorería/Caja/Banco) e imputa en cascada a las cuotas
  /// (mora→interés→principal).
  Future<void> registrarAbono(
    String ventaId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? fuente,
    String? bancoId,
    String? banco,
  }) async {
    await _dioClient.post(
      '$_basePath/$ventaId/abono',
      data: {
        'metodoPago': metodoPago,
        'monto': monto,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
        if (fuente != null) 'fuente': fuente,
        if (bancoId != null && bancoId.isNotEmpty) 'bancoId': bancoId,
        if (banco != null && banco.isNotEmpty) 'banco': banco,
      },
    );
  }

  /// Anula un abono (revierte el ingreso en caja/banco y recomputa las cuotas).
  Future<void> anularAbono(String pagoId, {String? motivo}) async {
    await _dioClient.post(
      '$_basePath/pagos/$pagoId/anular',
      data: {if (motivo != null && motivo.isNotEmpty) 'motivo': motivo},
    );
  }

  /// Deuda por cobrar agrupada por cliente (vista "Por cliente").
  Future<List<dynamic>> getPorCliente() async {
    final response = await _dioClient.get('$_basePath/por-cliente');
    return response.data as List<dynamic>? ?? [];
  }

  /// Estado de cuenta de un cliente (ventas a crédito + abonos + saldo).
  Future<EstadoCuentaCliente> getEstadoCuentaCliente({
    String? clienteId,
    String? clienteEmpresaId,
  }) async {
    final qp = <String, dynamic>{};
    if (clienteId != null) qp['clienteId'] = clienteId;
    if (clienteEmpresaId != null) qp['clienteEmpresaId'] = clienteEmpresaId;
    final response = await _dioClient.get(
      '$_basePath/estado-cuenta-cliente',
      queryParameters: qp.isNotEmpty ? qp : null,
    );
    return EstadoCuentaCliente.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Depósitos del cliente sin repartir + saldo a favor ──

  Map<String, dynamic> _titular(String? clienteId, String? clienteEmpresaId) => {
        // Va UNO: lo personal y la empresa no se mezclan.
        if (clienteEmpresaId != null && clienteEmpresaId.isNotEmpty)
          'clienteEmpresaId': clienteEmpresaId
        else if (clienteId != null && clienteId.isNotEmpty)
          'clienteId': clienteId,
      };

  /// Cómo repartir `monto` entre las ventas con deuda del cliente (cuotas
  /// completas, la que vence primero). Con monto 0 devuelve la deuda y el
  /// saldo a favor que ya tenía.
  Future<SugerenciaReparto> sugerirReparto({
    String? clienteId,
    String? clienteEmpresaId,
    required double monto,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/depositos/sugerencia',
      queryParameters: {..._titular(clienteId, clienteEmpresaId), 'monto': monto},
    );
    return SugerenciaReparto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Registra el depósito (la plata entra UNA vez) y, si vienen líneas, lo
  /// reparte en el mismo acto. Lo que no se reparta queda a favor.
  Future<void> registrarDeposito({
    String? clienteId,
    String? clienteEmpresaId,
    required double monto,
    required String metodoPago,
    String? referencia,
    String? fuente,
    String? bancoId,
    List<LineaReparto> lineas = const [],
  }) async {
    await _dioClient.post(
      '$_basePath/depositos',
      data: {
        ..._titular(clienteId, clienteEmpresaId),
        'monto': monto,
        'metodoPago': metodoPago,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
        if (fuente != null) 'fuente': fuente,
        if (bancoId != null && bancoId.isNotEmpty) 'bancoId': bancoId,
        if (lineas.isNotEmpty) 'lineas': lineas.map((l) => l.toJson()).toList(),
      },
    );
  }

  /// Reparte el saldo a favor del cliente entre sus ventas.
  Future<void> aplicarSaldoAFavor({
    String? clienteId,
    String? clienteEmpresaId,
    required List<LineaReparto> lineas,
  }) async {
    await _dioClient.post(
      '$_basePath/depositos/aplicar',
      data: {
        ..._titular(clienteId, clienteEmpresaId),
        'lineas': lineas.map((l) => l.toJson()).toList(),
      },
    );
  }
}

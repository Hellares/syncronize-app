import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText;

class ConciliacionPage extends StatefulWidget {
  final String cuentaId;
  final String cuentaNombre;

  const ConciliacionPage({
    super.key,
    required this.cuentaId,
    required this.cuentaNombre,
  });

  @override
  State<ConciliacionPage> createState() => _ConciliacionPageState();
}

class _ConciliacionPageState extends State<ConciliacionPage> {
  final _dio = locator<DioClient>();
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

  bool _isLoading = true;
  Map<String, dynamic>? _cuenta;
  Map<String, dynamic>? _movimientosSistema;
  Map<String, dynamic>? _conciliacion;
  List<Map<String, dynamic>> _movimientos = [];

  late DateTime _fechaDesde;
  late DateTime _fechaHasta;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaDesde = DateTime(now.year, now.month, 1);
    _fechaHasta = now;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '/empresa-banco/${widget.cuentaId}/conciliacion',
        queryParameters: {
          'fechaDesde': DateFormat('yyyy-MM-dd').format(_fechaDesde),
          'fechaHasta': DateFormat('yyyy-MM-dd').format(_fechaHasta),
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _cuenta = data['cuenta'] as Map<String, dynamic>?;
          _movimientosSistema = data['movimientosSistema'] as Map<String, dynamic>?;
          _conciliacion = data['conciliacion'] as Map<String, dynamic>?;
          _movimientos = List<Map<String, dynamic>>.from(
            (data['movimientos'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaDesde, end: _fechaHasta),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.blue1,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.blue3,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaDesde = picked.start;
        _fechaHasta = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Conciliacion Bancaria',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, size: 20),
            onPressed: _pickDateRange,
            tooltip: 'Cambiar rango de fechas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 10),
                    _buildDateRangeChip(),
                    const SizedBox(height: 10),
                    _buildConciliacionCard(),
                    const SizedBox(height: 10),
                    _buildMovimientosSistemaCard(),
                    const SizedBox(height: 14),
                    _buildMovimientosHeader(),
                    const SizedBox(height: 8),
                    if (_movimientos.isEmpty)
                      _buildEmptyMovimientos()
                    else
                      ..._movimientos.map(_buildMovimientoTile),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEADER CARD — Bank name, account number, moneda, saldo
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeaderCard() {
    final nombreBanco = _cuenta?['nombreBanco'] as String? ?? widget.cuentaNombre;
    final numeroCuenta = _cuenta?['numeroCuenta'] as String? ?? '-';
    final moneda = _cuenta?['moneda'] as String? ?? 'PEN';
    final saldoActual = _parseDecimal(_cuenta?['saldoActual']);

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance, color: AppColors.blue1, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreBanco,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cuenta: $numeroCuenta',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Moneda: $moneda',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Saldo actual', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(
                _currencyFormat.format(saldoActual),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.blue3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DATE RANGE CHIP
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDateRangeChip() {
    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('dd/MM/yyyy').format(_fechaDesde)} — ${DateFormat('dd/MM/yyyy').format(_fechaHasta)}',
              style: TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 12, color: AppColors.blue1.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONCILIACION SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildConciliacionCard() {
    final saldoBanco = _parseDecimal(_conciliacion?['saldoBanco']);
    final saldoSistema = _parseDecimal(_conciliacion?['saldoSistema']);
    final diferencia = _parseDecimal(_conciliacion?['diferencia']);
    final conciliado = _conciliacion?['conciliado'] == true;

    final diferenciaAbs = diferencia.abs();
    final matchPercentage = saldoBanco != 0
        ? ((1 - (diferenciaAbs / saldoBanco.abs())).clamp(0.0, 1.0))
        : (conciliado ? 1.0 : 0.0);

    return GradientContainer(
      borderColor: conciliado ? AppColors.green.withValues(alpha: 0.4) : AppColors.red.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conciliado ? Icons.check_circle : Icons.warning_amber_rounded,
                color: conciliado ? AppColors.green : AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              AppSubtitle('Resultado de Conciliacion', fontSize: 13, color: AppColors.blue3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: conciliado
                      ? AppColors.green.withValues(alpha: 0.1)
                      : AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conciliado ? 'Conciliado' : 'Diferencia',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: conciliado ? AppColors.green : AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Saldo banco vs saldo sistema
          Row(
            children: [
              Expanded(
                child: _buildSaldoColumn(
                  label: 'Saldo Banco',
                  value: _currencyFormat.format(saldoBanco),
                  icon: Icons.account_balance,
                  color: AppColors.blue1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text('vs', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Icon(Icons.compare_arrows, size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ),
              Expanded(
                child: _buildSaldoColumn(
                  label: 'Saldo Sistema',
                  value: _currencyFormat.format(saldoSistema),
                  icon: Icons.computer,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Diferencia highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: conciliado
                  ? AppColors.green.withValues(alpha: 0.06)
                  : AppColors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: conciliado
                    ? AppColors.green.withValues(alpha: 0.2)
                    : AppColors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Diferencia: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text(
                  _currencyFormat.format(diferencia),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: conciliado ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Match percentage indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Porcentaje de coincidencia',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: matchPercentage,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          matchPercentage >= 1.0
                              ? AppColors.green
                              : matchPercentage >= 0.9
                                  ? AppColors.orange
                                  : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (matchPercentage >= 1.0 ? AppColors.green : matchPercentage >= 0.9 ? AppColors.orange : AppColors.red)
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: (matchPercentage >= 1.0 ? AppColors.green : matchPercentage >= 0.9 ? AppColors.orange : AppColors.red)
                        .withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(matchPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: matchPercentage >= 1.0
                          ? AppColors.green
                          : matchPercentage >= 0.9
                              ? AppColors.orange
                              : AppColors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOVIMIENTOS SISTEMA SUMMARY
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMovimientosSistemaCard() {
    final cantidad = _movimientosSistema?['cantidad'] ?? 0;
    final totalIngresos = _parseDecimal(_movimientosSistema?['totalIngresos']);
    final totalEgresos = _parseDecimal(_movimientosSistema?['totalEgresos']);
    final saldoSistema = _parseDecimal(_movimientosSistema?['saldoSistema']);

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_vert, size: 18, color: AppColors.blue1),
              const SizedBox(width: 8),
              AppSubtitle('Movimientos del Sistema', fontSize: 12, color: AppColors.blue3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cantidad movimientos',
                  style: TextStyle(fontSize: 9, color: AppColors.blue1, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMontoChip(
                  label: 'Ingresos',
                  value: _currencyFormat.format(totalIngresos),
                  color: AppColors.green,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMontoChip(
                  label: 'Egresos',
                  value: _currencyFormat.format(totalEgresos),
                  color: AppColors.red,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMontoChip(
                  label: 'Saldo',
                  value: _currencyFormat.format(saldoSistema),
                  color: AppColors.blue3,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMontoChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOVIMIENTOS LIST
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMovimientosHeader() {
    return Row(
      children: [
        Icon(Icons.list_alt, size: 18, color: AppColors.blue1),
        const SizedBox(width: 8),
        AppSubtitle('Detalle de Movimientos', fontSize: 12, color: AppColors.blue3),
        const Spacer(),
        Text(
          '${_movimientos.length} registros',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildEmptyMovimientos() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              'No hay movimientos en este periodo',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Cambia el rango de fechas para ver resultados',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientoTile(Map<String, dynamic> mov) {
    final tipo = mov['tipo'] as String? ?? '';
    final descripcion = mov['descripcion'] as String? ?? mov['concepto'] as String? ?? '-';
    final monto = _parseDecimal(mov['monto']);
    final fecha = mov['fecha'] as String? ?? mov['createdAt'] as String?;
    final referencia = mov['referencia'] as String?;
    final isIngreso = tipo.toUpperCase() == 'INGRESO' || tipo.toUpperCase() == 'CREDITO' || monto >= 0;

    final montoDisplay = monto.abs();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (isIngreso ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: isIngreso ? AppColors.green : AppColors.red,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descripcion,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (fecha != null) ...[
                        Icon(Icons.access_time, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          _formatDateTime(fecha),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        ),
                      ],
                      if (referencia != null && referencia.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.tag, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            referencia,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '${isIngreso ? '+' : '-'} ${_currencyFormat.format(montoDisplay)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isIngreso ? AppColors.green : AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

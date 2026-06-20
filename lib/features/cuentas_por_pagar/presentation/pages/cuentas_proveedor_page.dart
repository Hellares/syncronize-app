import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../bloc/cuentas_pagar_state.dart';
import 'cuenta_pagar_detalle_page.dart';

/// Todas las compras a crédito (con saldo) de UN proveedor + el total adeudado.
/// Las compras se muestran en una tabla estilo Excel (header sticky + scroll
/// horizontal sincronizado), igual que la verificación de precios.
class CuentasProveedorPage extends StatelessWidget {
  final String proveedorId;
  final String nombreProveedor;

  const CuentasProveedorPage({
    super.key,
    required this.proveedorId,
    required this.nombreProveedor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CuentasPagarCubit>()..loadCuentas(proveedorId: proveedorId),
      child: _CuentasProveedorView(nombreProveedor: nombreProveedor),
    );
  }
}

class _CuentasProveedorView extends StatefulWidget {
  final String nombreProveedor;
  const _CuentasProveedorView({required this.nombreProveedor});

  @override
  State<_CuentasProveedorView> createState() => _CuentasProveedorViewState();
}

class _CuentasProveedorViewState extends State<_CuentasProveedorView> {
  // Scroll horizontal sincronizado entre header sticky y body (igual patrón
  // que verificacion_precios_page).
  final ScrollController _headerHCtrl = ScrollController();
  final ScrollController _bodyHCtrl = ScrollController();
  bool _syncingScroll = false;

  // Anchos fijos por columna. Header y filas usan los mismos.
  static const double _wCodigo = 110;
  static const double _wDoc = 95;
  static const double _wEstado = 78;
  static const double _wCompra = 72;
  static const double _wVence = 72;
  static const double _wTotal = 80;
  static const double _wPagado = 80;
  static const double _wSaldo = 86;
  static const double _rowH = 38;

  static final Color _bgTotalH = Colors.blue.shade100;
  static final Color _bgPagadoH = Colors.green.shade100;
  static final Color _bgSaldoH = Colors.orange.shade100;
  static final Color _bgTotal = Colors.blue.shade50;
  static final Color _bgPagado = Colors.green.shade50;
  static final Color _bgSaldo = Colors.orange.shade50;

  double get _totalWidth =>
      _wCodigo + _wDoc + _wEstado + _wCompra + _wVence + _wTotal + _wPagado + _wSaldo;

  @override
  void initState() {
    super.initState();
    _headerHCtrl.addListener(() => _syncH(_headerHCtrl, _bodyHCtrl));
    _bodyHCtrl.addListener(() => _syncH(_bodyHCtrl, _headerHCtrl));
  }

  void _syncH(ScrollController src, ScrollController dst) {
    if (_syncingScroll || !dst.hasClients || src.offset == dst.offset) return;
    _syncingScroll = true;
    dst.jumpTo(src.offset);
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: widget.nombreProveedor,
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<CuentasPagarCubit, CuentasPagarState>(
          builder: (context, state) {
            if (state is CuentasPagarLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CuentasPagarError) {
              return Center(child: Text(state.message));
            }
            if (state is CuentasPagarLoaded) {
              final pendientes = state.cuentas.where((c) => c.estado != 'PAGADA').toList();
              final vencidas = pendientes.where((c) => c.estado == 'VENCIDA').toList();
              final totalVencido = vencidas.fold<double>(0, (s, c) => s + c.saldoPendiente);
              // Deuda separada por moneda (no se suman PEN y USD juntos).
              final deudaPorMoneda = <String, double>{};
              for (final c in pendientes) {
                deudaPorMoneda[c.moneda] = (deudaPorMoneda[c.moneda] ?? 0) + c.saldoPendiente;
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildHeader(deudaPorMoneda, totalVencido, pendientes.length, vencidas.length),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: state.cuentas.isEmpty
                        ? _emptyState()
                        : _buildTabla(context, state.cuentas),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
          const SizedBox(height: 12),
          Text('Sin deudas con este proveedor', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, double> deudaPorMoneda, double totalVencido, int compras, int vencidas) {
    // Una línea de total por moneda (ej "S/ 200.00" y "$ 15.00" si hay ambas).
    final entradas = deudaPorMoneda.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return GradientContainer(
      borderColor: totalVencido > 0 ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('Total que debes', fontSize: 12, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            if (entradas.isEmpty)
              AppTitle('S/ 0.00', fontSize: 24, color: Colors.red)
            else
              Wrap(
                spacing: 14,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: entradas
                    .map((e) => AppTitle('${simboloMoneda(e.key)} ${e.value.toStringAsFixed(2)}',
                        fontSize: 20, color: Colors.red))
                    .toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(Icons.receipt_long, '$compras compra${compras != 1 ? 's' : ''}', AppColors.blue1),
                const SizedBox(width: 8),
                if (vencidas > 0)
                  _chip(Icons.warning_amber_rounded, '$vencidas vencida${vencidas != 1 ? 's' : ''}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(texto, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTabla(BuildContext context, List<CuentaPorPagar> cuentas) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${cuentas.length} compra(s) · tocá una fila para ver el detalle',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHCtrl,
            physics: const ClampingScrollPhysics(),
            child: _buildHeaderRow(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _bodyHCtrl,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: _totalWidth,
                child: ListView.builder(
                  itemCount: cuentas.length,
                  itemExtent: _rowH,
                  itemBuilder: (_, i) => _buildItemRow(context, cuentas[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final s = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue1);
    return Container(
      width: _totalWidth,
      height: _rowH,
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(
        children: [
          _hCell('Código', _wCodigo, s),
          _hCell('Documento', _wDoc, s),
          _hCell('Estado', _wEstado, s),
          _hCell('Compra', _wCompra, s),
          _hCell('Vence', _wVence, s),
          _hCell('Total', _wTotal, s, alignRight: true, bgColor: _bgTotalH),
          _hCell('Pagado', _wPagado, s, alignRight: true, bgColor: _bgPagadoH),
          _hCell('Saldo', _wSaldo, s, alignRight: true, bgColor: _bgSaldoH),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width, TextStyle s, {bool alignRight = false, Color? bgColor}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(text, style: s),
        ),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, CuentaPorPagar c) {
    Color estadoColor;
    String estadoLabel;
    switch (c.estado) {
      case 'VENCIDA':
        estadoColor = Colors.red;
        estadoLabel = 'Vencida';
        break;
      case 'PAGADA':
        estadoColor = Colors.green;
        estadoLabel = 'Pagada';
        break;
      default:
        estadoColor = Colors.orange;
        estadoLabel = 'Pendiente';
    }
    const ts = TextStyle(fontSize: 10);
    final cubit = context.read<CuentasPagarCubit>();

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CuentaPagarDetallePage(compraId: c.id, cubit: cubit),
        ),
      ),
      child: Container(
        width: _totalWidth,
        height: _rowH,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        ),
        child: Row(
          children: [
            _dCell(c.codigo, _wCodigo, ts.copyWith(color: AppColors.blue1, fontWeight: FontWeight.w600), ellipsis: true),
            _dCell(c.documentoCompra ?? '—', _wDoc, ts, ellipsis: true),
            _dCell(estadoLabel, _wEstado, ts.copyWith(color: estadoColor, fontWeight: FontWeight.w600)),
            _dCell(c.fechaCompra != null ? DateFormatter.formatDateShort(c.fechaCompra!) : '—', _wCompra, ts),
            _dCell(c.fechaVencimiento != null ? DateFormatter.formatDateShort(c.fechaVencimiento!) : '—', _wVence, ts,
                color: c.estado == 'VENCIDA' ? Colors.red : null),
            _dCell('${c.simbolo} ${c.totalCompra.toStringAsFixed(2)}', _wTotal, ts, alignRight: true, bgColor: _bgTotal),
            _dCell('${c.simbolo} ${c.totalPagado.toStringAsFixed(2)}', _wPagado, ts, alignRight: true, bgColor: _bgPagado),
            _dCell('${c.simbolo} ${c.saldoPendiente.toStringAsFixed(2)}', _wSaldo,
                ts.copyWith(color: estadoColor, fontWeight: FontWeight.bold),
                alignRight: true, bgColor: _bgSaldo),
          ],
        ),
      ),
    );
  }

  Widget _dCell(String text, double width, TextStyle s,
      {bool alignRight = false, bool ellipsis = false, Color? bgColor, Color? color}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: color != null ? s.copyWith(color: color) : s,
            overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

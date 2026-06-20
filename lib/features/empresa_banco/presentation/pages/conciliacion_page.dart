import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/empresa_banco_remote_datasource.dart';

String _sim(String? m) {
  switch ((m ?? 'PEN').toUpperCase()) {
    case 'USD':
      return '\$';
    case 'PEN':
      return 'S/';
    default:
      return '${(m ?? '').toUpperCase()} ';
  }
}

/// Estado de cuenta REAL de un banco (conciliación por banco): saldo del
/// sistema + los movimientos que tocaron esta cuenta (recaudación que entró,
/// pagos que salieron, ajustes), y las acciones para conciliar/ajustar.
class ConciliacionPage extends StatefulWidget {
  final String cuentaId;
  final String cuentaNombre;

  const ConciliacionPage({super.key, required this.cuentaId, required this.cuentaNombre});

  @override
  State<ConciliacionPage> createState() => _ConciliacionPageState();
}

class _ConciliacionPageState extends State<ConciliacionPage> {
  final _ds = locator<EmpresaBancoRemoteDataSource>();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final desde = DateTime(now.year, now.month, 1);
      final res = await locator<DioClient>().get(
        '/empresa-banco/${widget.cuentaId}/estado-cuenta',
        queryParameters: {
          'fechaDesde': desde.toIso8601String().split('T').first,
          'fechaHasta': now.toIso8601String().split('T').first,
        },
      );
      if (!mounted) return;
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar: $e';
          _loading = false;
        });
      }
    }
  }

  double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Estado de cuenta',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: AppColors.blue1,
                    child: ListView(padding: const EdgeInsets.all(12), children: _contenido()),
                  ),
      ),
    );
  }

  List<Widget> _contenido() {
    final data = _data!;
    final cuenta = data['cuenta'] as Map<String, dynamic>? ?? {};
    final resumen = data['resumen'] as Map<String, dynamic>? ?? {};
    final movs = (data['movimientos'] as List<dynamic>? ?? []);
    final moneda = cuenta['moneda']?.toString() ?? 'PEN';
    final saldo = _d(cuenta['saldoActual']);

    return [
      // Saldo + acciones
      GradientContainer(
        borderColor: AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle(cuenta['nombreBanco']?.toString() ?? widget.cuentaNombre, fontSize: 13, color: AppColors.blue1),
              Text('${cuenta['numeroCuenta'] ?? ''} · $moneda', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              const AppSubtitle('Saldo del sistema', fontSize: 11, color: AppColors.blueGrey),
              AppTitle('${_sim(moneda)} ${saldo.toStringAsFixed(2)}', fontSize: 24, color: AppColors.blue1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _accion(Icons.fact_check, 'Conciliar', () => _conciliar(saldo, moneda))),
                  const SizedBox(width: 8),
                  Expanded(child: _accion(Icons.tune, 'Ajuste', _ajuste)),
                  const SizedBox(width: 8),
                  Expanded(child: _accion(Icons.history, 'Ajustes', _historial)),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      // Resumen del período
      Row(
        children: [
          Expanded(child: _miniResumen('Ingresos', _d(resumen['totalIngresos']), Colors.green, moneda)),
          const SizedBox(width: 8),
          Expanded(child: _miniResumen('Egresos', _d(resumen['totalEgresos']), Colors.red, moneda)),
          const SizedBox(width: 8),
          Expanded(child: _miniResumen('Neto', _d(resumen['neto']), AppColors.blue1, moneda)),
        ],
      ),
      const SizedBox(height: 10),
      AppSubtitle('Movimientos del mes (${movs.length})', fontSize: 12, color: AppColors.blue1),
      const SizedBox(height: 6),
      if (movs.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text('Sin movimientos en el período', style: TextStyle(color: Colors.grey.shade500))),
        )
      else
        ...movs.map((m) => _movTile(m as Map<String, dynamic>, moneda)),
      const SizedBox(height: 20),
    ];
  }

  Widget _accion(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue1,
        side: const BorderSide(color: AppColors.blueborder),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _miniResumen(String label, double monto, Color color, String moneda) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${_sim(moneda)} ${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _movTile(Map<String, dynamic> m, String moneda) {
    final esIngreso = m['tipo']?.toString() == 'INGRESO';
    final monto = _d(m['monto']);
    final fecha = m['fecha'] != null ? DateTime.tryParse(m['fecha'].toString()) : null;
    final detalle = m['detalle']?.toString();
    IconData icon;
    switch (m['origen']?.toString()) {
      case 'RECAUDACION':
        icon = Icons.smartphone;
        break;
      case 'PAGO_PROVEEDOR':
        icon = Icons.local_shipping;
        break;
      case 'PAGO_GASTO':
        icon = Icons.receipt_long;
        break;
      case 'CONCILIACION':
        icon = Icons.fact_check;
        break;
      default:
        icon = Icons.tune;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: esIngreso ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['concepto']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                if (detalle != null && detalle.isNotEmpty)
                  Text(detalle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (fecha != null)
                  Text(DateFormatter.formatDate(fecha), style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('${esIngreso ? '+' : '-'}${_sim(moneda)} ${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: esIngreso ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  // ───── Acciones ─────

  Future<void> _conciliar(double saldoActual, String moneda) async {
    final ctrl = TextEditingController(text: saldoActual.toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conciliar con extracto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresá el saldo REAL del extracto. La diferencia con el sistema (${_sim(moneda)} ${saldoActual.toStringAsFixed(2)}) queda registrada como conciliación.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            CustomText(controller: ctrl, label: 'Saldo del extracto', hintText: '0.00', borderColor: AppColors.blue1, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
            child: const Text('Conciliar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final saldo = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
    try {
      await _ds.actualizarSaldo(id: widget.cuentaId, saldo: saldo);
      await _cargar();
      if (mounted) _snack('Conciliado', ok: true);
    } catch (e) {
      if (mounted) _snack('No se pudo conciliar: $e');
    }
  }

  Future<void> _ajuste() async {
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    String tipo = 'EGRESO';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Ajuste de saldo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomDropdown<String>(
                label: 'Tipo',
                value: tipo,
                borderColor: AppColors.blue1,
                items: const [
                  DropdownItem(value: 'EGRESO', label: 'Resta (comisión, retiro…)'),
                  DropdownItem(value: 'INGRESO', label: 'Suma (interés, depósito…)'),
                ],
                onChanged: (v) => setSt(() => tipo = v ?? 'EGRESO'),
              ),
              const SizedBox(height: 10),
              CustomText(controller: montoCtrl, label: 'Monto', hintText: '0.00', borderColor: AppColors.blue1, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              CustomText(controller: motivoCtrl, label: 'Motivo', hintText: 'Ej: comisión', borderColor: AppColors.blue1),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
    final motivo = motivoCtrl.text.trim();
    if (monto <= 0 || motivo.isEmpty) {
      _snack('Ingresá monto (> 0) y motivo');
      return;
    }
    try {
      await _ds.ajustar(id: widget.cuentaId, tipo: tipo, monto: monto, motivo: motivo);
      await _cargar();
      if (mounted) _snack('Ajuste registrado', ok: true);
    } catch (e) {
      if (mounted) _snack('No se pudo: $e');
    }
  }

  Future<void> _historial() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => FutureBuilder<List<Map<String, dynamic>>>(
          future: _ds.getAjustes(id: widget.cuentaId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }
            final ajustes = snap.data ?? [];
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: AppSubtitle('Ajustes / conciliaciones', fontSize: 14, color: AppColors.blue1)),
                const SizedBox(height: 12),
                if (ajustes.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Sin ajustes registrados', style: TextStyle(color: Colors.grey.shade500))))
                else
                  ...ajustes.map((a) {
                    final esIngreso = a['tipo']?.toString() == 'INGRESO';
                    final monto = _d(a['monto']);
                    final origen = a['origen']?.toString() == 'CONCILIACION' ? 'Conciliación' : 'Ajuste';
                    final ant = _d(a['saldoAnterior']);
                    final nue = _d(a['saldoNuevo']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          Icon(esIngreso ? Icons.add_circle : Icons.remove_circle, size: 18, color: esIngreso ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$origen · ${a['motivo'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('${ant.toStringAsFixed(2)} → ${nue.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text('${esIngreso ? '+' : '-'}${monto.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: esIngreso ? Colors.green : Colors.red)),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : null));
  }
}

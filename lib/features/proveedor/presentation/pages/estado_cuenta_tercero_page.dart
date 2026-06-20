import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../cuentas_por_pagar/presentation/bloc/cuentas_pagar_cubit.dart';
import '../../../cuentas_por_pagar/presentation/pages/cuenta_pagar_detalle_page.dart';
import '../../data/datasources/proveedor_remote_datasource.dart';

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

/// Estado de cuenta del TERCERO (proveedor que también es cliente): lo que le
/// debo (compras), lo que me debe (ventas) y el NETO por moneda + movimientos.
class EstadoCuentaTerceroPage extends StatefulWidget {
  final String empresaId;
  final String proveedorId;
  final String proveedorNombre;

  const EstadoCuentaTerceroPage({
    super.key,
    required this.empresaId,
    required this.proveedorId,
    required this.proveedorNombre,
  });

  @override
  State<EstadoCuentaTerceroPage> createState() => _EstadoCuentaTerceroPageState();
}

class _EstadoCuentaTerceroPageState extends State<EstadoCuentaTerceroPage> {
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
      final d = await locator<ProveedorRemoteDataSource>().estadoCuentaTercero(
        empresaId: widget.empresaId,
        proveedorId: widget.proveedorId,
      );
      if (!mounted) return;
      setState(() {
        _data = d;
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
  Map<String, dynamic> _map(dynamic v) => (v as Map<String, dynamic>?) ?? {};

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
    final leDebo = _map(data['leDeboPorMoneda']);
    final meDebe = _map(data['meDebePorMoneda']);
    final neto = _map(data['netoPorMoneda']);
    final esTercero = data['esTercero'] == true;
    final movs = (data['movimientos'] as List<dynamic>? ?? []);

    return [
      // Neto por moneda
      GradientContainer(
        borderColor: AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle(widget.proveedorNombre, fontSize: 13, color: AppColors.blue1),
              const SizedBox(height: 2),
              const AppSubtitle('Saldo neto', fontSize: 11, color: AppColors.blueGrey),
              const SizedBox(height: 4),
              if (neto.isEmpty)
                const AppTitle('Sin saldos', fontSize: 16, color: AppColors.blueGrey)
              else
                ...neto.entries.map((e) => _netoLinea(e.key, _d(e.value))),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      // Le debo / Me debe
      Row(
        children: [
          Expanded(child: _ladoCard('Le debo (compras)', leDebo, AppColors.red, Icons.south_west_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _ladoCard('Me debe (ventas)', meDebe, AppColors.green, Icons.north_east_rounded)),
        ],
      ),
      if (!esTercero) ...[
        const SizedBox(height: 8),
        Text(
          'Este proveedor todavía no está registrado como cliente, por eso "Me debe" está vacío. Registralo desde su ficha para sumar las ventas.',
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
        ),
      ],
      const SizedBox(height: 12),
      const AppSubtitle('Movimientos', fontSize: 13, color: AppColors.blue1),
      const SizedBox(height: 4),
      if (movs.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Sin compras ni ventas registradas.')),
        )
      else
        ...movs.map((m) => _movTile(m as Map<String, dynamic>)),
      const SizedBox(height: 20),
    ];
  }

  Widget _netoLinea(String moneda, double monto) {
    final String texto;
    final Color color;
    if (monto.abs() < 0.01) {
      texto = '${_sim(moneda)} 0.00 · saldado';
      color = AppColors.blueGrey;
    } else if (monto > 0) {
      texto = 'Le debés ${_sim(moneda)} ${monto.toStringAsFixed(2)}';
      color = AppColors.red;
    } else {
      texto = 'Te debe ${_sim(moneda)} ${(-monto).toStringAsFixed(2)}';
      color = AppColors.green;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AppTitle(texto, fontSize: 18, color: color),
    );
  }

  Widget _ladoCard(String label, Map<String, dynamic> porMoneda, Color color, IconData icon) {
    final entradas = porMoneda.entries.where((e) => _d(e.value).abs() > 0.001).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 6),
          if (entradas.isEmpty)
            Text('—', style: TextStyle(fontSize: 14, color: Colors.grey.shade500))
          else
            ...entradas.map((e) => Text(
                  '${_sim(e.key)} ${_d(e.value).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                )),
        ],
      ),
    );
  }

  String _fmtCant(double c) =>
      c == c.roundToDouble() ? c.toStringAsFixed(0) : c.toStringAsFixed(2);

  Widget _movTile(Map<String, dynamic> m) {
    final esCompra = m['tipo'] == 'COMPRA';
    final color = esCompra ? AppColors.red : AppColors.green;
    final fecha = m['fecha'] != null ? DateTime.tryParse(m['fecha'].toString()) : null;
    final saldo = _d(m['saldoPendiente']);
    final estado = m['estado']?.toString() ?? '';
    final moneda = m['moneda']?.toString();
    final items = (m['items'] as List<dynamic>? ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blueborder.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(esCompra ? Icons.shopping_cart_rounded : Icons.sell_rounded, size: 15, color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text('${esCompra ? 'Compra' : 'Venta'} · ${m['codigo'] ?? ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Text('${_sim(moneda)} ${_d(m['total']).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          subtitle: Text(
            '${fecha != null ? DateFormatter.formatDate(fecha) : ''}  ·  $estado'
            '${saldo > 0.001 ? '  ·  saldo ${_sim(moneda)} ${saldo.toStringAsFixed(2)}' : ''}',
            style: TextStyle(fontSize: 10, color: saldo > 0.001 ? color : Colors.grey.shade600),
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Sin ítems', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              )
            else
              ...items.map((it) {
                final i = it as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${_fmtCant(_d(i['cantidad']))} × ${i['descripcion']}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                      Text('${_sim(moneda)} ${_d(i['total']).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _verDetalle(m),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(esCompra ? 'Ver compra' : 'Ver venta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verDetalle(Map<String, dynamic> m) {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (m['tipo'] == 'VENTA') {
      context.push('/empresa/ventas/$id');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CuentaPagarDetallePage(
            compraId: id,
            cubit: locator<CuentasPagarCubit>(),
          ),
        ),
      );
    }
  }
}

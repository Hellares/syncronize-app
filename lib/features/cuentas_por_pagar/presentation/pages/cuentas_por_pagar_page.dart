import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';

class CuentasPorPagarPage extends StatefulWidget {
  const CuentasPorPagarPage({super.key});

  @override
  State<CuentasPorPagarPage> createState() => _CuentasPorPagarPageState();
}

class _CuentasPorPagarPageState extends State<CuentasPorPagarPage> {
  List<dynamic> _cuentas = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dio = locator<DioClient>();
      String url = '/cuentas-por-pagar';
      if (_filtroEstado != null) url += '?estado=$_filtroEstado';

      final responses = await Future.wait([
        dio.get(url),
        dio.get('/cuentas-por-pagar/resumen'),
      ]);

      if (mounted) {
        setState(() {
          _cuentas = responses[0].data as List<dynamic>? ?? [];
          _resumen = responses[1].data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(title: 'Cuentas por Pagar', backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_resumen != null) _buildResumen(),
                    const SizedBox(height: 12),
                    _buildFiltros(),
                    const SizedBox(height: 8),
                    if (_cuentas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
                              const SizedBox(height: 12),
                              Text('No hay cuentas pendientes', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._cuentas.map((c) => _CuentaCard(cuenta: c as Map<String, dynamic>)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResumen() {
    final pendiente = (_resumen!['totalPendiente'] as num?)?.toDouble() ?? 0;
    final vencido = (_resumen!['totalVencido'] as num?)?.toDouble() ?? 0;
    final cantPendientes = _resumen!['cantidadPendientes'] as int? ?? 0;
    final cantVencidas = _resumen!['cantidadVencidas'] as int? ?? 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _ResumenItem(label: 'Pendiente', monto: pendiente, cantidad: cantPendientes, color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _ResumenItem(label: 'Vencido', monto: vencido, cantidad: cantVencidas, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppSubtitle('Total por pagar', fontSize: 13),
                AppSubtitle('S/ ${(pendiente + vencido).toStringAsFixed(2)}', fontSize: 16, color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = [
      {'label': 'Todos', 'value': null},
      {'label': 'Pendientes', 'value': 'PENDIENTE'},
      {'label': 'Vencidas', 'value': 'VENCIDA'},
      {'label': 'Pagadas', 'value': 'PAGADA'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((f) {
          final isSelected = _filtroEstado == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.blue1)),
              selected: isSelected, selectedColor: AppColors.blue1, backgroundColor: Colors.white, checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? AppColors.blue1 : Colors.grey.shade300),
              onSelected: (_) {
                setState(() => _filtroEstado = f['value'] as String?);
                _load();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final double monto;
  final int cantidad;
  final Color color;
  const _ResumenItem({required this.label, required this.monto, required this.cantidad, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('S/ ${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text('$cantidad cuenta${cantidad != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _CuentaCard extends StatelessWidget {
  final Map<String, dynamic> cuenta;
  const _CuentaCard({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final codigo = cuenta['codigo'] as String? ?? '';
    final proveedor = cuenta['nombreProveedor'] as String? ?? '';
    final saldo = (cuenta['saldoPendiente'] as num?)?.toDouble() ?? 0;
    final total = (cuenta['totalCompra'] as num?)?.toDouble() ?? 0;
    final estado = cuenta['estado'] as String? ?? '';
    final dias = cuenta['diasVencimiento'] as int?;
    final fechaVenc = cuenta['fechaVencimiento'] != null ? DateTime.tryParse(cuenta['fechaVencimiento'].toString()) : null;
    final banco = cuenta['bancoPrincipal'] as Map<String, dynamic>?;

    Color estadoColor;
    String estadoLabel;
    switch (estado) {
      case 'VENCIDA': estadoColor = Colors.red; estadoLabel = 'Vencida'; break;
      case 'PAGADA': estadoColor = Colors.green; estadoLabel = 'Pagada'; break;
      default: estadoColor = Colors.orange; estadoLabel = 'Pendiente';
    }

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: estado == 'VENCIDA' ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSubtitle(codigo, fontSize: 13, color: AppColors.blue1),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(estadoLabel, style: TextStyle(fontSize: 10, color: estadoColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: AppSubtitle(proveedor, fontSize: 12)),
              ],
            ),
            if (banco != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.account_balance, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text('${banco['nombreBanco']} - ${banco['numeroCuenta']}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Total: S/ ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const Spacer(),
                AppSubtitle('Saldo: S/ ${saldo.toStringAsFixed(2)}', fontSize: 13, color: estadoColor),
              ],
            ),
            if (fechaVenc != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event, size: 13, color: estado == 'VENCIDA' ? Colors.red : Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(fechaVenc)}${dias != null ? ' (${dias > 0 ? 'en $dias días' : dias == 0 ? 'hoy' : '${dias.abs()} días atrás'})' : ''}',
                    style: TextStyle(fontSize: 10, color: estado == 'VENCIDA' ? Colors.red : Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

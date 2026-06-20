import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';

String _sim(String? moneda) {
  switch ((moneda ?? 'PEN').toUpperCase()) {
    case 'USD':
      return '\$';
    case 'PEN':
      return 'S/';
    default:
      return '${(moneda ?? '').toUpperCase()} ';
  }
}

String _metodoLabel(String m) {
  switch (m) {
    case 'YAPE':
      return 'Yape';
    case 'PLIN':
      return 'Plin';
    case 'TARJETA':
      return 'Tarjeta';
    case 'TRANSFERENCIA':
      return 'Transferencia';
    default:
      return m;
  }
}

/// Vista consolidada de tesorería: bóveda(s) de efectivo + cuentas bancarias
/// con saldo y método que recaudan. El "dónde está mi plata".
class TesoreriaConsolidadoPage extends StatefulWidget {
  const TesoreriaConsolidadoPage({super.key});

  @override
  State<TesoreriaConsolidadoPage> createState() => _TesoreriaConsolidadoPageState();
}

class _TesoreriaConsolidadoPageState extends State<TesoreriaConsolidadoPage> {
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
      final res = await locator<DioClient>().get('/caja/tesoreria-consolidado');
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
        title: 'Tesorería · Consolidado',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
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
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: _buildContent(),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final data = _data!;
    final bovedas = (data['bovedas'] as List<dynamic>? ?? []);
    final bancos = (data['bancos'] as List<dynamic>? ?? []);
    final totalEfectivo = _d(data['totalEfectivo']);
    final totalDigHist = _d(data['totalDigitalHistorico']);
    final bancosPorMoneda = (data['bancosPorMoneda'] as Map<String, dynamic>? ?? {});

    return [
      // ── Bóveda (efectivo) ──
      _seccionTitulo(Icons.savings, 'Bóveda — Efectivo'),
      GradientContainer(
        borderColor: AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppSubtitle('Efectivo total en tesorería', fontSize: 12, color: AppColors.blueGrey),
                  AppTitle('S/ ${totalEfectivo.toStringAsFixed(2)}', fontSize: 20, color: AppColors.blue1),
                ],
              ),
              if (bovedas.length > 1) ...[
                const Divider(height: 16),
                ...bovedas.map((b) {
                  final m = b as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m['sedeNombre']?.toString() ?? 'Sede', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        Text('S/ ${_d(m['saldoEfectivo']).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
              if (totalDigHist > 0.001) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Digital histórico en tesorería: S/ ${totalDigHist.toStringAsFixed(2)} '
                    '(de cierres previos; lo nuevo ya entra a los bancos)',
                    style: TextStyle(fontSize: 10.5, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),

      // ── Bancos ──
      _seccionTitulo(Icons.account_balance, 'Bancos'),
      if (bancos.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('No hay cuentas bancarias activas.', style: TextStyle(color: Colors.grey.shade500)),
          ),
        )
      else ...[
        ...bancos.map((b) => _bancoCard(b as Map<String, dynamic>)),
        const SizedBox(height: 4),
        ...bancosPorMoneda.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total ${e.key}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  Text('${_sim(e.key)} ${_d(e.value).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blue1)),
                ],
              ),
            )),
      ],
      const SizedBox(height: 20),
    ];
  }

  Widget _seccionTitulo(IconData icon, String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blue1),
          const SizedBox(width: 6),
          AppSubtitle(t, fontSize: 13, color: AppColors.blue1),
        ],
      ),
    );
  }

  Widget _bancoCard(Map<String, dynamic> b) {
    final metodos = (b['metodos'] as List<dynamic>? ?? []).cast<String>();
    final moneda = b['moneda']?.toString() ?? 'PEN';
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                Expanded(
                  child: AppSubtitle(
                    '${b['nombreBanco'] ?? ''}${b['esPrincipal'] == true ? ' ★' : ''}',
                    fontSize: 13,
                    color: AppColors.blue1,
                  ),
                ),
                Text('${_sim(moneda)} ${_d(b['saldoActual']).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 2),
            Text('${b['numeroCuenta'] ?? ''} · $moneda', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
            if (metodos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: metodos
                    .map((m) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Recauda ${_metodoLabel(m)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

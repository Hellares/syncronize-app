import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText;

class EmpresaBancoPage extends StatefulWidget {
  const EmpresaBancoPage({super.key});

  @override
  State<EmpresaBancoPage> createState() => _EmpresaBancoPageState();
}

class _EmpresaBancoPageState extends State<EmpresaBancoPage> {
  List<dynamic> _cuentas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await locator<DioClient>().get('/empresa-banco');
      if (mounted) setState(() { _cuentas = response.data as List<dynamic>? ?? []; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(title: 'Cuentas Bancarias', backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCrearDialog,
        backgroundColor: AppColors.blue1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cuentas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No hay cuentas bancarias registradas', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 16),
                        CustomButton(text: 'Agregar cuenta', onPressed: _showCrearDialog, backgroundColor: AppColors.blue1, height: 40),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.blue1,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _cuentas.length,
                      itemBuilder: (context, index) {
                        final cuenta = _cuentas[index] as Map<String, dynamic>;
                        return _CuentaCard(
                          cuenta: cuenta,
                          onMarcarPrincipal: () => _marcarPrincipal(cuenta['id']),
                          onEliminar: () => _eliminar(cuenta['id']),
                          onActualizarSaldo: () => _showSaldoDialog(cuenta),
                          onConciliacion: () => context.push(
                            '/empresa/cuentas-bancarias/${cuenta['id']}/conciliacion',
                            extra: {'nombre': cuenta['nombreBanco']},
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  void _showCrearDialog() {
    final nombreBancoCtrl = TextEditingController();
    final numeroCuentaCtrl = TextEditingController();
    final cciCtrl = TextEditingController();
    final titularCtrl = TextEditingController();
    String tipoCuenta = 'AHORROS';
    String moneda = 'PEN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Cuenta Bancaria', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(controller: nombreBancoCtrl, label: 'Banco', hintText: 'Ej: BCP, Interbank', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tipoCuenta,
                  decoration: InputDecoration(labelText: 'Tipo de cuenta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(value: 'AHORROS', child: Text('Ahorros')),
                    DropdownMenuItem(value: 'CORRIENTE', child: Text('Corriente')),
                    DropdownMenuItem(value: 'INTERBANCARIA', child: Text('Interbancaria')),
                  ],
                  onChanged: (v) => setDialogState(() => tipoCuenta = v ?? 'AHORROS'),
                ),
                const SizedBox(height: 10),
                CustomText(controller: numeroCuentaCtrl, label: 'Número de cuenta', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                CustomText(controller: cciCtrl, label: 'CCI (opcional)', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                CustomText(controller: titularCtrl, label: 'Titular (opcional)', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: moneda,
                  decoration: InputDecoration(labelText: 'Moneda', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(value: 'PEN', child: Text('PEN - Soles')),
                    DropdownMenuItem(value: 'USD', child: Text('USD - Dólares')),
                  ],
                  onChanged: (v) => setDialogState(() => moneda = v ?? 'PEN'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreBancoCtrl.text.isEmpty || numeroCuentaCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                await locator<DioClient>().post('/empresa-banco', data: {
                  'nombreBanco': nombreBancoCtrl.text.trim(),
                  'tipoCuenta': tipoCuenta,
                  'numeroCuenta': numeroCuentaCtrl.text.trim(),
                  if (cciCtrl.text.isNotEmpty) 'cci': cciCtrl.text.trim(),
                  if (titularCtrl.text.isNotEmpty) 'titular': titularCtrl.text.trim(),
                  'moneda': moneda,
                });
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaldoDialog(dynamic cuenta) {
    final saldoCtrl = TextEditingController(text: cuenta['saldoActual']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar saldo - ${cuenta['nombreBanco']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: CustomText(controller: saldoCtrl, label: 'Saldo actual', hintText: '0.00', borderColor: AppColors.blue1, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final saldo = double.tryParse(saldoCtrl.text) ?? 0;
              await locator<DioClient>().patch('/empresa-banco/${cuenta['id']}/saldo', data: {'saldo': saldo});
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarPrincipal(String id) async {
    await locator<DioClient>().post('/empresa-banco/$id/principal');
    _load();
  }

  Future<void> _eliminar(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta', style: TextStyle(fontSize: 15)),
        content: const Text('¿Está seguro de eliminar esta cuenta bancaria?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await locator<DioClient>().delete('/empresa-banco/$id');
      _load();
    }
  }
}

class _CuentaCard extends StatelessWidget {
  final Map<String, dynamic> cuenta;
  final VoidCallback onMarcarPrincipal;
  final VoidCallback onEliminar;
  final VoidCallback onConciliacion;
  final VoidCallback onActualizarSaldo;

  const _CuentaCard({required this.cuenta, required this.onMarcarPrincipal, required this.onEliminar, required this.onActualizarSaldo, required this.onConciliacion});

  @override
  Widget build(BuildContext context) {
    final esPrincipal = cuenta['esPrincipal'] == true;
    final saldo = cuenta['saldoActual'] != null ? double.tryParse(cuenta['saldoActual'].toString()) : null;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: esPrincipal ? AppColors.blue1 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 20, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(child: AppSubtitle(cuenta['nombreBanco'] ?? '', fontSize: 14)),
                if (esPrincipal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Principal', style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'principal') onMarcarPrincipal();
                    if (v == 'saldo') onActualizarSaldo();
                    if (v == 'conciliacion') onConciliacion();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    if (!esPrincipal) const PopupMenuItem(value: 'principal', child: Text('Marcar como principal')),
                    const PopupMenuItem(value: 'saldo', child: Text('Actualizar saldo')),
                    const PopupMenuItem(value: 'conciliacion', child: Text('Conciliación')),
                    const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.credit_card, '${_tipoCuentaLabel(cuenta['tipoCuenta'])} - ${cuenta['moneda'] ?? 'PEN'}'),
            _infoRow(Icons.numbers, cuenta['numeroCuenta'] ?? ''),
            if (cuenta['cci'] != null && (cuenta['cci'] as String).isNotEmpty)
              _infoRow(Icons.swap_horiz, 'CCI: ${cuenta['cci']}'),
            if (cuenta['titular'] != null && (cuenta['titular'] as String).isNotEmpty)
              _infoRow(Icons.person_outline, cuenta['titular']),
            if (saldo != null) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saldo:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  AppSubtitle('${cuenta['moneda'] ?? 'S/'} ${saldo.toStringAsFixed(2)}',
                    fontSize: 16, color: saldo >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  String _tipoCuentaLabel(String? tipo) {
    switch (tipo) {
      case 'AHORROS': return 'Ahorros';
      case 'CORRIENTE': return 'Corriente';
      case 'INTERBANCARIA': return 'Interbancaria';
      default: return tipo ?? '';
    }
  }
}

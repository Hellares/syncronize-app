import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText;
import '../../data/datasources/empresa_banco_remote_datasource.dart';
import '../../domain/entities/empresa_banco.dart';
import '../bloc/empresa_banco_cubit.dart';
import '../bloc/empresa_banco_state.dart';

class EmpresaBancoPage extends StatelessWidget {
  const EmpresaBancoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<EmpresaBancoCubit>()..loadCuentas(),
      child: const _EmpresaBancoView(),
    );
  }
}

class _EmpresaBancoView extends StatelessWidget {
  const _EmpresaBancoView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmpresaBancoCubit>();

    return Scaffold(
      appBar: SmartAppBar(title: 'Cuentas Bancarias', backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCrearDialog(context, cubit),
        backgroundColor: AppColors.blue1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: BlocBuilder<EmpresaBancoCubit, EmpresaBancoState>(
          builder: (context, state) {
            if (state is EmpresaBancoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EmpresaBancoError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(state.message, style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    CustomButton(text: 'Reintentar', onPressed: () => cubit.loadCuentas(), backgroundColor: AppColors.blue1, height: 40),
                  ],
                ),
              );
            }
            if (state is EmpresaBancoLoaded) {
              final cuentas = state.cuentas;
              if (cuentas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_outlined, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No hay cuentas bancarias registradas', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      CustomButton(text: 'Agregar cuenta', onPressed: () => _showCrearDialog(context, cubit), backgroundColor: AppColors.blue1, height: 40),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => cubit.loadCuentas(),
                color: AppColors.blue1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cuentas.length,
                  itemBuilder: (context, index) {
                    final cuenta = cuentas[index];
                    return _CuentaCard(
                      cuenta: cuenta,
                      onMarcarPrincipal: () => cubit.marcarPrincipal(id: cuenta.id),
                      onEliminar: () => _eliminar(context, cubit, cuenta.id),
                      onActualizarSaldo: () => _showSaldoDialog(context, cubit, cuenta),
                      onAjuste: () => _showAjusteDialog(context, cubit, cuenta),
                      onHistorial: () => _showHistorialAjustes(context, cuenta),
                      onConciliacion: () => context.push(
                        '/empresa/cuentas-bancarias/${cuenta.id}/conciliacion',
                        extra: {'nombre': cuenta.nombreBanco},
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showCrearDialog(BuildContext context, EmpresaBancoCubit cubit) {
    final nombreBancoCtrl = TextEditingController();
    final numeroCuentaCtrl = TextEditingController();
    final cciCtrl = TextEditingController();
    final titularCtrl = TextEditingController();
    String tipoCuenta = 'AHORROS';
    String moneda = 'PEN';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          margin: const EdgeInsets.only(top: 60),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: AppColors.blue1, size: 20),
                      const SizedBox(width: 8),
                      const AppSubtitle('Nueva Cuenta Bancaria', fontSize: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomText(controller: nombreBancoCtrl, label: 'Banco *', hintText: 'Ej: BCP, Interbank', borderColor: AppColors.blue1),
                  const SizedBox(height: 12),
                  CustomDropdown<String>(
                    label: 'Tipo de cuenta',
                    value: tipoCuenta,
                    borderColor: AppColors.blue1,
                    items: const [
                      DropdownItem(value: 'AHORROS', label: 'Ahorros'),
                      DropdownItem(value: 'CORRIENTE', label: 'Corriente'),
                      DropdownItem(value: 'INTERBANCARIA', label: 'Interbancaria'),
                    ],
                    onChanged: (v) => setDialogState(() => tipoCuenta = v ?? 'AHORROS'),
                  ),
                  const SizedBox(height: 12),
                  CustomText(controller: numeroCuentaCtrl, label: 'Número de cuenta *', borderColor: AppColors.blue1),
                  const SizedBox(height: 12),
                  CustomText(controller: cciCtrl, label: 'CCI (opcional)', borderColor: AppColors.blue1),
                  const SizedBox(height: 12),
                  CustomText(controller: titularCtrl, label: 'Titular (opcional)', borderColor: AppColors.blue1),
                  const SizedBox(height: 12),
                  CustomDropdown<String>(
                    label: 'Moneda',
                    value: moneda,
                    borderColor: AppColors.blue1,
                    items: const [
                      DropdownItem(value: 'PEN', label: 'PEN - Soles'),
                      DropdownItem(value: 'USD', label: 'USD - Dólares'),
                    ],
                    onChanged: (v) => setDialogState(() => moneda = v ?? 'PEN'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Guardar',
                          backgroundColor: AppColors.blue1,
                          height: 44,
                          onPressed: () {
                            if (nombreBancoCtrl.text.isEmpty || numeroCuentaCtrl.text.isEmpty) return;
                            Navigator.pop(ctx);
                            cubit.crear(
                              nombreBanco: nombreBancoCtrl.text.trim(),
                              tipoCuenta: tipoCuenta,
                              numeroCuenta: numeroCuentaCtrl.text.trim(),
                              cci: cciCtrl.text.isNotEmpty ? cciCtrl.text.trim() : null,
                              titular: titularCtrl.text.isNotEmpty ? titularCtrl.text.trim() : null,
                              moneda: moneda,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Conciliar: el usuario ingresa el saldo REAL del extracto. El backend
  /// asienta la diferencia como ajuste de conciliación (no pisa en silencio).
  void _showSaldoDialog(BuildContext context, EmpresaBancoCubit cubit, EmpresaBanco cuenta) {
    final saldoCtrl = TextEditingController(text: cuenta.saldoActual.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Conciliar saldo - ${cuenta.nombreBanco}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresá el saldo REAL del extracto. La diferencia con el saldo del sistema (${cuenta.moneda ?? 'S/'} ${cuenta.saldoActual.toStringAsFixed(2)}) queda registrada como conciliación.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            CustomText(controller: saldoCtrl, label: 'Saldo del extracto', hintText: '0.00', borderColor: AppColors.blue1, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final saldo = double.tryParse(saldoCtrl.text.replaceAll(',', '.')) ?? 0;
              cubit.actualizarSaldo(id: cuenta.id, saldo: saldo);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
            child: const Text('Conciliar'),
          ),
        ],
      ),
    );
  }

  /// Ajuste manual +/- con motivo (comisión, interés, corrección).
  void _showAjusteDialog(BuildContext context, EmpresaBancoCubit cubit, EmpresaBanco cuenta) {
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    String tipo = 'EGRESO';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Ajuste de saldo - ${cuenta.nombreBanco}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
              CustomText(controller: motivoCtrl, label: 'Motivo', hintText: 'Ej: comisión de mantenimiento', borderColor: AppColors.blue1),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
                final motivo = motivoCtrl.text.trim();
                if (monto <= 0 || motivo.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresá monto (> 0) y motivo')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await locator<EmpresaBancoRemoteDataSource>().ajustar(id: cuenta.id, tipo: tipo, monto: monto, motivo: motivo);
                  cubit.loadCuentas();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajuste registrado'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Historial de ajustes/conciliaciones de la cuenta.
  Future<void> _showHistorialAjustes(BuildContext context, EmpresaBanco cuenta) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => FutureBuilder<List<Map<String, dynamic>>>(
          future: locator<EmpresaBancoRemoteDataSource>().getAjustes(id: cuenta.id),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }
            final ajustes = snap.data ?? [];
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: AppSubtitle('Ajustes - ${cuenta.nombreBanco}', fontSize: 14, color: AppColors.blue1)),
                const SizedBox(height: 12),
                if (ajustes.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Sin ajustes registrados', style: TextStyle(color: Colors.grey.shade500))))
                else
                  ...ajustes.map(_ajusteTile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ajusteTile(Map<String, dynamic> a) {
    final tipo = a['tipo']?.toString() ?? '';
    final esIngreso = tipo == 'INGRESO';
    final monto = (a['monto'] as num?)?.toDouble() ?? 0;
    final origen = a['origen']?.toString() == 'CONCILIACION' ? 'Conciliación' : 'Ajuste';
    final anterior = (a['saldoAnterior'] as num?)?.toDouble() ?? 0;
    final nuevo = (a['saldoNuevo'] as num?)?.toDouble() ?? 0;
    final fecha = a['creadoEn'] != null ? DateTime.tryParse(a['creadoEn'].toString()) : null;
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
                Text('${anterior.toStringAsFixed(2)} → ${nuevo.toStringAsFixed(2)}'
                    '${fecha != null ? '  ·  ${fecha.day}/${fecha.month}/${fecha.year}' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('${esIngreso ? '+' : '-'}${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: esIngreso ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Future<void> _eliminar(BuildContext context, EmpresaBancoCubit cubit, String id) async {
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
      cubit.eliminar(id: id);
    }
  }
}

class _CuentaCard extends StatelessWidget {
  final EmpresaBanco cuenta;
  final VoidCallback onMarcarPrincipal;
  final VoidCallback onEliminar;
  final VoidCallback onConciliacion;
  final VoidCallback onActualizarSaldo;
  final VoidCallback onAjuste;
  final VoidCallback onHistorial;

  const _CuentaCard({required this.cuenta, required this.onMarcarPrincipal, required this.onEliminar, required this.onActualizarSaldo, required this.onConciliacion, required this.onAjuste, required this.onHistorial});

  @override
  Widget build(BuildContext context) {
    final esPrincipal = cuenta.esPrincipal;
    final saldo = cuenta.saldoActual;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: esPrincipal ? AppColors.blue1 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(child: AppSubtitle(cuenta.nombreBanco, fontSize: 12)),
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
                    if (v == 'ajuste') onAjuste();
                    if (v == 'historial') onHistorial();
                    if (v == 'conciliacion') onConciliacion();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    if (!esPrincipal) const PopupMenuItem(value: 'principal', child: Text('Marcar como principal')),
                    const PopupMenuItem(value: 'saldo', child: Text('Conciliar saldo')),
                    const PopupMenuItem(value: 'ajuste', child: Text('Ajuste (+/-)')),
                    const PopupMenuItem(value: 'historial', child: Text('Historial de ajustes')),
                    const PopupMenuItem(value: 'conciliacion', child: Text('Conciliación (movimientos)')),
                    const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 8),
            _infoRow(Icons.credit_card, '${_tipoCuentaLabel(cuenta.tipoCuenta)} - ${cuenta.moneda ?? 'PEN'}'),
            _infoRow(Icons.numbers, cuenta.numeroCuenta),
            if (cuenta.cci != null && cuenta.cci!.isNotEmpty)
              _infoRow(Icons.swap_horiz, 'CCI: ${cuenta.cci}'),
            if (cuenta.titular != null && cuenta.titular!.isNotEmpty)
              _infoRow(Icons.person_outline, cuenta.titular!),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                AppSubtitle('${cuenta.moneda ?? 'S/'} ${saldo.toStringAsFixed(2)}',
                  fontSize: 12, color: saldo >= 0 ? Colors.green : Colors.red),
              ],
            ),
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

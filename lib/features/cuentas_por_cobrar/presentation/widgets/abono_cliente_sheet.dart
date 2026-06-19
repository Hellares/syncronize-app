import 'package:flutter/material.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/cuenta_por_cobrar.dart';
import '../bloc/cuentas_cobrar_cubit.dart';

/// Hoja para registrar un abono del cliente sobre una venta a crédito (CxC).
/// Devuelve `true` (Navigator.pop) si el abono quedó registrado.
class AbonoClienteSheet extends StatefulWidget {
  final CuentaPorCobrar cuenta;
  final CuentasCobrarCubit cubit;

  const AbonoClienteSheet({super.key, required this.cuenta, required this.cubit});

  static Future<bool?> mostrar(
    BuildContext context, {
    required CuentaPorCobrar cuenta,
    required CuentasCobrarCubit cubit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AbonoClienteSheet(cuenta: cuenta, cubit: cubit),
    );
  }

  @override
  State<AbonoClienteSheet> createState() => _AbonoClienteSheetState();
}

class _AbonoClienteSheetState extends State<AbonoClienteSheet> {
  String _metodo = 'EFECTIVO';
  late final TextEditingController _montoCtrl;
  final _refCtrl = TextEditingController();
  bool _procesando = false;

  // Total a cobrar incluye la mora (el backend la aplica primero).
  double get _maximo => widget.cuenta.totalConMora;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: _maximo.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    var monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      _snack('Ingresá un monto válido');
      return;
    }
    if (monto > _maximo + 0.001) {
      _snack('El monto no puede superar el saldo (S/ ${_maximo.toStringAsFixed(2)})');
      return;
    }
    monto = (monto * 100).round() / 100;
    // En métodos digitales la bancarización (ventas ≥ umbral) exige N° de
    // operación → default 00000 si lo dejan vacío.
    final esDigital = _metodo != 'EFECTIVO';
    final ref = _refCtrl.text.trim();
    final referencia = esDigital ? (ref.isEmpty ? '00000' : ref) : (ref.isEmpty ? null : ref);

    setState(() => _procesando = true);
    final err = await widget.cubit.registrarAbono(
      widget.cuenta.id,
      metodoPago: _metodo,
      monto: monto,
      referencia: referencia,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _procesando = false);
      _snack(err);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppTitle('Registrar abono', fontSize: 17, color: AppColors.blue1),
                const SizedBox(height: 2),
                AppSubtitle(c.nombreCliente, fontSize: 12, color: AppColors.blueGrey),
                const SizedBox(height: 2),
                AppSubtitle(
                  '${c.codigo}  ·  Saldo: S/ ${c.saldoPendiente.toStringAsFixed(2)}'
                  '${c.totalMora > 0 ? '  + mora S/ ${c.totalMora.toStringAsFixed(2)}' : ''}',
                  fontSize: 11,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                CustomDropdown<String>(
                  label: 'Método de pago',
                  value: _metodo,
                  borderColor: AppColors.blueborder,
                  items: const [
                    DropdownItem(value: 'EFECTIVO', label: 'Efectivo'),
                    DropdownItem(value: 'YAPE', label: 'Yape'),
                    DropdownItem(value: 'PLIN', label: 'Plin'),
                    DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                  ],
                  onChanged: (v) => setState(() => _metodo = v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 12),
                CustomText(
                  label: 'Monto (máx S/ ${_maximo.toStringAsFixed(2)})',
                  controller: _montoCtrl,
                  fieldType: FieldType.number,
                  borderColor: AppColors.blueborder,
                ),
                if (_metodo != 'EFECTIVO') ...[
                  const SizedBox(height: 12),
                  CustomText(
                    label: 'N° de operación / voucher (opcional)',
                    controller: _refCtrl,
                    fieldType: FieldType.number,
                    hintText: 'N° op.',
                    borderColor: AppColors.blueborder,
                    maxLength: 20,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancelar',
                        isOutlined: true,
                        borderColor: Colors.grey.shade400,
                        textColor: Colors.grey.shade700,
                        enableShadows: false,
                        onPressed: _procesando ? null : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Registrar abono',
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        isLoading: _procesando,
                        onPressed: _procesando ? null : _registrar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

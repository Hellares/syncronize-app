import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

class CrearAgenteDialog extends StatefulWidget {
  final Function(Map<String, dynamic> data) onConfirm;

  const CrearAgenteDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required Function(Map<String, dynamic> data) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CrearAgenteDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<CrearAgenteDialog> createState() => _CrearAgenteDialogState();
}

class _CrearAgenteDialogState extends State<CrearAgenteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bancoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _fondoController = TextEditingController();
  final _comisionDepositoController = TextEditingController(text: '0.5');
  final _comisionRetiroController = TextEditingController(text: '0.5');
  bool _loading = false;

  @override
  void dispose() {
    _bancoController.dispose();
    _codigoController.dispose();
    _fondoController.dispose();
    _comisionDepositoController.dispose();
    _comisionRetiroController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = <String, dynamic>{
      'banco': _bancoController.text.trim(),
      'fondoAsignado': double.parse(_fondoController.text),
      'comisionDeposito': double.parse(_comisionDepositoController.text),
      'comisionRetiro': double.parse(_comisionRetiroController.text),
    };
    if (_codigoController.text.isNotEmpty) {
      data['codigoAgente'] = _codigoController.text.trim();
    }

    widget.onConfirm(data);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.teal, size: 22),
                  SizedBox(width: 8),
                  AppSubtitle('Nuevo Agente Bancario', fontSize: 16),
                ],
              ),
              const SizedBox(height: 20),
              CustomText(
                controller: _bancoController,
                borderColor: Colors.teal,
                label: 'Banco *',
                hintText: 'Ej: BCP, Interbank, BBVA',
                prefixIcon: const Icon(Icons.account_balance),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del banco' : null,
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _codigoController,
                borderColor: AppColors.blue1,
                label: 'Codigo de Agente',
                hintText: 'Opcional',
                prefixIcon: const Icon(Icons.tag),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _fondoController,
                borderColor: Colors.teal,
                label: 'Fondo Asignado *',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el fondo';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto invalido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      controller: _comisionDepositoController,
                      borderColor: AppColors.blue1,
                      label: 'Comision Deposito %',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Invalido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomText(
                      controller: _comisionRetiroController,
                      borderColor: AppColors.blue1,
                      label: 'Comision Retiro %',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Invalido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Crear Agente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

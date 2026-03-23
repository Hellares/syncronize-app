import 'package:flutter/material.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

class RegistrarOperacionDialog extends StatefulWidget {
  final String tipo;
  final double comisionPorcentaje;
  final Function(Map<String, dynamic> data) onConfirm;

  const RegistrarOperacionDialog({
    super.key,
    required this.tipo,
    required this.comisionPorcentaje,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String tipo,
    required double comisionPorcentaje,
    required Function(Map<String, dynamic> data) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistrarOperacionDialog(
        tipo: tipo,
        comisionPorcentaje: comisionPorcentaje,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RegistrarOperacionDialog> createState() => _RegistrarOperacionDialogState();
}

class _RegistrarOperacionDialogState extends State<RegistrarOperacionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _documentoController = TextEditingController();
  final _numOperacionController = TextEditingController();
  final _observacionesController = TextEditingController();
  double _comisionCalculada = 0;
  bool _loading = false;

  bool get _isDeposito => widget.tipo == 'DEPOSITO';
  Color get _color => _isDeposito ? AppColors.green : AppColors.red;

  @override
  void initState() {
    super.initState();
    _montoController.addListener(_calcularComision);
  }

  void _calcularComision() {
    final monto = CurrencyUtilsImproved.parseToDouble(_montoController.text);
    setState(() => _comisionCalculada = monto * widget.comisionPorcentaje / 100);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _nombreController.dispose();
    _documentoController.dispose();
    _numOperacionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = <String, dynamic>{
      'tipo': widget.tipo,
      'monto': double.parse(_montoController.text),
    };
    if (_nombreController.text.isNotEmpty) data['nombreCliente'] = _nombreController.text;
    if (_documentoController.text.isNotEmpty) data['documentoCliente'] = _documentoController.text;
    if (_numOperacionController.text.isNotEmpty) data['numeroOperacion'] = _numOperacionController.text;
    if (_observacionesController.text.isNotEmpty) data['observaciones'] = _observacionesController.text;

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
              Row(
                children: [
                  Icon(_isDeposito ? Icons.arrow_downward : Icons.arrow_upward, color: _color, size: 22),
                  const SizedBox(width: 8),
                  AppSubtitle(_isDeposito ? 'Registrar Deposito' : 'Registrar Retiro', fontSize: 16),
                ],
              ),
              const SizedBox(height: 20),
              CustomText(
                controller: _montoController,
                borderColor: _color,
                label: 'Monto *',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto invalido';
                  return null;
                },
              ),
              if (_comisionCalculada > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Comision (${widget.comisionPorcentaje}%):', style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w500)),
                      Text('S/ ${_comisionCalculada.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: _color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              CustomText(controller: _nombreController, borderColor: AppColors.blue1, label: 'Nombre del Cliente', hintText: 'Opcional'),
              const SizedBox(height: 12),
              CustomText(controller: _documentoController, borderColor: AppColors.blue1, label: 'DNI / Documento', hintText: 'Opcional', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              CustomText(controller: _numOperacionController, borderColor: AppColors.blue1, label: 'N. Operacion', hintText: 'Codigo del banco'),
              const SizedBox(height: 12),
              CustomText(controller: _observacionesController, borderColor: AppColors.blue1, label: 'Observaciones', hintText: 'Opcional', maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isDeposito ? 'Confirmar Deposito' : 'Confirmar Retiro', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../../domain/usecases/comprobante_pago_usecases.dart';
import '../bloc/cuentas_pagar_cubit.dart';

/// Hoja para registrar un pago/abono a proveedor sobre una compra (CxP).
/// Devuelve `true` (Navigator.pop) si el pago quedó registrado.
class PagoProveedorSheet extends StatefulWidget {
  final CuentaPorPagar cuenta;
  final CuentasPagarCubit cubit;

  const PagoProveedorSheet({super.key, required this.cuenta, required this.cubit});

  static Future<bool?> mostrar(
    BuildContext context, {
    required CuentaPorPagar cuenta,
    required CuentasPagarCubit cubit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PagoProveedorSheet(cuenta: cuenta, cubit: cubit),
    );
  }

  @override
  State<PagoProveedorSheet> createState() => _PagoProveedorSheetState();
}

class _PagoProveedorSheetState extends State<PagoProveedorSheet> {
  String _metodo = 'EFECTIVO';
  late final TextEditingController _montoCtrl;
  final _refCtrl = TextEditingController();
  late final TextEditingController _bancoCtrl;
  late final TextEditingController _cuentaCtrl;
  bool _procesando = false;
  File? _comprobante;
  final _picker = ImagePicker();

  bool get _esBancario =>
      _metodo == 'TRANSFERENCIA' || _metodo == 'YAPE' || _metodo == 'PLIN' || _metodo == 'TARJETA';

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: widget.cuenta.saldoPendiente.toStringAsFixed(2));
    _bancoCtrl = TextEditingController(text: widget.cuenta.bancoPrincipal?.nombreBanco ?? '');
    _cuentaCtrl = TextEditingController(text: widget.cuenta.bancoPrincipal?.numeroCuenta ?? '');
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _refCtrl.dispose();
    _bancoCtrl.dispose();
    _cuentaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final saldo = widget.cuenta.saldoPendiente;
    var monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      _snack('Ingresá un monto válido');
      return;
    }
    if (monto > saldo + 0.001) {
      _snack('El monto no puede superar el saldo (S/ ${saldo.toStringAsFixed(2)})');
      return;
    }
    monto = (monto * 100).round() / 100;
    setState(() => _procesando = true);

    // Si adjuntó comprobante, súbelo primero para obtener la URL.
    String? comprobanteUrl;
    if (_esBancario && _comprobante != null) {
      final res = await locator<SubirComprobantePagoUseCase>().call(_comprobante!.path);
      if (!mounted) return;
      if (res is Success<String>) {
        comprobanteUrl = res.data;
      } else {
        setState(() => _procesando = false);
        _snack('No se pudo subir el comprobante. Intentá de nuevo.');
        return;
      }
    }

    final err = await widget.cubit.registrarPago(
      widget.cuenta.id,
      metodoPago: _metodo,
      monto: monto,
      referencia: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      bancoDestino: _esBancario && _bancoCtrl.text.trim().isNotEmpty ? _bancoCtrl.text.trim() : null,
      cuentaDestino: _esBancario && _cuentaCtrl.text.trim().isNotEmpty ? _cuentaCtrl.text.trim() : null,
      comprobanteUrl: comprobanteUrl,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _procesando = false);
      _snack(err);
    }
  }

  Future<void> _pickComprobante() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.blue1),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.blue1),
              title: const Text('Galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked != null) setState(() => _comprobante = File(picked.path));
    } catch (e) {
      if (mounted) _snack('No se pudo seleccionar la imagen');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildComprobantePicker() {
    if (_comprobante == null) {
      return GestureDetector(
        onTap: _procesando ? null : _pickComprobante,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blueborder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_file, size: 18, color: AppColors.blue1.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              AppSubtitle('Adjuntar comprobante (opcional)', fontSize: 12, color: AppColors.blue1),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_comprobante!, width: 54, height: 54, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: AppSubtitle('Comprobante adjuntado', fontSize: 12, color: AppColors.blueGrey),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18, color: AppColors.blue1),
          onPressed: _procesando ? null : _pickComprobante,
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
          onPressed: _procesando ? null : () => setState(() => _comprobante = null),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldo = widget.cuenta.saldoPendiente;
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
                AppTitle('Pagar a proveedor', fontSize: 17, color: AppColors.blue1),
                const SizedBox(height: 2),
                AppSubtitle(widget.cuenta.nombreProveedor, fontSize: 12, color: AppColors.blueGrey),
                const SizedBox(height: 2),
                AppSubtitle(
                  '${widget.cuenta.codigo}  ·  Saldo: S/ ${saldo.toStringAsFixed(2)}',
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
                    DropdownItem(value: 'TRANSFERENCIA', label: 'Transferencia'),
                    DropdownItem(value: 'YAPE', label: 'Yape'),
                    DropdownItem(value: 'PLIN', label: 'Plin'),
                    DropdownItem(value: 'TARJETA', label: 'Tarjeta'),
                  ],
                  onChanged: (v) => setState(() => _metodo = v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 12),
                CustomText(
                  label: 'Monto (máx S/ ${saldo.toStringAsFixed(2)})',
                  controller: _montoCtrl,
                  fieldType: FieldType.number,
                  borderColor: AppColors.blueborder,
                ),
                const SizedBox(height: 12),
                CustomText(
                  label: 'N° de operación / voucher (opcional)',
                  controller: _refCtrl,
                  fieldType: FieldType.number,
                  hintText: 'N° op.',
                  borderColor: AppColors.blueborder,
                  maxLength: 20,
                ),
                if (_esBancario) ...[
                  const SizedBox(height: 12),
                  CustomText(
                    label: 'Banco destino (opcional)',
                    controller: _bancoCtrl,
                    borderColor: AppColors.blueborder,
                  ),
                  const SizedBox(height: 12),
                  CustomText(
                    label: 'Cuenta destino (opcional)',
                    controller: _cuentaCtrl,
                    borderColor: AppColors.blueborder,
                  ),
                  const SizedBox(height: 12),
                  _buildComprobantePicker(),
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
                        text: 'Registrar pago',
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

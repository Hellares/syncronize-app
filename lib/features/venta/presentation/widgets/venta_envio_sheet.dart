import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/venta.dart';

/// Datos del envío recolectados por el sheet (el caller hace el upsert).
class VentaEnvioFormData {
  final String destinatarioNombre;
  final String? destinatarioDni;
  final String? destinatarioCelular;
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;

  const VentaEnvioFormData({
    required this.destinatarioNombre,
    this.destinatarioDni,
    this.destinatarioCelular,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
  });

  Map<String, dynamic> toJson() => {
        'destinatarioNombre': destinatarioNombre,
        if (destinatarioDni != null && destinatarioDni!.isNotEmpty)
          'destinatarioDni': destinatarioDni,
        if (destinatarioCelular != null && destinatarioCelular!.isNotEmpty)
          'destinatarioCelular': destinatarioCelular,
        if (agenciaNombre != null && agenciaNombre!.isNotEmpty)
          'agenciaNombre': agenciaNombre,
        if (destinoDepartamento != null && destinoDepartamento!.isNotEmpty)
          'destinoDepartamento': destinoDepartamento,
        if (destinoProvincia != null && destinoProvincia!.isNotEmpty)
          'destinoProvincia': destinoProvincia,
        if (agenciaDireccion != null && agenciaDireccion!.isNotEmpty)
          'agenciaDireccion': agenciaDireccion,
      };
}

/// Sheet de datos del ENVÍO de una venta: prellenado con lo guardado o
/// con el snapshot del cliente de la venta — todo editable (el
/// destinatario puede ser otra persona: "envíaselo a mi mamá").
Future<VentaEnvioFormData?> showVentaEnvioSheet({
  required BuildContext context,
  required Venta venta,
}) {
  return showModalBottomSheet<VentaEnvioFormData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VentaEnvioSheet(venta: venta),
  );
}

class _VentaEnvioSheet extends StatefulWidget {
  final Venta venta;
  const _VentaEnvioSheet({required this.venta});

  @override
  State<_VentaEnvioSheet> createState() => _VentaEnvioSheetState();
}

class _VentaEnvioSheetState extends State<_VentaEnvioSheet> {
  late final _nombreCtrl = TextEditingController(
    text: widget.venta.envio?.destinatarioNombre ?? widget.venta.nombreCliente,
  );
  late final _dniCtrl = TextEditingController(
    text: widget.venta.envio?.destinatarioDni ??
        widget.venta.documentoCliente ??
        '',
  );
  late final _celularCtrl = TextEditingController(
    text: widget.venta.envio?.destinatarioCelular ??
        widget.venta.telefonoCliente ??
        '',
  );
  late final _agenciaCtrl =
      TextEditingController(text: widget.venta.envio?.agenciaNombre ?? '');
  late final _destinoDepCtrl = TextEditingController(
      text: widget.venta.envio?.destinoDepartamento ?? '');
  late final _destinoProvCtrl =
      TextEditingController(text: widget.venta.envio?.destinoProvincia ?? '');
  late final _agenciaDirCtrl =
      TextEditingController(text: widget.venta.envio?.agenciaDireccion ?? '');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _celularCtrl.dispose();
    _agenciaCtrl.dispose();
    _destinoDepCtrl.dispose();
    _destinoProvCtrl.dispose();
    _agenciaDirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      color: AppColors.blue1, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Envío de la venta ${widget.venta.codigo}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _nombreCtrl,
                label: 'Destinatario',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      controller: _dniCtrl,
                      label: 'DNI',
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      controller: _celularCtrl,
                      label: 'Celular',
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _agenciaCtrl,
                label: 'Agencia',
                hintText: 'ej. Shalom / Olva / Marvisur',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final a in const ['SHALOM', 'OLVA', 'MARVISUR'])
                    ActionChip(
                      label: Text(a, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.blue1.withValues(alpha: 0.06),
                      side: BorderSide(
                          color: AppColors.blue1.withValues(alpha: 0.3),
                          width: 0.5),
                      onPressed: () =>
                          setState(() => _agenciaCtrl.text = a),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      controller: _destinoDepCtrl,
                      label: 'Departamento',
                      hintText: 'ej. San Martín',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      controller: _destinoProvCtrl,
                      label: 'Provincia / ciudad',
                      hintText: 'ej. Tarapoto',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _agenciaDirCtrl,
                label: 'Dirección de la agencia destino',
                hintText: 'ej. Jr. Los Pinos 123',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      enableShadows: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Guardar envío',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: () {
                        final nombre = _nombreCtrl.text.trim();
                        if (nombre.isEmpty) return;
                        Navigator.of(context).pop(VentaEnvioFormData(
                          destinatarioNombre: nombre,
                          destinatarioDni: _dniCtrl.text.trim(),
                          destinatarioCelular: _celularCtrl.text.trim(),
                          agenciaNombre: _agenciaCtrl.text.trim(),
                          destinoDepartamento: _destinoDepCtrl.text.trim(),
                          destinoProvincia: _destinoProvCtrl.text.trim(),
                          agenciaDireccion: _agenciaDirCtrl.text.trim(),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

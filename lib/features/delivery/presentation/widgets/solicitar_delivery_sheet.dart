import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

/// Datos del delivery recolectados por el sheet (el caller arma el payload
/// con empresaId/ventaId y hace el POST).
class SolicitarDeliveryFormData {
  final String direccion;
  final String? referencia;
  final String? distrito;

  /// null = el backend aplica la tarifa default de la sede.
  final double? costoDelivery;

  const SolicitarDeliveryFormData({
    required this.direccion,
    this.referencia,
    this.distrito,
    this.costoDelivery,
  });

  Map<String, dynamic> toJson() => {
        'direccion': direccion,
        if (referencia != null && referencia!.isNotEmpty)
          'referencia': referencia,
        if (distrito != null && distrito!.isNotEmpty) 'distrito': distrito,
        if (costoDelivery != null) 'costoDelivery': costoDelivery,
      };
}

/// Sheet para publicar el DELIVERY LOCAL de una venta ya pagada al 100%:
/// dirección de entrega + tarifa (vacía = la default de la sede). Al
/// confirmar, el backend lo publica al pool y notifica a los repartidores.
Future<SolicitarDeliveryFormData?> showSolicitarDeliverySheet({
  required BuildContext context,
  required String ventaCodigo,
}) {
  return showModalBottomSheet<SolicitarDeliveryFormData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SolicitarDeliverySheet(ventaCodigo: ventaCodigo),
  );
}

class _SolicitarDeliverySheet extends StatefulWidget {
  final String ventaCodigo;
  const _SolicitarDeliverySheet({required this.ventaCodigo});

  @override
  State<_SolicitarDeliverySheet> createState() =>
      _SolicitarDeliverySheetState();
}

class _SolicitarDeliverySheetState extends State<_SolicitarDeliverySheet> {
  final _direccionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _distritoCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _distritoCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final direccion = _direccionCtrl.text.trim();
    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ingresa la dirección de entrega',
            style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final costoTexto = _costoCtrl.text.trim();
    double? costo;
    if (costoTexto.isNotEmpty) {
      costo = double.tryParse(costoTexto.replaceAll(',', '.'));
      if (costo == null || costo < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('La tarifa no es un monto válido',
              style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }
    Navigator.of(context).pop(SolicitarDeliveryFormData(
      direccion: direccion,
      referencia: _referenciaCtrl.text.trim(),
      distrito: _distritoCtrl.text.trim(),
      costoDelivery: costo,
    ));
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
                  const Icon(Icons.delivery_dining,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery local — ${widget.ventaCodigo}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'El producto ya está pagado: el repartidor cobra SOLO la '
                'tarifa del delivery al entregar.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _direccionCtrl,
                label: 'Dirección de entrega',
                hintText: 'ej. Av. Los Olivos 123',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _referenciaCtrl,
                label: 'Referencia',
                hintText: 'ej. Casa de rejas verdes, frente al parque',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomText(
                      controller: _distritoCtrl,
                      label: 'Distrito / zona',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      controller: _costoCtrl,
                      label: 'Tarifa S/',
                      hintText: 'de la sede',
                      borderColor: AppColors.blue1,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tarifa vacía = se usa la tarifa configurada de la sede.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 14),
              CustomButton(
                text: 'Publicar para repartidores',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                icon: const Icon(Icons.delivery_dining,
                    size: 16, color: Colors.white),
                onPressed: _confirmar,
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

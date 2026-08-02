import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/delivery_local.dart';

/// Resultado del sheet: el precio que el repartidor propone.
class OfertaFormData {
  final double monto;
  final String? comentario;

  const OfertaFormData({required this.monto, this.comentario});
}

/// El repartidor propone su precio por un pedido en subasta.
///
/// La empresa no sabe cuánto sale llegar a cada zona; el repartidor sí. Por
/// eso el precio sugerido es solo un ancla —puede no venir— y el comentario
/// existe para justificar un monto alto ("son 20 min de ida"), que es lo que
/// le permite al staff decidir con algo más que el número.
Future<OfertaFormData?> showOfertarSheet({
  required BuildContext context,
  required DeliveryLocal delivery,
}) {
  return showModalBottomSheet<OfertaFormData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfertarSheet(delivery: delivery),
  );
}

class _OfertarSheet extends StatefulWidget {
  final DeliveryLocal delivery;

  const _OfertarSheet({required this.delivery});

  @override
  State<_OfertarSheet> createState() => _OfertarSheetState();
}

class _OfertarSheetState extends State<_OfertarSheet> {
  late final TextEditingController _montoCtrl = TextEditingController(
    // Prefill con lo que ya oferté, si no con el sugerido de la empresa.
    text: (widget.delivery.miOfertaMonto ?? widget.delivery.costoSugerido)
            ?.toStringAsFixed(2) ??
        '',
  );
  final _comentarioCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido mayor a 0');
      return;
    }
    Navigator.pop(
      context,
      OfertaFormData(
        monto: monto,
        comentario: _comentarioCtrl.text.trim().isEmpty
            ? null
            : _comentarioCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                d.tengoOfertaViva ? 'Cambiar mi oferta' : 'Proponer mi precio',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${d.ventaCodigo ?? 'Pedido'} · ${d.direccion}'
                '${d.distrito != null ? ' (${d.distrito})' : ''}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.costoSugerido != null
                      ? 'La empresa sugiere S/ ${d.costoSugerido!.toStringAsFixed(2)}. '
                          'Puedes proponer otro monto si la zona lo amerita.'
                      : 'La empresa no puso precio: propón lo que cobras por '
                          'llegar a esa zona.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.blue1),
                ),
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: _montoCtrl,
                label: 'Mi precio (S/)',
                hintText: 'ej. 8.00',
                borderColor: AppColors.blue1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _comentarioCtrl,
                label: 'Motivo (opcional)',
                hintText: 'ej. son 20 min de ida, zona sin asfaltar',
                borderColor: AppColors.blue1,
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 11.5, color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Tu oferta vence en 10 minutos. Si la empresa elige otra, '
                'te avisamos.',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Enviar oferta',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: _confirmar,
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

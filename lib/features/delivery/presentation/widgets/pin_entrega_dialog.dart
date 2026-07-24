import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_text.dart';

/// Diálogo de PRUEBA DE ENTREGA: el repartidor le pide al cliente su
/// código de 4 dígitos (le llegó por WhatsApp y está en su página de
/// seguimiento) y lo ingresa aquí. Devuelve el PIN o null si canceló.
Future<String?> showPinEntregaDialog({
  required BuildContext context,
  required String ventaCodigo,
  required double costoDelivery,
}) {
  final pinCtrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('🔐 Código de entrega', style: TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pídele al cliente su código de 4 dígitos ($ventaCodigo). '
            'Le llegó por WhatsApp y está en su página de seguimiento.'
            '${costoDelivery > 0 ? '\n\nRecuerda cobrar S/ ${costoDelivery.toStringAsFixed(2)} del delivery.' : ''}',
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: pinCtrl,
            label: 'Código del cliente',
            hintText: '4 dígitos',
            borderColor: AppColors.blue1,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
          onPressed: () {
            final pin = pinCtrl.text.trim();
            if (pin.length != 4) return; // sin 4 dígitos no hay entrega
            Navigator.pop(ctx, pin);
          },
          child: const Text('Confirmar entrega'),
        ),
      ],
    ),
  );
}

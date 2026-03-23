import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../network/dio_client.dart';

/// Verifica que el usuario tenga una caja abierta antes de continuar.
/// Retorna `true` si hay caja abierta, `false` si no (y muestra diálogo).
Future<bool> verificarCajaAbierta(BuildContext context) async {
  try {
    final dio = locator<DioClient>();
    final response = await dio.get('/caja/activa');
    final data = response.data;
    if (data != null && data is Map<String, dynamic> && data['id'] != null) {
      return true;
    }
  } catch (_) {}

  if (!context.mounted) return false;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.point_of_sale, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Caja no abierta')),
        ],
      ),
      content: const Text(
        'Debes abrir una caja antes de realizar ventas.\n\n'
        'Ve a Caja → Abrir Caja para continuar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            context.push('/empresa/caja');
          },
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Ir a Caja'),
        ),
      ],
    ),
  );

  return false;
}

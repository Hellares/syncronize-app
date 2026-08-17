import 'package:flutter/material.dart';

import 'package:syncronize/core/theme/app_colors.dart';
import '../../domain/services/conteo_borrador_store.dart';

/// Aviso de que el conteo que se ve en pantalla se recuperó de una sesión
/// anterior, con la opción de descartarlo y empezar de cero.
///
/// 🔴 Nunca restaurar en silencio: si el cajero ve montos cargados y asume que
/// son los que acaba de contar, aplica un conteo viejo, la caja cuadra mal y el
/// descuadre aparece recién en el arqueo siguiente, sin rastro de dónde salió.
/// Por eso el aviso dice DE CUÁNDO es el conteo.
class AvisoConteoRecuperado extends StatelessWidget {
  final ConteoBorrador borrador;
  final VoidCallback onDescartar;

  const AvisoConteoRecuperado({
    super.key,
    required this.borrador,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blue3.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue3.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: AppColors.blue3),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recuperamos tu conteo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
                ),
                Text(
                  'Lo guardamos ${borrador.antiguedadLegible}. Revisá que siga '
                  'siendo correcto antes de confirmar.',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDescartar,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Descartar', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

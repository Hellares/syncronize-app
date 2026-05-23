import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';

/// Selector del tipo de comprobante a emitir (Nota de venta, Boleta,
/// Factura). Mismo lenguaje visual que los `ConfirmDialog` del módulo
/// productos: `Dialog` transparente + `GradientContainer` con borde y
/// sombra `blue1`, cards por opción con icono coloreado.
class TipoComprobanteDialog extends StatelessWidget {
  const TipoComprobanteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GradientContainer(
        borderColor: AppColors.blue1.withValues(alpha: 0.4),
        borderWidth: 1,
        customShadows: [
          BoxShadow(
            color: AppColors.blue1.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono + título.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.blue1,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tipo de comprobante',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Elegí el comprobante que se emitirá para esta venta.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _Opcion(
              icon: Icons.receipt_outlined,
              label: 'Nota de venta',
              descripcion: 'Comprobante interno sin valor tributario',
              onTap: () => Navigator.of(context).pop('TICKET'),
            ),
            const SizedBox(height: 8),
            _Opcion(
              icon: Icons.description_outlined,
              label: 'Boleta de venta',
              descripcion: 'Para consumidor final',
              onTap: () => Navigator.of(context).pop('BOLETA'),
            ),
            const SizedBox(height: 8),
            _Opcion(
              icon: Icons.assignment_outlined,
              label: 'Factura',
              descripcion: 'Para empresa con RUC',
              onTap: () => Navigator.of(context).pop('FACTURA'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.blue3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descripcion;
  final VoidCallback onTap;

  const _Opcion({
    required this.icon,
    required this.label,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue1, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.blue1.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

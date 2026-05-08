import 'package:flutter/material.dart';

class TipoComprobanteDialog extends StatelessWidget {
  const TipoComprobanteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'TIPO DE COMPROBANTE DE PAGO',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            _Opcion(
              label: 'NOTA DE VENTA',
              onTap: () => Navigator.of(context).pop('TICKET'),
            ),
            _Opcion(
              label: 'BOLETA DE VENTA',
              onTap: () => Navigator.of(context).pop('BOLETA'),
            ),
            _Opcion(
              label: 'FACTURA',
              onTap: () => Navigator.of(context).pop('FACTURA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Opcion({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Banner que muestra conflictos de compatibilidad entre items
class CotizacionCompatibilidadBanner extends StatelessWidget {
  final bool compatible;
  final List<Map<String, dynamic>> conflictos;

  const CotizacionCompatibilidadBanner({
    super.key,
    required this.compatible,
    required this.conflictos,
  });

  @override
  Widget build(BuildContext context) {
    if (compatible) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Todos los productos son compatibles entre si',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conflictos de compatibilidad (${conflictos.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...conflictos.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('  \u2022 ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        c['mensaje'] as String? ?? 'Conflicto desconocido',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

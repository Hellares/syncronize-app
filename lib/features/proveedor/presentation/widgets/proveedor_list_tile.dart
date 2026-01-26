import 'package:flutter/material.dart';
import '../../domain/entities/proveedor.dart';

class ProveedorListTile extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback? onTap;

  const ProveedorListTile({
    super.key,
    required this.proveedor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: proveedor.isActive
              ? Colors.blue.shade100
              : Colors.grey.shade300,
          child: Text(
            proveedor.iniciales,
            style: TextStyle(
              color:
                  proveedor.isActive ? Colors.blue.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          proveedor.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${proveedor.codigo} • ${proveedor.numeroDocumento}'),
            if (proveedor.terminosPago != null)
              Text(
                proveedor.terminosPagoTexto,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (proveedor.calificacion != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    proveedor.calificacion.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            if (!proveedor.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Inactivo',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

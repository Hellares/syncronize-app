import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector.dart';

/// Busca un producto del catálogo para una celda de tabla.
///
/// Envuelve [ProductoSedeSelector], el selector estándar de la app (el mismo
/// de cotizaciones, compras, combos, citas y devoluciones): trae selector de
/// sede, búsqueda con debounce, caché, escáner de código de barras y soporte
/// de variantes. Reescribir todo eso aquí habría sido peor y se habría
/// quedado atrás en cuanto el estándar mejorara.
///
/// Devuelve `{nombre, precio, codigo}`; la tabla reparte cada dato en su
/// columna. El PRECIO es el de la sede elegida y queda CONGELADO: una orden
/// es un presupuesto, y si el catálogo sube mañana lo cotizado no cambia.
class BuscarProductoSheet extends StatelessWidget {
  final String empresaId;
  final String? sedeId;

  const BuscarProductoSheet({
    super.key,
    required this.empresaId,
    this.sedeId,
  });

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String empresaId,
    String? sedeId,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BuscarProductoSheet(empresaId: empresaId, sedeId: sedeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 18, color: AppColors.blue1),
                  SizedBox(width: 6),
                  Text(
                    'Producto del catálogo',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                    ),
                  ),
                ],
              ),
              Text(
                'El precio se guarda tal cual está hoy en la sede elegida.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 10),
              ProductoSedeSelector(
                empresaId: empresaId,
                sedeIdInicial: sedeId,
                label: 'Producto',
                hintText: 'Buscar por nombre o código…',
                onProductoSeleccionado: ({
                  required producto,
                  required sedeId,
                  variante,
                }) {
                  // Con variante manda SU precio: es lo que se vende.
                  final precio = variante != null
                      ? variante.precioEnSede(sedeId)
                      : producto.precioEnSede(sedeId);
                  final nombre = variante != null
                      ? '${producto.nombre} — ${variante.nombre}'
                      : producto.nombre;

                  Navigator.pop(context, {
                    'nombre': nombre,
                    if (precio != null) 'precio': precio.toStringAsFixed(2),
                    'codigo': producto.codigoEmpresa,
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';

/// Bottom sheet que muestra los niveles de precio configurados para un
/// producto: "Por Mayor", "Distribuidor", etc. con su rango de cantidades
/// y el precio resultante (fijo o porcentaje de descuento).
Future<void> showPreciosMayorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required Future<List<PrecioNivel>> Function(String productoId) cargarNiveles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Limita la altura máxima al 70% de la pantalla. Sin esto, el sheet
    // puede aparecer ocupando toda la pantalla durante la animación inicial
    // y "encogerse" cuando termina la carga async — efecto visual feo.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (_) => _PreciosMayorSheet(
      producto: producto,
      sedeId: sedeId,
      cargarNiveles: cargarNiveles,
    ),
  );
}

class _PreciosMayorSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final Future<List<PrecioNivel>> Function(String productoId) cargarNiveles;

  const _PreciosMayorSheet({
    required this.producto,
    required this.sedeId,
    required this.cargarNiveles,
  });

  @override
  State<_PreciosMayorSheet> createState() => _PreciosMayorSheetState();
}

class _PreciosMayorSheetState extends State<_PreciosMayorSheet> {
  late Future<List<PrecioNivel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.cargarNiveles(widget.producto.id);
  }

  @override
  Widget build(BuildContext context) {
    final precioBase = widget.producto.precioEfectivoEnSede(widget.sedeId) ??
        widget.producto.precioEnSede(widget.sedeId) ??
        0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Icon(Icons.auto_graph, color: AppColors.blue1, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precios por Volumen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1,
                        ),
                      ),
                      Text(
                        widget.producto.nombre,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Precio base
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.label_outline, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text('Precio base (1 unidad):',
                    style: TextStyle(fontSize: 12)),
                const Spacer(),
                Text(
                  'S/ ${precioBase.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Lista de niveles. AnimatedSize evita el salto visual cuando el
          // FutureBuilder pasa de loading (placeholder pequeño) al contenido
          // real (lista). Sin AnimatedSize el sheet "saltaría" de tamaño.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: FutureBuilder<List<PrecioNivel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final niveles = snap.data ?? const <PrecioNivel>[];
                if (niveles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.discount_outlined,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Este producto no tiene precios por mayor configurados',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                final ordenados = [...niveles]
                  ..sort((a, b) =>
                      a.cantidadMinima.compareTo(b.cantidadMinima));
                // ConstrainedBox limita el alto a 50% de pantalla: si hay
                // muchos niveles, el ListView interno hace scroll en lugar
                // de empujar el sheet a alturas raras.
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: ordenados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NivelTile(
                        nivel: ordenados[i], precioBase: precioBase),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NivelTile extends StatelessWidget {
  final PrecioNivel nivel;
  final double precioBase;

  const _NivelTile({required this.nivel, required this.precioBase});

  @override
  Widget build(BuildContext context) {
    final esPorcentaje = nivel.tipoPrecio == TipoPrecioNivel.porcentajeDescuento;
    final precioFinal = nivel.calcularPrecioFinal(precioBase);
    final descuentoPct = nivel.calcularDescuentoPorcentaje(precioBase);
    final ahorroPorUnidad = precioBase - precioFinal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Nombre del nivel
              Expanded(
                child: Text(
                  nivel.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              // Tipo (chip)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: esPorcentaje
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esPorcentaje ? Icons.percent : Icons.attach_money,
                      size: 10,
                      color: esPorcentaje
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      esPorcentaje ? 'Descuento' : 'Precio fijo',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: esPorcentaje
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Rango de cantidades
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 12, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                nivel.rangoString,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Precio resultante
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (descuentoPct > 0) ...[
                Text(
                  'S/ ${precioBase.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                'S/ ${precioFinal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800,
                ),
              ),
              if (esPorcentaje) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '−${descuentoPct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (ahorroPorUnidad > 0)
                Text(
                  'Ahorra S/ ${ahorroPorUnidad.toStringAsFixed(2)} c/u',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (nivel.descripcion != null && nivel.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              nivel.descripcion!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

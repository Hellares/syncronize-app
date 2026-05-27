import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

Future<ProductoVariante?> showVarianteSelectorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
}) {
  return showModalBottomSheet<ProductoVariante>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.65,
    ),
    builder: (_) => _VarianteSelectorSheet(
      producto: producto,
      sedeId: sedeId,
    ),
  );
}

class _VarianteSelectorSheet extends StatelessWidget {
  final ProductoListItem producto;
  final String sedeId;

  const _VarianteSelectorSheet({
    required this.producto,
    required this.sedeId,
  });

  @override
  Widget build(BuildContext context) {
    final variantes = producto.variantes
            ?.where((v) => v.isActive)
            .toList() ??
        [];

    variantes.sort((a, b) {
      final stockA = a.stockEnSede(sedeId) ?? 0;
      final stockB = b.stockEnSede(sedeId) ?? 0;
      if (stockA > 0 && stockB <= 0) return -1;
      if (stockA <= 0 && stockB > 0) return 1;
      return a.orden.compareTo(b.orden);
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.style, color: AppColors.blue1, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar variante',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de variantes
          if (variantes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No hay variantes disponibles',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: variantes.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) => _VarianteTile(
                  variante: variantes[i],
                  sedeId: sedeId,
                  onTap: () {
                    final stock = variantes[i].stockEnSede(sedeId) ?? 0;
                    if (stock <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sin stock: ${variantes[i].nombre}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, variantes[i]);
                  },
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _VarianteTile extends StatelessWidget {
  final ProductoVariante variante;
  final String sedeId;
  final VoidCallback onTap;

  const _VarianteTile({
    required this.variante,
    required this.sedeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stock = variante.stockEnSede(sedeId) ?? 0;
    final agotado = stock <= 0;
    final precio = variante.precioEfectivoEnSede(sedeId) ??
        variante.precioEnSede(sedeId);
    final enOferta = variante.enOfertaEnSede(sedeId);
    final enLiquidacion = variante.enLiquidacionEnSede(sedeId);
    final imagen = variante.thumbnailPrincipal;

    final atributos = variante.atributosValores
        .map((av) => '${av.atributo.nombre}: ${av.valor}')
        .join(', ');

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: agotado ? 0.45 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              if (imagen != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: imagen,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade100,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, size: 20, color: Colors.grey.shade400),
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.style, size: 20, color: AppColors.blue1.withValues(alpha: 0.5)),
                ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variante.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (atributos.isNotEmpty)
                      Text(
                        atributos,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          agotado ? 'Sin stock' : 'Stock: $stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: agotado ? Colors.red : Colors.grey.shade700,
                          ),
                        ),
                        if (enLiquidacion) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LIQ.',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ] else if (enOferta) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'OFERTA',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Precio
              if (precio != null)
                Text(
                  'S/ ${precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: agotado ? Colors.grey : AppColors.blue1,
                  ),
                )
              else
                Text(
                  'Sin precio',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

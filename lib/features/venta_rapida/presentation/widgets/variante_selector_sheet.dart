import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

Future<void> showVarianteSelectorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required void Function(ProductoVariante variante) onSeleccionada,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.65,
    ),
    builder: (_) => _VarianteSelectorSheet(
      producto: producto,
      sedeId: sedeId,
      onSeleccionada: onSeleccionada,
    ),
  );
}

class _VarianteSelectorSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final void Function(ProductoVariante) onSeleccionada;

  const _VarianteSelectorSheet({
    required this.producto,
    required this.sedeId,
    required this.onSeleccionada,
  });

  @override
  State<_VarianteSelectorSheet> createState() => _VarianteSelectorSheetState();
}

class _VarianteSelectorSheetState extends State<_VarianteSelectorSheet> {
  final Map<String, int> _agregados = {};

  int _stockDisponible(ProductoVariante v) {
    final real = v.stockEnSede(widget.sedeId) ?? 0;
    return (real - (_agregados[v.id] ?? 0)).clamp(0, real);
  }

  @override
  Widget build(BuildContext context) {
    final variantes = widget.producto.variantes
            ?.where((v) => v.isActive)
            .toList() ??
        [];

    variantes.sort((a, b) {
      final stockA = _stockDisponible(a);
      final stockB = _stockDisponible(b);
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
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                        widget.producto.nombre,
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
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final v = variantes[i];
                  final stockDisp = _stockDisponible(v);
                  final qty = _agregados[v.id] ?? 0;
                  return _VarianteTile(
                    variante: v,
                    sedeId: widget.sedeId,
                    stockDisponible: stockDisp,
                    cantidadAgregada: qty,
                    onTap: () {
                      if (stockDisp <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sin stock: ${v.nombre}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _agregados[v.id] = qty + 1;
                      });
                      widget.onSeleccionada(v);
                    },
                  );
                },
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
  final int stockDisponible;
  final int cantidadAgregada;
  final VoidCallback onTap;

  const _VarianteTile({
    required this.variante,
    required this.sedeId,
    required this.stockDisponible,
    required this.cantidadAgregada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final agotado = stockDisponible <= 0;
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
              // Thumbnail (long press → imagen completa)
              GestureDetector(
                onLongPress: () {
                  final fullUrl = variante.imagenPrincipal ?? imagen;
                  if (fullUrl != null) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black87,
                        barrierDismissible: true,
                        pageBuilder: (_, __, ___) => Scaffold(
                          backgroundColor: Colors.black87,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            title: Text(
                              variante.nombre,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                          body: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 5.0,
                            child: Center(
                              child: CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.white54),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: imagen != null
                    ? ClipRRect(
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
                            child: Icon(Icons.image,
                                size: 20, color: Colors.grey.shade400),
                          ),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.style,
                            size: 20,
                            color: AppColors.blue1.withValues(alpha: 0.5)),
                      ),
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
                          agotado ? 'Sin stock' : 'Stock: $stockDisponible',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: agotado ? Colors.red : Colors.grey.shade700,
                          ),
                        ),
                        if (cantidadAgregada > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+$cantidadAgregada',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (enLiquidacion) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LIQ.',
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                        ] else if (enOferta) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'OFERTA',
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
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

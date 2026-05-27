import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

Future<void> showVarianteSelectorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required void Function(ProductoVariante variante) onSeleccionada,
  void Function(ProductoVariante variante)? onDecrementada,
  Map<String, int> cantidadesEnCarrito = const {},
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
      onDecrementada: onDecrementada,
      cantidadesIniciales: cantidadesEnCarrito,
    ),
  );
}

class _VarianteSelectorSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final void Function(ProductoVariante) onSeleccionada;
  final void Function(ProductoVariante)? onDecrementada;
  final Map<String, int> cantidadesIniciales;

  const _VarianteSelectorSheet({
    required this.producto,
    required this.sedeId,
    required this.onSeleccionada,
    this.onDecrementada,
    this.cantidadesIniciales = const {},
  });

  @override
  State<_VarianteSelectorSheet> createState() => _VarianteSelectorSheetState();
}

class _VarianteSelectorSheetState extends State<_VarianteSelectorSheet> {
  late Map<String, int> _cantidades;

  @override
  void initState() {
    super.initState();
    _cantidades = Map.of(widget.cantidadesIniciales);
  }

  int _cantidadActual(String varianteId) => _cantidades[varianteId] ?? 0;

  int _stockDisponible(ProductoVariante v) {
    final real = v.stockEnSede(widget.sedeId) ?? 0;
    return (real - _cantidadActual(v.id)).clamp(0, real);
  }

  void _incrementar(ProductoVariante v) {
    if (_stockDisponible(v) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sin stock: ${v.nombre}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _cantidades[v.id] = _cantidadActual(v.id) + 1;
    });
    widget.onSeleccionada(v);
  }

  void _decrementar(ProductoVariante v) {
    final qty = _cantidadActual(v.id);
    if (qty <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _cantidades[v.id] = qty - 1;
    });
    widget.onDecrementada?.call(v);
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
                  final qty = _cantidadActual(v.id);
                  return _VarianteTile(
                    variante: v,
                    sedeId: widget.sedeId,
                    stockDisponible: stockDisp,
                    cantidadEnCarrito: qty,
                    onIncrement: () => _incrementar(v),
                    onDecrement: qty > 0 ? () => _decrementar(v) : null,
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
  final int cantidadEnCarrito;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const _VarianteTile({
    required this.variante,
    required this.sedeId,
    required this.stockDisponible,
    required this.cantidadEnCarrito,
    required this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final agotado = stockDisponible <= 0 && cantidadEnCarrito == 0;
    final precio = variante.precioEfectivoEnSede(sedeId) ??
        variante.precioEnSede(sedeId);
    final enOferta = variante.enOfertaEnSede(sedeId);
    final enLiquidacion = variante.enLiquidacionEnSede(sedeId);
    final imagen = variante.thumbnailPrincipal;

    final atributos = variante.atributosValores
        .map((av) => '${av.atributo.nombre}: ${av.valor}')
        .join(', ');

    return Opacity(
      opacity: agotado ? 0.45 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            icon:
                                const Icon(Icons.close, color: Colors.white),
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
            const SizedBox(width: 10),
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
                        agotado
                            ? 'Sin stock'
                            : 'Stock: $stockDisponible',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: agotado ? Colors.red : Colors.grey.shade700,
                        ),
                      ),
                      if (enLiquidacion) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade700,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('LIQ.',
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
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
                          child: const Text('OFERTA',
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Precio
            if (precio != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'S/ ${precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: agotado ? Colors.grey : AppColors.blue1,
                  ),
                ),
              ),
            // Stepper
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.green.shade200, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cantidadEnCarrito > 0) ...[
                    InkWell(
                      onTap: onDecrement,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.remove,
                            size: 14, color: Colors.green.shade700),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      alignment: Alignment.center,
                      child: Text(
                        '$cantidadEnCarrito',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                  InkWell(
                    onTap: stockDisponible > 0 ? onIncrement : null,
                    borderRadius: cantidadEnCarrito > 0
                        ? const BorderRadius.horizontal(
                            right: Radius.circular(8))
                        : BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.add,
                          size: 14,
                          color: stockDisponible > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

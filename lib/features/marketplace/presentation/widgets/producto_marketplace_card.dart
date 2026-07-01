import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/producto_marketplace.dart';
import 'favorito_button.dart';

/// Card de producto estilo MercadoLibre para el marketplace
class ProductoMarketplaceCard extends StatelessWidget {
  final ProductoMarketplace producto;
  final VoidCallback? onTap;
  final bool compact;

  const ProductoMarketplaceCard({
    super.key,
    required this.producto,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final empresa = producto.empresa;
    final precioFinal = producto.precioFinal;
    final tieneDescuento = producto.tieneDescuento;
    final descuentoPct = producto.descuentoPct;

    final mq = MediaQuery.of(context);
    // Decodificar al ancho real de la card (~mitad de pantalla) en vez de a
    // resolución completa: menos RAM y decode más rápido en listas largas.
    final imgCacheW = (mq.size.width / 2 * mq.devicePixelRatio).round();
    final logoCacheW = (14 * mq.devicePixelRatio).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con badges
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Container(
                    color: Colors.grey.shade50,
                    // Padding para que la imagen no quede pegada al borde de la card.
                    padding: const EdgeInsets.all(10),
                    child: producto.imagen != null
                        ? CachedNetworkImage(
                            imageUrl: producto.imagen!,
                            fit: BoxFit.contain,
                            memCacheWidth: imgCacheW,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (_, __) => _buildPlaceholder(),
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                // Badge de descuento
                if (tieneDescuento && descuentoPct > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$descuentoPct% OFF',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Badge agotado o nuevo
                if (!producto.hayStock)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AGOTADO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (producto.esNuevo)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.blue2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NUEVO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Marca badge
                if (producto.marca != null)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        producto.marca!,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                // Favorito
                if (FavoritoButton.isLoaded)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: FavoritoButton(
                        productoId: producto.id,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            // Separador sutil
            Container(height: 0.5, color: Colors.grey.shade100),

            // Info del producto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Precio (protagonista, azul de marca) + tachado si hay oferta
                    if (precioFinal != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '${producto.tieneVariantes ? 'Desde ' : ''}S/ ${precioFinal.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                                color: AppColors.blue1,
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (tieneDescuento) ...[
                            const SizedBox(width: 5),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                'S/ ${producto.precio!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else
                      Text(
                        'Consultar',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.blue2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 3),

                    // Rating compacto + vendidos (prueba social)
                    if (producto.tieneCalificacion || producto.vendidos > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            if (producto.tieneCalificacion) ...[
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                              const SizedBox(width: 2),
                              Text(
                                producto.calificacion!.toStringAsFixed(1),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 2),
                              Text('(${producto.totalOpiniones})',
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                            ],
                            if (producto.tieneCalificacion && producto.vendidos > 0)
                              Text('  ·  ', style: TextStyle(fontSize: 9, color: Colors.grey.shade300)),
                            if (producto.vendidos > 0)
                              Text('${_fmtVendidos(producto.vendidos)} vendidos',
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                    // Nombre
                    Expanded(
                      child: Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    if (!compact) ...[
                    const SizedBox(height: 6),

                    // Empresa con logo
                    Row(
                      children: [
                        if (empresa.logo != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: CachedNetworkImage(
                              imageUrl: empresa.logo!,
                              width: 14,
                              height: 14,
                              fit: BoxFit.cover,
                              memCacheWidth: logoCacheW,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.storefront,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.storefront, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            empresa.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.blue2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (empresa.ubicacion.isNotEmpty || producto.distancia != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          if (producto.distancia != null) ...[
                            Text(
                              _formatDistance(producto.distancia!),
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (empresa.ubicacion.isNotEmpty)
                              Text(' · ', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                          ],
                          Expanded(
                            child: Text(
                              empresa.ubicacion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                            ),
                          ),
                          // Botón WhatsApp
                          if (empresa.telefono != null && empresa.telefono!.isNotEmpty)
                            GestureDetector(
                              onTap: () => _openWhatsApp(
                                  empresa.telefono!, producto.nombre, precioFinal, empresa.nombre),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.chat,
                                  size: 14,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else if (empresa.telefono != null && empresa.telefono!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _openWhatsApp(
                              empresa.telefono!, producto.nombre, precioFinal, empresa.nombre),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat, size: 12, color: Color(0xFF25D366)),
                                SizedBox(width: 4),
                                Text(
                                  'Consultar',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF25D366), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    ], // cierre if (!compact)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWhatsApp(String telefono, String producto, num? precio, String empresa) {
    // Formatear número para WhatsApp (Perú: +51)
    String numero = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (numero.startsWith('9') && numero.length == 9) {
      numero = '51$numero';
    }

    // Mensaje con detalle del producto
    final precioStr = precio != null ? 'S/ ${precio.toStringAsFixed(2)}' : 'sin precio definido';
    final mensaje = Uri.encodeComponent(
      'Hola $empresa, me interesa el producto:\n\n'
      '*$producto*\n'
      'Precio: $precioStr\n\n'
      'Vi este producto en Syncronize Marketplace. ¿Podrían darme más información?',
    );

    final url = Uri.parse('https://wa.me/$numero?text=$mensaje');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _fmtVendidos(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 4),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

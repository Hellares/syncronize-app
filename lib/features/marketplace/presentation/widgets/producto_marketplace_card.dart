import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../carrito/presentation/widgets/carrito_badge.dart';
import '../../../carrito/presentation/widgets/fly_to_cart.dart';
import '../../domain/entities/producto_marketplace.dart';
import 'favorito_button.dart';
import 'mini_countdown_bar.dart';

/// Card de producto estilo MercadoLibre para el marketplace
class ProductoMarketplaceCard extends StatelessWidget {
  final ProductoMarketplace producto;
  final VoidCallback? onTap;
  final bool compact;

  /// En el grid masonry (alto variable) la imagen toma su proporción real para
  /// que las cards se escalonen tipo Temu. En grids de celda fija (favoritos,
  /// perfil de tienda) debe quedar en false para no exceder la celda y romper
  /// el layout (overflow).
  final bool staggered;

  /// Botón pequeño de "agregar" a la derecha del precio (solo se renderiza si
  /// se provee). Lo usa Solicitar Cotización: tap en la card = ver detalle,
  /// este botón = agregar al carrito de la solicitud.
  final VoidCallback? onAgregarTap;

  /// Ícono de carrito de la página (destino de la animación "vuela al
  /// carrito"). Si la página no tiene uno, la miniatura vuela a la esquina
  /// superior derecha, donde suele estar.
  final GlobalKey? cartIconKey;

  const ProductoMarketplaceCard({
    super.key,
    required this.producto,
    this.onTap,
    this.compact = false,
    this.staggered = false,
    this.onAgregarTap,
    this.cartIconKey,
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

    // Tipografías más pequeñas en modo compacto (carruseles).
    final double fsPrecio = compact ? 10 : 14;
    final double fsPrecioTachado = compact ? 8 : 10;
    final double fsRating = compact ? 8.5 : 10;
    final double fsMeta = compact ? 7.5 : 9;
    final double fsNombre = compact ? 7.5 : 10;
    final double starSize = compact ? 9 : 12;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Cards totalmente cuadradas y pegadas (grid tipo Temu edge-to-edge),
        // sin sombra. Borde sutil SOLO en el grid principal (staggered) como
        // separador; en carruseles/otros van completamente blancas.
        borderRadius: BorderRadius.zero,
        border: staggered
            ? Border.all(color: Colors.grey.shade200, width: 0.5)
            : null,
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
                  // Solo en el grid masonry usamos la proporción real de la
                  // imagen (escalonado tipo Temu); en carruseles y grids de
                  // celda fija mantenemos el alto fijo para no romper el layout.
                  aspectRatio: staggered ? producto.aspectRatioImagen : 1.2,
                  child: Padding(
                    // Margen para que la imagen no quede pegada al borde de la card
                    // (más ajustado en modo compacto).
                    padding: EdgeInsets.all(compact ? 3 : 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.grey.shade50,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            producto.imagen != null
                                ? CachedNetworkImage(
                                    imageUrl: producto.imagen!,
                                    fit: BoxFit.contain,
                                    memCacheWidth: imgCacheW,
                                    fadeInDuration: const Duration(milliseconds: 150),
                                    placeholder: (_, __) => _buildPlaceholder(),
                                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Badge de descuento
                if (tieneDescuento && descuentoPct > 0)
                  Positioned(
                    top: compact ? 6 : 10,
                    left: compact ? 6 : 10,
                    child: Container(
                      padding: compact
                          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5)
                          : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(compact ? 3 : 4),
                      ),
                      child: Text(
                        '$descuentoPct% OFF',
                        style: TextStyle(
                          fontSize: compact ? 7 : 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Badge agotado o nuevo
                if (!producto.hayStock)
                  Positioned(
                    top: 10,
                    right: 10,
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
                    top: 10,
                    right: 10,
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
                // Marca badge (el countdown ya no se superpone a la imagen, va
                // debajo, así que queda en su posición fija).
                if (producto.marca != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
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
                    top: 8,
                    right: 8,
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

            // Countdown de oferta (estilo Temu): "EXPIRA EN:" + dígitos en
            // cajitas verdes + botón agregar al carrito, justo debajo de la
            // imagen. Solo en cards grandes (no en carruseles compact) y si hay
            // stock para el botón.
            if (!compact && producto.enOferta && producto.ofertaFin != null)
              MiniCountdownBar(
                fin: producto.ofertaFin!,
                onAddToCart: producto.hayStock
                    ? () => _agregarAlCarrito(context)
                    : null,
              ),

            // Separador sutil
            Container(height: 0.5, color: Colors.grey.shade100),

            // Info del producto (sin Expanded → la card se ajusta a su
            // contenido para el masonry/staggered grid).
            Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(6, 4, 6, 4)
                  : const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                                fontSize: fsPrecio,
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
                                  fontSize: fsPrecioTachado,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                          if (onAgregarTap != null) ...[
                            const Spacer(),
                            _buildAgregarBtn(),
                          ],
                        ],
                      ),
                    ] else
                      Row(
                        children: [
                          Text(
                            'Consultar',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.blue2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (onAgregarTap != null) ...[
                            const Spacer(),
                            _buildAgregarBtn(),
                          ],
                        ],
                      ),

                    const SizedBox(height: 3),

                    // Rating compacto + vendidos (prueba social)
                    if (producto.tieneCalificacion || producto.vendidos > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            if (producto.tieneCalificacion) ...[
                              Icon(Icons.star_rounded, size: starSize, color: const Color(0xFFFFB300)),
                              const SizedBox(width: 2),
                              Text(
                                producto.calificacion!.toStringAsFixed(1),
                                style: TextStyle(fontSize: fsRating, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 2),
                              Text('(${producto.totalOpiniones})',
                                  style: TextStyle(fontSize: fsMeta, color: Colors.grey.shade400)),
                            ],
                            if (producto.tieneCalificacion && producto.vendidos > 0)
                              Text('  ·  ', style: TextStyle(fontSize: fsMeta, color: Colors.grey.shade300)),
                            if (producto.vendidos > 0)
                              Text('${_fmtVendidos(producto.vendidos)} vendidos',
                                  style: TextStyle(fontSize: fsMeta, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                    // Nombre (sin Expanded → la tienda queda justo debajo, sin
                    // el hueco que dejaba el Expanded).
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fsNombre,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    // Descripción (si hay), debajo del nombre — solo cards
                    // grandes; máx 2 líneas, letra 8.
                    if (!compact &&
                        producto.descripcion != null &&
                        producto.descripcion!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        producto.descripcion!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          height: 1.2,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],

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
          ],
        ),
      ),
    );
  }

  /// Agrega el producto directamente al carrito desde la card. Los productos
  /// con variantes requieren elegir una en el detalle, así que ahí navegamos
  /// en vez de agregar a ciegas.
  Future<void> _agregarAlCarrito(BuildContext context) async {
    if (producto.tieneVariantes) {
      onTap?.call();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    // Capturar los anclajes de la animación ANTES de los awaits (después el
    // contexto de la card puede ya no estar montado).
    final cardBox = context.findRenderObject() as RenderBox?;
    final start = cardBox != null && cardBox.attached
        ? cardBox.localToGlobal(cardBox.size.center(Offset.zero))
        : null;
    final mq = MediaQuery.of(context);
    final fallbackEnd = Offset(mq.size.width - 40, mq.padding.top + 32);
    final token = await locator<SecureStorageService>()
        .read(key: StorageConstants.accessToken);
    if (token == null || token.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Inicia sesión para agregar al carrito')),
      );
      return;
    }
    try {
      await locator<DioClient>().post(
        '/marketplace/carrito',
        data: {'productoId': producto.id, 'cantidad': 1},
      );
      var flyOk = false;
      if (context.mounted) {
        flyOk = await flyToCart(
          context: context,
          from: start,
          toKey: cartIconKey,
          to: fallbackEnd,
          imageUrl: producto.imagen,
        );
      }
      CarritoBadgeController.add(1);
      if (!flyOk) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Producto agregado al carrito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains('stock')
          ? 'Stock insuficiente'
          : 'Error al agregar al carrito';
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
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

  /// Botón compacto de agregar (a la derecha del precio).
  Widget _buildAgregarBtn() {
    return GestureDetector(
      onTap: onAgregarTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: AppColors.blue1,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_shopping_cart,
            size: 13, color: Colors.white),
      ),
    );
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

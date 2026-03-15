import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card de producto estilo MercadoLibre para el marketplace
class ProductoMarketplaceCard extends StatelessWidget {
  final Map<String, dynamic> producto;
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
    final nombre = producto['nombre'] as String? ?? '';
    final precio = producto['precio'] as num?;
    final precioOferta = producto['precioOferta'] as num?;
    final enOferta = producto['enOferta'] as bool? ?? false;
    final imagen = producto['imagen'] as String?;
    final marca = producto['marca'] as String?;
    final empresa = producto['empresa'] as Map<String, dynamic>? ?? {};
    final empresaNombre = empresa['nombre'] as String? ?? '';
    final empresaLogo = empresa['logo'] as String?;
    final telefono = empresa['telefono'] as String?;
    final ubicacion = empresa['ubicacion'] as String? ?? '';
    final hayStock = producto['hayStock'] as bool? ?? false;
    final creadoEn = producto['creadoEn'] as String?;

    final precioFinal = enOferta && precioOferta != null ? precioOferta : precio;
    final tieneDescuento = enOferta && precioOferta != null && precio != null;
    final esNuevo = creadoEn != null &&
        DateTime.now().difference(DateTime.parse(creadoEn)).inDays <= 2;
    final descuentoPct = tieneDescuento && precio > 0
        ? ((1 - precioOferta / precio) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                    child: imagen != null
                        ? Image.network(
                            imagen,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
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
                if (!hayStock)
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
                else if (esNuevo)
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
                if (marca != null)
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
                        marca,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
                    // Precio
                    if (precioFinal != null) ...[
                      if (tieneDescuento) ...[
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade400,
                          ),
                        ),
                      ],
                      Text(
                        'S/ ${precioFinal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                          color: tieneDescuento ? Colors.green.shade600 : Colors.black87,
                          height: 1.1,
                        ),
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

                    // Envío gratis simulado (para productos con stock)
                    if (hayStock && precioFinal != null && precioFinal > 100)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Envío disponible',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Nombre
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.0,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    if (!compact) ...[
                    const SizedBox(height: 6),

                    // Empresa con logo
                    Row(
                      children: [
                        if (empresaLogo != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.network(
                              empresaLogo,
                              width: 14,
                              height: 14,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
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
                            empresaNombre,
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

                    if (ubicacion.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              ubicacion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                            ),
                          ),
                          // Botón WhatsApp
                          if (telefono != null && telefono.isNotEmpty)
                            GestureDetector(
                              onTap: () => _openWhatsApp(telefono, nombre, precioFinal, empresaNombre),
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
                    ] else if (telefono != null && telefono.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _openWhatsApp(telefono, nombre, precioFinal, empresaNombre),
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

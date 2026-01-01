import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/producto_list_item.dart';

class ProductoListTile extends StatelessWidget {
  final ProductoListItem producto;
  final VoidCallback onTap;
  final VoidCallback? onManageFiles;
  final VoidCallback? onViewVariants;

  const ProductoListTile({
    super.key,
    required this.producto,
    required this.onTap,
    this.onManageFiles,
    this.onViewVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        gradient:AppGradients.blueWhiteBlue(), // Gradiente sutil para las cards
        borderRadius: BorderRadius.circular(12),
        shadowStyle: ShadowStyle.glow, // Efecto neumórfico elegante
        borderColor: AppColors.blueborder,
        borderWidth: 0.8,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Imagen posicionada a la izquierda
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 95,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: producto.imagenPrincipal != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            producto.imagenPrincipal!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                          ),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              // Contenido principal
              Padding(
                padding: EdgeInsets.only(
                  left: 107, // 95 (imagen) + 12 (spacing)
                  top: 6,
                  bottom: 8,
                  right: onManageFiles != null
                      ? 40
                      : 10, // Espacio para botón adjuntar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    // const SizedBox(height: 8),
                    _buildFooter(),
                  ],
                ),
              ),

              // Botón de gestionar archivos en esquina superior derecha
              if (onManageFiles != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onManageFiles,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          border: Border.all(
                            color: AppColors.cardBackground,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.attach_file,
                          size: 14,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea 1: Nombre + Estrella destacado
        Row(
          children: [
            Expanded(
              child: Text(
                producto.nombre,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (producto.destacado) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ],
        ),

        // Línea 2: SKU • Categoría • Marca (todo en una línea)
        const SizedBox(height: 6),
        Row(
          children: [
            // SKU
            if (producto.codigoEmpresa.isNotEmpty) ...[
              Icon(Icons.tag, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                producto.codigoEmpresa,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[700],
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Separador SKU - Categoría
            if (producto.codigoEmpresa.isNotEmpty &&
                producto.categoriaNombre != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '•',
                  style: TextStyle(color: Colors.grey[400], fontSize: 9),
                ),
              ),
            ],

            // Categoría
            if (producto.categoriaNombre != null) ...[
              Icon(Icons.category_outlined, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  producto.categoriaNombre!,
                  style: TextStyle(fontSize: 9, color: Colors.grey[700], fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Separador Categoría - Marca
            if (producto.categoriaNombre != null &&
                producto.marcaNombre != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '•',
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ),
            ],

            // Marca
            if (producto.marcaNombre != null) ...[
              Icon(Icons.verified, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  producto.marcaNombre!,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[700],
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular)
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Separador visual
        Container(
          height: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        // Línea 1: Precio con descuento + badge de descuento inline
        if (producto.isOfertaActiva) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'S/ ${producto.precioEfectivo.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'S/ ${producto.precio.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                ),
              ),
              // Badge de descuento inline con fecha
              if (producto.porcentajeDescuento != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-${producto.porcentajeDescuento!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (producto.ofertaFechaFin != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.schedule,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('dd/MM/yy').format(producto.ofertaFechaFin!),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ] else ...[
          Text(
            'S/ ${producto.precioEfectivo.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],

        // Línea 2: Stock badge + COMBO badge (horizontal)
        const SizedBox(height: 8),
        Row(
          children: [
            // Stock badge
            _buildStockBadge(),

            // COMBO badge
            if (producto.esCombo) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                    width: 0.6
                  ),
                ),
                child: AppSubtitle(
                  'COMBO',
                  fontSize: 8,
                  color: Colors.purple,
                ),
              ),
            ],

            // VARIANTES badge
            if (producto.tieneVariantes) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewVariants,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 0.6
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.widgets, size: 10, color: Colors.blue),
                        const SizedBox(width: 4),
                        AppSubtitle(
                          'VARIANTES',
                          fontSize: 8,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Línea 3: Badge de INACTIVO (si aplica)
        if (!producto.isActive) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off, size: 11, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text(
                  'INACTIVO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockBadge() {
    final hasStock = producto.stock > 0;
    final isLowStock = producto.isStockLow;

    Color badgeColor;
    IconData icon;
    String badgeText;

    if (!hasStock) {
      badgeColor = Colors.red;
      icon = Icons.remove_circle_outline;
      badgeText = '0';
    } else if (isLowStock) {
      badgeColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
      badgeText = '${producto.stock}';
    } else {
      badgeColor = Colors.green;
      icon = Icons.check_circle_outline;
      badgeText = '${producto.stock}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          AppSubtitle( 
            'Stock: $badgeText',
            fontSize: 9,
            color: badgeColor,
          ),
        ],
      ),
    );
  }
}

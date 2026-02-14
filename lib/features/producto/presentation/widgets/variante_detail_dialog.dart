import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/producto_variante.dart';

/// Muestra un diálogo con los detalles completos de una variante de producto.
void showVarianteDetailDialog({
  required BuildContext context,
  required ProductoVariante variante,
}) {
  final screenSize = MediaQuery.of(context).size;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Detalle variante',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Container(
          width: screenSize.width * 0.88,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: _VarianteDetailContent(variante: variante),
          ),
        ),
      );
    },
  );
}

class _VarianteDetailContent extends StatefulWidget {
  final ProductoVariante variante;

  const _VarianteDetailContent({required this.variante});

  @override
  State<_VarianteDetailContent> createState() => _VarianteDetailContentState();
}

class _VarianteDetailContentState extends State<_VarianteDetailContent> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  List<ProductoVarianteArchivo> get _archivosImagenes {
    final archivos = widget.variante.archivos;
    if (archivos == null || archivos.isEmpty) return [];
    return archivos;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variante = widget.variante;
    final stocks = variante.stocksPorSede;
    final imagenes = _archivosImagenes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carrusel de imágenes
        if (imagenes.isNotEmpty)
          _buildImageCarousel(imagenes),

        // Contenido scrollable
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre + Estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        variante.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ),
                    if (!variante.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'INACTIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Códigos
                _buildDetailRow(Icons.tag, 'Código', variante.codigoEmpresa),
                _buildDetailRow(Icons.qr_code, 'SKU', variante.sku),
                if (variante.codigoBarras != null && variante.codigoBarras!.isNotEmpty)
                  _buildDetailRow(Icons.qr_code_scanner, 'Código de barras', variante.codigoBarras!),

                // Unidad de medida
                if (variante.unidadMedida != null)
                  _buildDetailRow(Icons.straighten, 'Unidad', variante.unidadDisplayCompleto),

                // Peso
                if (variante.peso != null)
                  _buildDetailRow(Icons.scale, 'Peso', '${variante.peso} kg'),

                // Dimensiones
                if (variante.dimensiones != null && variante.dimensiones!.isNotEmpty)
                  _buildDetailRow(Icons.aspect_ratio, 'Dimensiones', _formatDimensiones(variante.dimensiones!)),

                // Atributos
                if (variante.atributosValores.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Atributos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...variante.atributosValores.map((av) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            av.atributo.nombre,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue1,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            av.valor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],

                // Stock por sede
                if (stocks != null && stocks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Stock por sede',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...stocks.map((stock) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.store, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stock.sedeNombre,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (stock.cantidad > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${stock.cantidad}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stock.cantidad > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        if (stock.precioConfigurado && stock.precio != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'S/ ${stock.precioEfectivo?.toStringAsFixed(2) ?? stock.precio!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stock.isOfertaActiva ? Colors.green : AppColors.textPrimary,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
                ],

                // Fechas
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.calendar_today, 'Creado', DateFormatter.formatDateTime(variante.creadoEn)),
                _buildDetailRow(Icons.update, 'Actualizado', DateFormatter.formatDateTime(variante.actualizadoEn)),
              ],
            ),
          ),
        ),

        // Botón cerrar
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cerrar'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(List<ProductoVarianteArchivo> imagenes) {
    if (imagenes.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        child: Image.network(
          imagenes.first.url,
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            color: Colors.grey[200],
            child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imagenes.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  imagenes[index].url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imagenes.length, (index) {
            return Container(
              width: _currentImageIndex == index ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _currentImageIndex == index
                    ? AppColors.blue1
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatDimensiones(Map<String, dynamic> dimensiones) {
  final parts = <String>[];
  if (dimensiones['largo'] != null) parts.add('L: ${dimensiones['largo']}');
  if (dimensiones['ancho'] != null) parts.add('A: ${dimensiones['ancho']}');
  if (dimensiones['alto'] != null) parts.add('Al: ${dimensiones['alto']}');
  return parts.isNotEmpty ? parts.join(' × ') : '-';
}

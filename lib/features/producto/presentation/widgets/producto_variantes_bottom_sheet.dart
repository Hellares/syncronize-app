import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/services/storage_service.dart';
import 'package:syncronize/core/di/injection_container.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_variante/producto_variante_cubit.dart';
import '../bloc/producto_variante/producto_variante_state.dart';
import 'archivo_manager_bottom_sheet.dart';

class ProductoVariantesBottomSheet extends StatefulWidget {
  final String productoId;
  final String empresaId;
  final String productoNombre;

  const ProductoVariantesBottomSheet({
    super.key,
    required this.productoId,
    required this.empresaId,
    required this.productoNombre,
  });

  static void show({
    required BuildContext context,
    required String productoId,
    required String empresaId,
    required String productoNombre,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductoVariantesBottomSheet(
        productoId: productoId,
        empresaId: empresaId,
        productoNombre: productoNombre,
      ),
    );
  }

  @override
  State<ProductoVariantesBottomSheet> createState() => _ProductoVariantesBottomSheetState();
}

class _ProductoVariantesBottomSheetState extends State<ProductoVariantesBottomSheet> {

  Future<void> _showArchivoManager(ProductoVariante variante) async {
    try {
      // Obtener archivos existentes de la variante
      final storageService = locator<StorageService>();
      final archivosResponse = await storageService.getFilesByEntity(
        empresaId: widget.empresaId,
        entidadTipo: 'PRODUCTO_VARIANTE',
        entidadId: variante.id,
      );

      // Convertir a ArchivoItem
      final archivosExistentes = archivosResponse.map((archivo) {
        TipoArchivo tipo;
        if (archivo.mimeType.startsWith('image/')) {
          tipo = TipoArchivo.imagen;
        } else if (archivo.mimeType == 'application/pdf') {
          tipo = TipoArchivo.pdf;
        } else {
          tipo = TipoArchivo.otro;
        }

        return ArchivoItem(
          id: archivo.id,
          url: archivo.url,
          urlThumbnail: archivo.urlThumbnail,
          nombreOriginal: archivo.nombreOriginal,
          tipoArchivo: tipo,
          isLocal: false,
        );
      }).toList();

      if (!mounted) return;

      // Mostrar bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ArchivoManagerBottomSheet(
          entidadId: variante.id,
          entidadNombre: variante.nombre,
          entidadTipo: 'PRODUCTO_VARIANTE',
          empresaId: widget.empresaId,
          storageService: storageService,
          archivosExistentes: archivosExistentes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar archivos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load variants when bottom sheet opens
    context.read<ProductoVarianteCubit>().loadVariantes(
          productoId: widget.productoId,
          empresaId: widget.empresaId,
        );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: BlocBuilder<ProductoVarianteCubit, ProductoVarianteState>(
              builder: (context, state) {
                if (state is ProductoVarianteLoading) {
                  return _buildLoading();
                }

                if (state is ProductoVarianteError) {
                  return _buildError(state.message);
                }

                if (state is ProductoVarianteLoaded ||
                    state is ProductoVarianteOperationSuccess) {
                  final variantes = state is ProductoVarianteLoaded
                      ? state.variantes
                      : (state as ProductoVarianteOperationSuccess).variantes;

                  if (variantes.isEmpty) {
                    return _buildEmpty();
                  }

                  return _buildVariantesList(variantes);
                }

                return _buildEmpty();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              const Icon(
                Icons.widgets,
                color: AppColors.blue1,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTitle(
                      'Variantes',
                      fontSize: 16,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.productoNombre,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay variantes disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantesList(List<ProductoVariante> variantes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      itemCount: variantes.length,
      itemBuilder: (context, index) {
        final variante = variantes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildVarianteCard(variante),
        );
      },
    );
  }

  Widget _buildVarianteCard(ProductoVariante variante) {
    // Obtener precios desde stocksPorSede (sistema multi-sede)
    final _stocks = variante.stocksPorSede;
    final _stockInfo = _stocks != null && _stocks.isNotEmpty
        ? (_stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull ?? _stocks.first)
        : null;
    final hasOferta = _stockInfo?.isOfertaActiva ?? false;
    final precioActual = _stockInfo?.precioEfectivo ?? 0.0;
    final precioOriginal = _stockInfo?.precio ?? 0.0;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderRadius: BorderRadius.circular(12),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.cardBackground,
      borderWidth: 0.8,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header: Nombre + Estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    variante.nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ),
                if (!variante.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'INACTIVO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),

            // SKU
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.tag, size: 11, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  variante.codigoEmpresa,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
              ],
            ),

            // Atributos (Color, Talla, etc.)
            if (variante.atributosValores.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: variante.atributosValores.map((av) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${av.atributo.nombre}: ${av.valor}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[700],
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Separator
            Container(
              height: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),

            // Footer: Precio + Stock
            Row(
              children: [
                // Precio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasOferta) ...[
                        Row(
                          children: [
                            Text(
                              'S/ ${precioActual.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'S/ ${precioOriginal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'S/ ${precioActual.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stock Badge
                _buildStockBadge(variante),
              ],
            ),
          ],
        ),
      ),

      // Botón de gestionar archivos en esquina superior derecha
      Positioned(
        top: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showArchivoManager(variante),
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
    );
  }

  Widget _buildStockBadge(ProductoVariante variante) {
    final hasStock = variante.stockTotal > 0;
    final isStockLow = variante.isStockLowTotal;

    Color badgeColor;
    IconData icon;
    String badgeText;

    if (!hasStock) {
      badgeColor = Colors.red;
      icon = Icons.remove_circle_outline;
      badgeText = '0';
    } else if (isStockLow) {
      badgeColor = Colors.orange;
      icon = Icons.warning;
      badgeText = '${variante.stockTotal}';
    } else {
      badgeColor = Colors.green;
      icon = Icons.check_circle_outline;
      badgeText = '${variante.stockTotal}';
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/confirm_dialog.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/product_image_gallery.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import 'package:syncronize/features/producto/domain/entities/producto.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../domain/repositories/precio_nivel_repository.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/producto_detail/producto_detail_cubit.dart';
import '../bloc/producto_detail/producto_detail_state.dart';
import '../bloc/producto_list/producto_list_cubit.dart';
import '../widgets/producto_variantes_section.dart';
import '../widgets/variante_plantilla_atributos_dialog.dart';
import '../widgets/oferta_countdown_timer.dart';
import '../../domain/entities/producto_variante.dart';

class ProductoDetailPage extends StatefulWidget {
  final String productoId;
  final String? sedeId; // Sede seleccionada para mostrar precios y stock específicos
  final Producto? productoData; // Producto ya cargado (opcional, evita petición duplicada)

  const ProductoDetailPage({
    super.key,
    required this.productoId,
    this.sedeId,
    this.productoData,
  });

  @override
  State<ProductoDetailPage> createState() => _ProductoDetailPageState();
}

class _ProductoDetailPageState extends State<ProductoDetailPage> {
  ProductoVariante? _selectedVariante;
  bool _productoWasEdited = false; // Flag para saber si se editó el producto

  @override
  void initState() {
    super.initState();

    // Si ya tenemos los datos del producto, cargarlos directamente (evita petición duplicada)
    if (widget.productoData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final empresaState = context.read<EmpresaContextCubit>().state;
        if (empresaState is EmpresaContextLoaded) {
          context.read<ProductoDetailCubit>().loadProductoFromCache(
            widget.productoData!,
            empresaState.context.empresa.id,
          );
        }
      });
    } else {
      // Solo hacer petición si no tenemos datos previos
      _loadProducto();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadProducto() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<ProductoDetailCubit>().loadProducto(
        productoId: widget.productoId,
        empresaId: empresaState.context.empresa.id,
      );
    }
  }

  /// Obtiene las imágenes para el slider según el contexto:
  /// - Si hay variante seleccionada: muestra sus imágenes
  /// - Si tiene variantes sin selección: imágenes del producto + todas las de variantes
  /// - Si no tiene variantes: solo imágenes del producto
  List<String> _getImagenesParaSlider(Producto producto) {
    // Si hay una variante seleccionada, mostrar sus imágenes
    if (_selectedVariante != null) {
      final varianteImages = _selectedVariante!.archivos
              ?.map((a) => a.url)
              .toList() ??
          [];
      // Si la variante no tiene imágenes, mostrar las del producto base
      if (varianteImages.isNotEmpty) return varianteImages;
    }

    final productoImages = producto.imagenes ?? [];

    // Si tiene variantes, combinar imágenes del producto + variantes
    if (producto.tieneVariantes &&
        producto.variantes != null &&
        producto.variantes!.isNotEmpty) {
      final allImages = <String>[...productoImages];
      for (final variante in producto.variantes!) {
        if (variante.archivos != null) {
          allImages.addAll(variante.archivos!.map((a) => a.url));
        }
      }
      return allImages;
    }

    return productoImages;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        // ✅ Retornar true si el producto fue editado
        Navigator.of(context).pop(_productoWasEdited);
      },
      child: Scaffold(
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Detalle del Producto',
          actions: [
          BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
            builder: (context, empresaState) {
              if (empresaState is EmpresaContextLoaded &&
                  empresaState.context.permissions.canManageProducts) {
                return BlocBuilder<ProductoDetailCubit, ProductoDetailState>(
                  builder: (context, productoState) {
                    final productoCargado = productoState is ProductoDetailLoaded
                        ? productoState.producto
                        : null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle activo/inactivo (solo si producto está cargado).
                        // Visible: Icons.visibility (activo) / Icons.visibility_off (inactivo).
                        if (productoCargado != null)
                          IconButton(
                            icon: Icon(
                              productoCargado.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: productoCargado.isActive
                                  ? AppColors.white
                                  : Colors.amber,
                            ),
                            tooltip: productoCargado.isActive
                                ? 'Desactivar producto'
                                : 'Activar producto',
                            onPressed: () => _toggleActive(
                              context,
                              productoCargado,
                              empresaState.context.empresa.id,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () async {
                            final productoData = productoCargado;
                            final detailCubit = context.read<ProductoDetailCubit>();
                            final empresaId = empresaState.context.empresa.id;
                            final result = await context.push(
                              '/empresa/productos/${widget.productoId}/editar',
                              extra: productoData,
                            );
                            if (!mounted) return;
                            if (result != null && result is Producto) {
                              detailCubit.loadProductoFromCache(result, empresaId);
                              setState(() {
                                _productoWasEdited = true;
                              });
                            }
                          },
                          tooltip: 'Editar',
                        ),
                        // Eliminar (soft delete → papelera).
                        if (productoCargado != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Eliminar producto',
                            onPressed: () => _eliminar(
                              context,
                              productoCargado,
                              empresaState.context.empresa.id,
                            ),
                          ),
                      ],
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocConsumer<ProductoDetailCubit, ProductoDetailState>(
          listener: (context, state) {
            if (state is ProductoDetailLoaded) {
              // Almacenar producto fresco en el cache del list cubit
              context.read<ProductoListCubit>().cacheProductoCompleto(state.producto);
            }
          },
          builder: (context, state) {
            if (state is ProductoDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductoDetailError) {
              return _buildErrorView(state.message);
            }

            if (state is ProductoDetailLoaded) {
              final producto = state.producto;
              final empresaState = context.read<EmpresaContextCubit>().state;
              final empresaId = empresaState is EmpresaContextLoaded
                  ? empresaState.context.empresa.id
                  : '';

              return RefreshIndicator(
                onRefresh: () async => _loadProducto(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slider sin padding - ocupa toda la pantalla
                      ProductImageGallery(
                        images: _getImagenesParaSlider(producto),
                        videoUrl: producto.videoUrl,
                        heroTag: 'product-image-${producto.id}',
                      ),
                      _buildHeader(producto),
                      // Resto del contenido con padding
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _buildHeader(producto),
                            // const SizedBox(height: 16),
                            _buildPriceSection(producto),
                            const SizedBox(height: 16),

                            if (!producto.tieneVariantes && !producto.esCombo) ...[
                              _buildNivelesPrecioSection(producto.id),
                              _buildAtributosManagerSection(producto),
                              const SizedBox(height: 16),
                            ],

                            if (producto.tieneVariantes &&
                                producto.variantes != null &&
                                producto.variantes!.isNotEmpty) ...[
                              ProductoVariantesSection(
                                variantes: producto.variantes!,
                                selectedVariante: _selectedVariante,
                                empresaId: empresaId,
                                productoId: producto.id,
                                onVarianteSelected: (variante) {
                                  setState(() {
                                    _selectedVariante = variante;
                                  });
                                },
                                onAtributosChanged: _loadProducto,
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildInfoSection(producto),
                            const SizedBox(height: 18),

                            if (producto.descripcion != null) ...[
                              _buildDescripcionSection(producto.descripcion!),
                              const SizedBox(height: 18),
                            ],
                            if (producto.videoUrl != null) ...[
                              _buildVideoSection(producto.videoUrl!),
                              const SizedBox(height: 18),
                            ],

                            _buildMetadataSection(producto),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    )
    );
  }

  Widget _buildHeader(dynamic producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
          color: AppColors.bluechip,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
              if (producto.destacado)
                InfoChip(icon: Icons.star, text: 'Destacado', textColor: AppColors.amberText ,backgroundColor: AppColors.amberShadow,borderRadius: 4,)
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Códigos del producto
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (producto.sku != null)
              _buildCodeChip('SKU', producto.sku!, Icons.qr_code),
            if (producto.codigoBarras != null)
              _buildCodeChip(
                'Código Barras',
                producto.codigoBarras!,
                Icons.barcode_reader,
              ),
            _buildCodeChip(
              'Código Empresa',
              producto.codigoEmpresa,
              Icons.business,
            ),
            // _buildCodeChip(
            //   'Código Sistema',
            //   producto.codigoSistema,
            //   Icons.computer,
            // ),
          ],
        ),

        // Estado del producto
        if (!producto.isActive) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Text(
                  'Producto Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeChip(String label, String value, IconData icon) {
    return InfoChip(
      text: '$label: $value',
      icon: icon,
      backgroundColor: AppColors.blueborder.withValues(alpha: 0.1),
      textColor: AppColors.blue1,
      borderRadius: 4,
    );
  }

  Widget _buildPriceSection(dynamic producto) {
    // Precios y stock se obtienen desde stocksPorSede (sistema multi-sede)
    double precioMostrar = 0.0;
    double precioEfectivoMostrar = 0.0;
    int stockMostrar = producto.stockTotal ?? 0;
    bool isOfertaActivaSede = false;
    bool isLiquidacionActivaSede = false;
    String? motivoLiquidacionLabel;
    double? porcentajeDescuentoSede;
    DateTime? fechaInicioOfertaSede;
    DateTime? fechaFinOfertaSede;
    DateTime? fechaInicioLiquidacionSede;
    DateTime? fechaFinLiquidacionSede;
    bool tienePrecioConfigurado = false;
    dynamic stockSede;

    // Si hay sede seleccionada, buscar los datos específicos de esa sede
    if (widget.sedeId != null && producto.stocksPorSede != null) {
      try {
        stockSede = producto.stocksPorSede!.firstWhere(
          (s) => s.sedeId == widget.sedeId,
        );

        // Stock de la sede
        stockMostrar = stockSede.cantidad ?? 0;

        // Precios de la sede (si están configurados)
        if (stockSede.precioConfigurado && stockSede.precio != null) {
          tienePrecioConfigurado = true;
          precioMostrar = stockSede.precio!;

          // PRIORIDAD: liquidación gana sobre oferta (la autorización
          // gerencial ya fue dada al activarla y el precio suele ser
          // menor — es el evento comercial más relevante para el cliente).
          final liquidacionVigente = (stockSede.isLiquidacionActiva ?? false) == true &&
              stockSede.precioLiquidacion != null &&
              stockSede.precioLiquidacion! < stockSede.precio!;
          final ofertaVigente = stockSede.enOferta == true &&
              stockSede.precioOferta != null &&
              stockSede.precioOferta! < stockSede.precio!;

          if (liquidacionVigente) {
            isLiquidacionActivaSede = true;
            precioEfectivoMostrar = stockSede.precioLiquidacion!;
            porcentajeDescuentoSede = ((precioMostrar - precioEfectivoMostrar) / precioMostrar) * 100;
            fechaInicioLiquidacionSede = stockSede.fechaInicioLiquidacion;
            fechaFinLiquidacionSede = stockSede.fechaFinLiquidacion;
            motivoLiquidacionLabel = stockSede.motivoLiquidacion?.label;
          } else if (ofertaVigente) {
            isOfertaActivaSede = true;
            precioEfectivoMostrar = stockSede.precioOferta!;
            porcentajeDescuentoSede = ((precioMostrar - precioEfectivoMostrar) / precioMostrar) * 100;
            fechaInicioOfertaSede = stockSede.fechaInicioOferta;
            fechaFinOfertaSede = stockSede.fechaFinOferta;
          } else {
            precioEfectivoMostrar = precioMostrar;
          }
        } else {
          tienePrecioConfigurado = false;
        }
      } catch (e) {
        // Si no se encuentra stock en la sede seleccionada, usar valores por defecto
      }
    }

    final hasStock = stockMostrar > 0;

    // Estado visual prioritario: liquidación > oferta > base.
    final tieneDescuento = isLiquidacionActivaSede || isOfertaActivaSede;
    final colorDescuento = isLiquidacionActivaSede
        ? Colors.deepOrange.shade700
        : (isOfertaActivaSede ? AppColors.amberText : AppColors.blueborder);

    return GradientContainer(
      gradient: isLiquidacionActivaSede
          ? AppGradients.deepOrangeWhite()
          : (isOfertaActivaSede
              ? AppGradients.orangeWhiteBlue()
              : AppGradients.blueWhiteBlue()),
      borderColor: colorDescuento,
      // En liquidación el deepOrange del borde + ShadowStyle.colorful
      // genera una sombra naranja oscura debajo que "opaca" el bloque.
      // Usamos customShadows con gris suave que da profundidad sin tinte.
      shadowStyle: isLiquidacionActivaSede
          ? ShadowStyle.none
          : ShadowStyle.colorful,
      // Replica del efecto ShadowStyle.colorful pero con un naranja
      // más claro (shade300 en vez de shade700) para que realce sin
      // que la sombra se vea oscura/opaca.
      customShadows: isLiquidacionActivaSede
          ? [
              BoxShadow(
                color: Colors.deepOrange.shade300.withValues(alpha: 0.43),
                offset: const Offset(0, 3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ]
          : null,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLiquidacionActivaSede
                    ? Icons.local_fire_department
                    : Icons.monetization_on_outlined,
                color: colorDescuento,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Precio y Stock',
                style: TextStyle(
                  fontSize: 12,
                  color: tieneDescuento ? colorDescuento : AppColors.blue1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!tienePrecioConfigurado) ...[
            const Text(
              'Sin precio configurado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (tieneDescuento) ...[
            // Precio base tachado
            Text(
              'S/${precioMostrar.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey[700],
                decorationThickness: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'S/${precioEfectivoMostrar.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: isLiquidacionActivaSede
                        ? Colors.deepOrange.shade700
                        : AppColors.blue1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                InfoChip(
                  text: isLiquidacionActivaSede
                      ? 'LIQUIDACIÓN'
                      : '${porcentajeDescuentoSede?.toStringAsFixed(0) ?? '0'}% OFF',
                  backgroundColor: isLiquidacionActivaSede
                      ? Colors.deepOrange.shade700
                      : AppColors.red,
                  textColor: Colors.white,
                  icon: isLiquidacionActivaSede
                      ? Icons.local_fire_department
                      : Icons.local_offer,
                  iconSize: 14,
                  borderRadius: 4,
                ),
                if (isLiquidacionActivaSede && porcentajeDescuentoSede != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '-${porcentajeDescuentoSede.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ] else
            Text(
              'S/${precioEfectivoMostrar.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppColors.blue1,
                height: 1.0,
              ),
            ),
          const SizedBox(height: 12),

          // Detalle de liquidación si aplica (motivo + fechas).
          // Container con fondo blanco puro: el bloque exterior ya tiene
          // el tinte naranja del gradient, asi que mantener este bloque
          // blanco da contraste y reposo visual.
          if (isLiquidacionActivaSede) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.deepOrange.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          size: 14, color: Colors.deepOrange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Liquidación activa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (motivoLiquidacionLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Motivo: $motivoLiquidacionLabel',
                      style: TextStyle(fontSize: 10, color: Colors.grey[800]),
                    ),
                  ],
                  if (fechaInicioLiquidacionSede != null)
                    Text(
                      'Desde: ${DateFormatter.formatDateTime(fechaInicioLiquidacionSede)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  if (fechaFinLiquidacionSede != null)
                    Text(
                      'Hasta: ${DateFormatter.formatDateTime(fechaFinLiquidacionSede)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    )
                  else
                    Text(
                      'Sin vencimiento (hasta desactivación manual)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Fechas de oferta si aplica
          if (isOfertaActivaSede) ...[
            GradientContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              gradient: AppGradients.blueWhiteBlue(),
              borderColor: AppColors.orange,
              shadowStyle: ShadowStyle.none,
              // ========================================
              // OPCIÓN 3: STACK CON POSITIONED
              // Libertad total de posicionamiento
              // ========================================
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppCaption(color: AppColors.amberText ,items:[CaptionItem(icon: Icons.local_offer, text: 'Oferta Activa')] )
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (fechaInicioOfertaSede != null)
                        AppSubtitle(
                          'Desde: ${DateFormatter.formatDateTime(fechaInicioOfertaSede)}',
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      if (fechaFinOfertaSede != null)
                        AppSubtitle(
                          'Hasta: ${DateFormatter.formatDateTime(fechaFinOfertaSede)}',
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                    ],
                  ),
                  // Countdown posicionado donde quieras
                  Positioned(
                    right: 15,
                    top: -13,  // top, bottom, left, right
                    child: OfertaCountdownTimer(
                      fechaInicio: fechaInicioOfertaSede,
                      fechaFin: fechaFinOfertaSede,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Stock y estado
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                text: 'Stock: $stockMostrar',
                icon: hasStock ? Icons.check_circle : Icons.cancel,
                textColor: hasStock ? AppColors.blue1 : AppColors.red,
                iconSize: 14,
                borderRadius: 4,
              ),
              if (stockSede != null)
                InfoChip(
                  text: 'Stock en Sede ${stockSede.sedeNombre}',
                  icon: Icons.warehouse,
                  textColor: AppColors.blue1,
                  // backgroundColor: AppColors.blueborder.withValues(alpha: 0.1),
                  iconSize: 14,
                borderRadius: 4,
                ),
              if (producto.visibleMarketplace)
                InfoChip(
                  text: 'Marketplace',
                  icon: Icons.store,
                  textColor: AppColors.blue1,
                  iconSize: 14,
                  borderRadius: 4,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic producto) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Información General',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const AppSubtitle('INFORMACIÓN GENERAL'),
            const SizedBox(height: 10),

            // Categoría
            _buildInfoRow(
              'Categoría',
              producto.categoria?.nombre ?? 'Sin categoría',
            ),

            // Marca con logo
            if (producto.marca != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Marca',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        if (producto.marca.logo != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: producto.marca.logo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const SizedBox.shrink(),
                              errorWidget: (context, url, error) {
                                return const Icon(Icons.business, size: 24);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          producto.marca.nombre,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              _buildInfoRow('Marca', 'Sin marca'),

            // Sede
            if (producto.sede != null)
              _buildInfoRow('Sede', producto.sede!.nombre),

            const Divider(height: 24),

            // Precios y costos (desde stocksPorSede)
            if (widget.sedeId != null && producto.stockSedeInfo(widget.sedeId!) != null &&
                producto.stockSedeInfo(widget.sedeId!)!.precioCosto != null)
              _buildInfoRow(
                'Precio de costo',
                'S/${producto.stockSedeInfo(widget.sedeId!)!.precioCosto!.toStringAsFixed(2)}',
              ),
            if (producto.impuestoPorcentaje != null)
              _buildInfoRow('Impuesto', '${producto.impuestoPorcentaje}%'),
            if (producto.descuentoMaximo != null)
              _buildInfoRow('Descuento máximo', '${producto.descuentoMaximo}%'),

            const Divider(height: 12),

            // Stock por sedes (nuevo sistema multi-sede)
            if (producto.stocksPorSede != null && producto.stocksPorSede!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AppSubtitle('STOCK POR SEDE'),
              ),
              ...producto.stocksPorSede!.map((stockSede) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppText('${stockSede.sedeNombre} (${stockSede.sedeCodigo})', size: 10,),
                    ),
                    Row(
                      children: [
                        AppText(
                          '${stockSede.cantidad}',
                          color: stockSede.esCritico ? AppColors.red : stockSede.esBajoMinimo ? AppColors.amberText : AppColors.blue1, 
                          fontWeight: FontWeight.bold,
                        ),
                        if (stockSede.stockMinimo != null) ...[
                          Text(
                            ' / ${stockSede.stockMinimo}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                          ),
                          if (stockSede.esBajoMinimo)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.warning,
                                size: 16,
                                color: AppColors.amberText,
                              ),
                            ),
                        ],
                        if (stockSede.ubicacion != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Tooltip(
                              message: 'Ubicación: ${stockSede.ubicacion}',
                              child: const Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )),
            ],

            const Divider(height: 12),

            // Dimensiones y peso
            if (producto.peso != null)
              _buildInfoRow('Peso', '${producto.peso} kg'),
            if (producto.dimensiones != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dimensiones',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    ...producto.dimensiones!.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(left: 12, top: 2),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcionSection(String descripcion) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('DESCRIPCIÓN'),
            const SizedBox(height: 5),
            Text(descripcion, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(String videoUrl) {
      return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 16),
                const SizedBox(width: 8),
                // const Text(
                //   'Video del Producto',
                //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                // ),
                const AppSubtitle('VIDEO DEL PRODUCTO'),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.videocam, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      videoUrl,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 16,),
                    onPressed: () {
                      // Aquí podrías agregar lógica para abrir el video
                      // Por ejemplo: launch(videoUrl);
                    },
                    tooltip: 'Abrir video',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributosManagerSection(dynamic producto) {
    final tieneAtributos =
        producto.atributosValores != null &&
        producto.atributosValores!.isNotEmpty;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return const SizedBox.shrink();

    return GradientContainer(
      // color: tieneAtributos ? null : Colors.orange.shade50,
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.colorful,
      child: InkWell(
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => VariantePlantillaAtributosDialog(
              empresaId: empresaState.context.empresa.id,
              productoId: producto.id,
              nombre: producto.nombre,
            ),
          );

          if (result == true && mounted) {
            _loadProducto(); // Recargar para ver cambios
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 6),
          child: tieneAtributos
              ? _buildAtributosContent(producto.atributosValores!)
              : _buildNoAtributosContent(),
        ),
      ),
    );
  }

  Widget _buildAtributosContent(List atributosValores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.tune, color: Colors.blue.shade700, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: AppSubtitle('Caracteristicas del Producto'),
            ),
            Icon(Icons.edit, size: 16, color: Colors.grey[600]),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: atributosValores.map((atributoValor) {
            return InfoChip(icon: Icons.label, text: '${atributoValor.atributo.nombre} : ${atributoValor.valor}' , font: AppFont.oxygenBold, borderRadius: 4, fontSize: 10,);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoAtributosContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atributos no asignados',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 2),
              AppSubtitle('Toca aquí para asignar atributos técnicos', fontSize: 10,font: AppFont.oxygenRegular,)
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange.shade700),
      ],
    );
  }

  Widget _buildMetadataSection(dynamic producto) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('INFORMACIÓN DEL SISTEMA'),
            const SizedBox(height: 10),
            _buildInfoRow('ID', producto.id),
            _buildInfoRow('Empresa ID', producto.empresaId),
            if (producto.sedeId != null)
              _buildInfoRow('Sede ID', producto.sedeId!),
            if (producto.empresaCategoriaId != null)
              _buildInfoRow('Categoría ID', producto.empresaCategoriaId!),
            if (producto.empresaMarcaId != null)
              _buildInfoRow('Marca ID', producto.empresaMarcaId!),

            const Divider(height: 24),

            if (producto.ordenMarketplace != null)
              _buildInfoRow(
                'Orden Marketplace',
                producto.ordenMarketplace.toString(),
              ),
            _buildInfoRow('Estado', producto.isActive ? 'Activo' : 'Inactivo'),

            const Divider(height: 24),

            _buildInfoRow('Creado', DateFormatter.formatDateTime(producto.creadoEn)),
            _buildInfoRow('Actualizado', DateFormatter.formatDateTime(producto.actualizadoEn)),
            if (producto.deletedAt != null)
              _buildInfoRow('Eliminado', DateFormatter.formatDateTime(producto.deletedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            AppSubtitle(
              message,
              textAlign: TextAlign.center,
              fontSize: 14,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Reintentar',
              onPressed: _loadProducto,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              backgroundColor: AppColors.red,
              borderColor: AppColors.red,
              height: 45,
            ),
          ],
        ),
      ),
    );
    // Cierre del PopScope
  }

  /// Sección read-only que muestra los niveles de precio configurados para
  /// el producto (descuentos por volumen). Si no hay niveles, no renderiza
  /// nada — para evitar ruido visual en productos sin configuración.
  /// Para gestionar (crear/editar/eliminar) se usa el dialog "Configurar
  /// Precios" del stock por sede.
  Widget _buildNivelesPrecioSection(String productoId) {
    return FutureBuilder<Resource<List<PrecioNivel>>>(
      future: locator<PrecioNivelRepository>()
          .getPreciosNivelProducto(productoId: productoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        if (result is! Success<List<PrecioNivel>>) return const SizedBox.shrink();
        final activos = result.data.where((n) => n.isActive).toList()
          ..sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));
        if (activos.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GradientContainer(
            gradient: AppGradients.blueWhiteDialog(),
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_graph,
                        size: 16, color: AppColors.blue1),
                    const SizedBox(width: 6),
                    AppSubtitle(
                      'Precios por Volumen',
                      fontSize: 13,
                      color: AppColors.blue1,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${activos.length} ${activos.length == 1 ? 'nivel' : 'niveles'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...activos.map((n) => _buildNivelRow(n)),
                const SizedBox(height: 4),
                Text(
                  'Para editar usa "Configurar Precios" en stock por sede.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNivelRow(PrecioNivel n) {
    final esFijo = n.tipoPrecio == TipoPrecioNivel.precioFijo;
    final color = esFijo ? AppColors.blue1 : Colors.orange.shade700;
    final icon = esFijo ? Icons.attach_money : Icons.percent;
    final valor = esFijo
        ? 'S/ ${(n.precio ?? 0).toStringAsFixed(2)}'
        : '${(n.porcentajeDesc ?? 0).toStringAsFixed(0)}% off';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  n.nombre,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  n.rangoString,
                  style: TextStyle(
                      fontSize: 9, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Elimina el producto (soft delete → papelera). Pide confirmación clara
  /// explicando que se puede restaurar después. Al éxito navega atrás al
  /// listado e invalida la lista para que desaparezca.
  Future<void> _eliminar(
    BuildContext context,
    Producto producto,
    String empresaId,
  ) async {
    final confirma = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Eliminar producto',
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${producto.nombre}" se moverá a la papelera.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• No aparecerá en POS, Venta Rápida ni listado normal.\n'
            '• Las ventas históricas que lo incluyen se mantienen intactas.\n'
            '• Podés restaurarlo desde "Productos eliminados".',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      confirmText: 'Eliminar',
    );
    if (confirma != true) return;
    if (!context.mounted) return;

    final repo = locator<ProductoRepository>();
    final listCubit = context.read<ProductoListCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await repo.eliminarProducto(
      productoId: producto.id,
      empresaId: empresaId,
    );
    if (!mounted) return;

    if (result is Success<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Producto "${producto.nombre}" enviado a la papelera',
          ),
          backgroundColor: Colors.red.shade600,
          action: SnackBarAction(
            label: 'Ver papelera',
            textColor: Colors.white,
            onPressed: () {
              context.push('/empresa/productos/eliminados');
            },
          ),
        ),
      );
      listCubit.reload();
      // Volver al listado: el producto eliminado ya no debería estar visible.
      _productoWasEdited = true;
      navigator.pop(_productoWasEdited);
    } else if (result is Error<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Activa o desactiva el producto (toggle isActive). Pide confirmación,
  /// llama al endpoint y refresca el detalle + invalida el listado.
  Future<void> _toggleActive(
    BuildContext context,
    Producto producto,
    String empresaId,
  ) async {
    final activando = !producto.isActive;
    final confirma = await ConfirmDialog.show(
      context: context,
      type: activando
          ? ConfirmDialogType.success
          : ConfirmDialogType.warning,
      title: activando ? 'Activar producto' : 'Desactivar producto',
      message: activando
          ? '"${producto.nombre}" volverá a estar disponible para venta '
              'en POS y Venta Rápida.'
          : '"${producto.nombre}" dejará de aparecer en POS y Venta Rápida. '
              'No se elimina, solo se oculta. Podés volver a activarlo cuando quieras.',
      confirmText: activando ? 'Activar' : 'Desactivar',
    );
    if (confirma != true) return;
    if (!context.mounted) return;

    final repo = locator<ProductoRepository>();
    final detailCubit = context.read<ProductoDetailCubit>();
    final listCubit = context.read<ProductoListCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await repo.toggleActiveProducto(productoId: producto.id);
    if (!mounted) return;

    if (result is Success<bool>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.data ? 'Producto activado' : 'Producto desactivado',
          ),
          backgroundColor: result.data ? Colors.green : Colors.orange,
        ),
      );
      // Recargar detalle (para que el isActive se refleje) e invalidar listado.
      detailCubit.reload();
      listCubit.reload();
      setState(() {
        _productoWasEdited = true;
      });
    } else if (result is Error<bool>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

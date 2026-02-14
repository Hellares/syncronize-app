import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/product_image_gallery.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import 'package:syncronize/features/producto/domain/entities/producto.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/producto_detail/producto_detail_cubit.dart';
import '../bloc/producto_detail/producto_detail_state.dart';
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
                    return IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () async {
                        // Pasar el producto completo si ya está cargado para evitar petición duplicada
                        final productoData = productoState is ProductoDetailLoaded
                          ? productoState.producto
                          : null;

                        // Guardar referencias antes del await para evitar usar BuildContext desactualizado
                        final detailCubit = context.read<ProductoDetailCubit>();
                        final empresaId = empresaState.context.empresa.id;

                        // Esperar el resultado del formulario
                        final result = await context.push(
                          '/empresa/productos/${widget.productoId}/editar',
                          extra: productoData,
                        );

                        // ✅ Si retorna un producto actualizado, recargarlo
                        if (!mounted) return;
                        if (result != null && result is Producto) {
                          detailCubit.loadProductoFromCache(result, empresaId);
                          // Marcar que el producto fue editado
                          setState(() {
                            _productoWasEdited = true;
                          });
                        }
                      },
                      tooltip: 'Editar',
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
        child: BlocBuilder<ProductoDetailCubit, ProductoDetailState>(
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
                        images: producto.imagenes ?? [],
                        videoUrl: producto.videoUrl,
                        heroTag: 'product-image-${producto.id}',
                      ),

                      // Resto del contenido con padding
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(producto),
                            const SizedBox(height: 16),
                            _buildPriceSection(producto),
                            const SizedBox(height: 16),

                            if (!producto.tieneVariantes && !producto.esCombo) ...[
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
        Row(
          children: [
            Expanded(
              child: Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (producto.destacado)
              InfoChip(icon: Icons.star, text: 'Destacado', textColor: AppColors.amberText ,backgroundColor: AppColors.amberShadow,)
          ],
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
    );
  }

  Widget _buildPriceSection(dynamic producto) {
    // Precios y stock se obtienen desde stocksPorSede (sistema multi-sede)
    double precioMostrar = 0.0;
    double precioEfectivoMostrar = 0.0;
    int stockMostrar = producto.stockTotal ?? 0;
    bool isOfertaActivaSede = false;
    double? porcentajeDescuentoSede;
    DateTime? fechaInicioOfertaSede;
    DateTime? fechaFinOfertaSede;
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

          // Verificar si hay oferta activa en esta sede
          if (stockSede.enOferta == true &&
              stockSede.precioOferta != null &&
              stockSede.precioOferta! < stockSede.precio!) {
            isOfertaActivaSede = true;
            precioEfectivoMostrar = stockSede.precioOferta!;
            porcentajeDescuentoSede = ((precioMostrar - precioEfectivoMostrar) / precioMostrar) * 100;
            fechaInicioOfertaSede = stockSede.fechaInicioOferta;
            fechaFinOfertaSede = stockSede.fechaFinOferta;
          } else {
            isOfertaActivaSede = false;
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

    return GradientContainer(
      gradient: isOfertaActivaSede
          ? AppGradients.orangeWhiteBlue()
          : AppGradients.blueWhiteBlue(),
      borderColor: isOfertaActivaSede
          ? AppColors.amberText
          : AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on_outlined,
                color: isOfertaActivaSede
                    ? AppColors.amberText
                    : AppColors.blueborder,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Precio y Stock',style: TextStyle(fontSize: 12, color: isOfertaActivaSede ? AppColors.amberText : AppColors.blue1, fontWeight: FontWeight.bold),)
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
          ] else if (isOfertaActivaSede) ...[
            AppSubtitle(
              'S/${precioMostrar.toStringAsFixed(2)}',
              fontSize: 12,
              color: Colors.grey[600],
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
                    color: AppColors.blue1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                InfoChip(
                  text:
                      '${porcentajeDescuentoSede?.toStringAsFixed(0) ?? '0'}% OFF',
                  backgroundColor: AppColors.red,
                  textColor: Colors.white,
                  icon: Icons.local_offer,
                ),
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
          const SizedBox(height: 16),

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
              ),
              if (stockSede != null)
                InfoChip(
                  text: 'Stock en Sede ${stockSede.sedeNombre}',
                  icon: Icons.warehouse,
                  textColor: AppColors.blue1,
                  backgroundColor: AppColors.blueborder.withValues(alpha: 0.1),
                ),
              if (producto.visibleMarketplace)
                InfoChip(
                  text: 'Marketplace',
                  icon: Icons.store,
                  textColor: AppColors.blue1,
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
                            child: Image.network(
                              producto.marca.logo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
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

            const Divider(height: 24),

            // Stock por sedes (nuevo sistema multi-sede)
            if (producto.stocksPorSede != null && producto.stocksPorSede!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Stock por Sede',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...producto.stocksPorSede!.map((stockSede) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${stockSede.sedeNombre} (${stockSede.sedeCodigo})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${stockSede.cantidad}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: stockSede.esCritico
                              ? AppColors.red
                              : stockSede.esBajoMinimo
                                ? AppColors.amberText
                                : AppColors.blue1,
                          ),
                        ),
                        if (stockSede.stockMinimo != null) ...[
                          Text(
                            ' / ${stockSede.stockMinimo}',
                            style: const TextStyle(
                              fontSize: 12,
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

            const Divider(height: 24),

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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/producto_detail/producto_detail_cubit.dart';
import '../bloc/producto_detail/producto_detail_state.dart';
import '../widgets/producto_variantes_section.dart';
import '../widgets/variante_plantilla_atributos_dialog.dart';
import '../../domain/entities/producto_variante.dart';

class ProductoDetailPage extends StatefulWidget {
  final String productoId;

  const ProductoDetailPage({
    super.key,
    required this.productoId,
  });

  @override
  State<ProductoDetailPage> createState() => _ProductoDetailPageState();
}

class _ProductoDetailPageState extends State<ProductoDetailPage> {
  ProductoVariante? _selectedVariante;

  @override
  void initState() {
    super.initState();
    _loadProducto();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        actions: [
          BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
            builder: (context, empresaState) {
              if (empresaState is EmpresaContextLoaded &&
                  empresaState.context.permissions.canManageProducts) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.push('/empresa/productos/${widget.productoId}/editar');
                  },
                  tooltip: 'Editar',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductoDetailCubit, ProductoDetailState>(
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
                onRefresh: () async {
                  _loadProducto();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageGallery(producto.imagenes ?? []),
                      const SizedBox(height: 16),
                      _buildHeader(producto),
                      const SizedBox(height: 16),
                      _buildPriceSection(producto),
                      const SizedBox(height: 16),
                      // Gestión de atributos (solo para productos sin variantes)
                      if (!producto.tieneVariantes && !producto.esCombo) ...[
                        _buildAtributosManagerSection(producto),
                        const SizedBox(height: 16),
                      ],
                      // Sección de variantes
                      if (producto.tieneVariantes && producto.variantes != null && producto.variantes!.isNotEmpty) ...[
                        ProductoVariantesSection(
                          variantes: producto.variantes!,
                          selectedVariante: _selectedVariante,
                          empresaId: empresaId,
                          onVarianteSelected: (variante) {
                            setState(() {
                              _selectedVariante = variante;
                            });
                          },
                          onAtributosChanged: _loadProducto,
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildInfoSection(producto),
                      const SizedBox(height: 24),
                      if (producto.descripcion != null) ...[
                        _buildDescripcionSection(producto.descripcion!),
                        const SizedBox(height: 24),
                      ],
                      if (producto.videoUrl != null) ...[
                        _buildVideoSection(producto.videoUrl!),
                        const SizedBox(height: 24),
                      ],
                      _buildMetadataSection(producto),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),    
      );
  }

  Widget _buildImageGallery(List<String> imagenes) {
    if (imagenes.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagenes[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (producto.destacado)
              const Chip(
                avatar: Icon(Icons.star, size: 18, color: Colors.amber),
                label: Text('Destacado'),
                backgroundColor: Colors.amber,
              ),
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
              _buildCodeChip('Código Barras', producto.codigoBarras!, Icons.barcode_reader),
            _buildCodeChip('Código Empresa', producto.codigoEmpresa, Icons.business),
            _buildCodeChip('Código Sistema', producto.codigoSistema, Icons.computer),
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
                    fontSize: 12,
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
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildPriceSection(dynamic producto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.isOfertaActiva) ...[
              Text(
                '\$${producto.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '\$${producto.precioEfectivo.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(
                      '${producto.porcentajeDescuento.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
            ] else
              Text(
                '\$${producto.precioEfectivo.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),

            // Fechas de oferta si aplica
            if (producto.isOfertaActiva) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_offer, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Oferta Activa',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (producto.fechaInicioOferta != null || producto.fechaFinOferta != null) ...[
                      const SizedBox(height: 8),
                      if (producto.fechaInicioOferta != null)
                        Text(
                          'Desde: ${_formatDate(producto.fechaInicioOferta)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      if (producto.fechaFinOferta != null)
                        Text(
                          'Hasta: ${_formatDate(producto.fechaFinOferta)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Stock y estado
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  'Stock: ${producto.stock}',
                  producto.hasStock ? Icons.check_circle : Icons.cancel,
                  producto.hasStock ? Colors.green : Colors.red,
                ),
                if (producto.isStockLow)
                  _buildInfoChip(
                    'Stock Bajo',
                    Icons.warning,
                    Colors.orange,
                  ),
                if (producto.visibleMarketplace)
                  _buildInfoChip(
                    'Marketplace',
                    Icons.store,
                    Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildInfoSection(dynamic producto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Categoría
            _buildInfoRow('Categoría', producto.categoria?.nombre ?? 'Sin categoría'),

            // Marca con logo
            if (producto.marca != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Marca',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
                            fontSize: 14,
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

            // Precios y costos
            if (producto.precioCosto != null)
              _buildInfoRow('Precio de costo', '\$${producto.precioCosto!.toStringAsFixed(2)}'),
            if (producto.impuestoPorcentaje != null)
              _buildInfoRow('Impuesto', '${producto.impuestoPorcentaje}%'),
            if (producto.descuentoMaximo != null)
              _buildInfoRow('Descuento máximo', '${producto.descuentoMaximo}%'),

            const Divider(height: 24),

            // Stock
            if (producto.stockMinimo != null)
              _buildInfoRow('Stock mínimo', producto.stockMinimo.toString()),

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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...producto.dimensiones!.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcionSection(String descripcion) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(String videoUrl) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Video del Producto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
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
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
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
    final tieneAtributos = producto.atributosValores != null && producto.atributosValores!.isNotEmpty;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: tieneAtributos ? null : Colors.orange.shade50,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tune, color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Atributos del Producto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.edit, size: 18, color: Colors.grey[600]),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: atributosValores.map((atributoValor) {
            return Chip(
              avatar: Icon(Icons.label, size: 16, color: Colors.blue.shade700),
              label: Text('${atributoValor.atributo.nombre}: ${atributoValor.valor}'),
              backgroundColor: Colors.blue.shade50,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoAtributosContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atributos no asignados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca aquí para asignar atributos técnicos',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange.shade700),
      ],
    );
  }

  Widget _buildMetadataSection(dynamic producto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
              _buildInfoRow('Orden Marketplace', producto.ordenMarketplace.toString()),
            _buildInfoRow('Estado', producto.isActive ? 'Activo' : 'Inactivo'),

            const Divider(height: 24),

            _buildInfoRow('Creado', _formatDate(producto.creadoEn)),
            _buildInfoRow('Actualizado', _formatDate(producto.actualizadoEn)),
            if (producto.deletedAt != null)
              _buildInfoRow('Eliminado', _formatDate(producto.deletedAt!)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducto,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

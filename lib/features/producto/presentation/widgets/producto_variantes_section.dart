import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../data/datasources/producto_remote_datasource.dart';
import '../../domain/entities/producto_variante.dart';
import 'variante_detail_dialog.dart';
import 'variante_plantilla_atributos_dialog.dart';

class ProductoVariantesSection extends StatefulWidget {
  final List<ProductoVariante> variantes;
  final Function(ProductoVariante)? onVarianteSelected;
  final ProductoVariante? selectedVariante;
  final String empresaId;
  final String productoId;
  final VoidCallback? onAtributosChanged;

  const ProductoVariantesSection({
    super.key,
    required this.variantes,
    this.onVarianteSelected,
    this.selectedVariante,
    required this.empresaId,
    required this.productoId,
    this.onAtributosChanged,
  });

  @override
  State<ProductoVariantesSection> createState() =>
      _ProductoVariantesSectionState();
}

class _ProductoVariantesSectionState extends State<ProductoVariantesSection> {
  ProductoVariante? _selectedVariante;
  Map<String, ProductoVariante> _variantesCompletas = {};

  @override
  void initState() {
    super.initState();
    _selectedVariante = widget.selectedVariante ?? widget.variantes.firstOrNull;
    _fetchVariantesCompletas();
  }

  Future<void> _fetchVariantesCompletas() async {
    if (widget.variantes.isEmpty) return;
    try {
      final datasource = locator<ProductoRemoteDataSource>();
      final variantes = await datasource.getVariantes(
        productoId: widget.productoId,
        empresaId: widget.empresaId,
      );
      if (mounted) {
        setState(() {
          _variantesCompletas = {
            for (final v in variantes) v.id: v,
          };
        });
      }
    } catch (e) {
      debugPrint('Error al cargar variantes completas: $e');
    }
  }

  /// Obtiene la variante enriquecida con archivos si está disponible.
  ProductoVariante _getVarianteCompleta(ProductoVariante variante) {
    return _variantesCompletas[variante.id] ?? variante;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 16),
                const SizedBox(width: 8),
                const AppSubtitle('VARIANTES DISPONIBLES'),
                const Spacer(),
                Text(
                  '${widget.variantes.length} opciones',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Atributos de la variante seleccionada
            if (_selectedVariante != null) ...[
              _buildAtributosChips(_selectedVariante!),
              // const SizedBox(height: 6),
              const Divider(),
              // const SizedBox(height: 6),
            ],

            // Lista de variantes
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.variantes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final variante = widget.variantes[index];
                final isSelected = _selectedVariante?.id == variante.id;

                return _buildVarianteCard(variante, isSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributosChips(ProductoVariante variante) {
    if (variante.atributosValores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: variante.atributosValores.map((atributoValor) {
        return InfoChip(
          icon: Icons.label,
          text: '${atributoValor.atributo.nombre}: ${atributoValor.valor}',
          backgroundColor: AppColors.white,
          borderColor: AppColors.blue2,
          borderRadius: 4,
          fontSize: 10,
        );
        



      }).toList(),
    );
  }



  Widget _buildVarianteCard(ProductoVariante variante, bool isSelected) {
    // Obtener precio desde stocksPorSede (sistema multi-sede)
    final stocks = variante.stocksPorSede;
    final stockInfo = stocks != null && stocks.isNotEmpty
        ? (stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull ?? stocks.first)
        : null;
    final precioEfectivoDisplay = stockInfo?.precioEfectivo ?? 0.0;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVariante = variante;
        });
        widget.onVarianteSelected?.call(variante);
      },
      onLongPress: () => showVarianteDetailDialog(
        context: context,
        variante: _getVarianteCompleta(variante),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Imagen miniatura si existe
                if (_getVarianteCompleta(variante).imagenPrincipal != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      _getVarianteCompleta(variante).thumbnailPrincipal!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Información de la variante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              variante.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.blue.shade900
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          // Botón para gestionar atributos
                          IconButton(
                            icon: Icon(
                              Icons.tune,
                              size: 18,
                              color: variante.atributosValores.isEmpty
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            tooltip: 'Gestionar atributos',
                            onPressed: () => _mostrarGestionAtributos(variante),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // const SizedBox(width: 4),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                        ],
                      ),
                      // const SizedBox(height: 4),
                      Text(
                        'SKU: ${variante.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Precio y stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Precio (desde stocksPorSede)
                Text(
                  'S/${precioEfectivoDisplay.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),

                // Stock
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStockColor(variante).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStockColor(variante)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStockIcon(variante),
                        size: 14,
                        color: _getStockColor(variante),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${variante.stockTotal}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStockColor(variante),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Estado inactivo
            if (!variante.isActive) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Inactiva',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
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

  Color _getStockColor(ProductoVariante variante) {
    if (variante.isOutOfStockTotal) return Colors.red;
    if (variante.isStockLowTotal) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon(ProductoVariante variante) {
    if (variante.isOutOfStockTotal) return Icons.cancel;
    if (variante.isStockLowTotal) return Icons.warning;
    return Icons.check_circle;
  }

  Future<void> _mostrarGestionAtributos(ProductoVariante variante) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => VariantePlantillaAtributosDialog(
        empresaId: widget.empresaId,
        varianteId: variante.id,
        nombre: variante.nombre,
        // No se pasa plantilla - el diálogo mostrará el selector
      ),
    );

    if (result == true && mounted) {
      widget.onAtributosChanged?.call();
    }
  }
}

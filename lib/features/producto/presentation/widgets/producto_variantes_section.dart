import 'package:flutter/material.dart';
import '../../domain/entities/producto_variante.dart';
import 'variante_plantilla_atributos_dialog.dart';

class ProductoVariantesSection extends StatefulWidget {
  final List<ProductoVariante> variantes;
  final Function(ProductoVariante)? onVarianteSelected;
  final ProductoVariante? selectedVariante;
  final String empresaId;
  final VoidCallback? onAtributosChanged;

  const ProductoVariantesSection({
    super.key,
    required this.variantes,
    this.onVarianteSelected,
    this.selectedVariante,
    required this.empresaId,
    this.onAtributosChanged,
  });

  @override
  State<ProductoVariantesSection> createState() =>
      _ProductoVariantesSectionState();
}

class _ProductoVariantesSectionState extends State<ProductoVariantesSection> {
  ProductoVariante? _selectedVariante;

  @override
  void initState() {
    super.initState();
    _selectedVariante = widget.selectedVariante ?? widget.variantes.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Variantes Disponibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${widget.variantes.length} opciones',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Atributos de la variante seleccionada
            if (_selectedVariante != null) ...[
              _buildAtributosChips(_selectedVariante!),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
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
        return Chip(
          avatar: _getAtributoIcon(atributoValor.atributo.clave),
          label: Text(
            '${atributoValor.atributo.nombre}: ${atributoValor.valor}',
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: Colors.blue.shade50,
          side: BorderSide(color: Colors.blue.shade200),
        );
      }).toList(),
    );
  }

  Widget _getAtributoIcon(String key) {
    final keyLower = key.toLowerCase();
    IconData icon = Icons.label;

    if (keyLower.contains('color')) {
      icon = Icons.palette;
    } else if (keyLower.contains('talla') || keyLower.contains('tamaño')) {
      icon = Icons.straighten;
    } else if (keyLower.contains('material')) {
      icon = Icons.category;
    } else if (keyLower.contains('capacidad')) {
      icon = Icons.storage;
    } else if (keyLower.contains('conexi') || keyLower.contains('conex')) {
      icon = Icons.cable;
    }

    return Icon(icon, size: 16);
  }

  Widget _buildVarianteCard(ProductoVariante variante, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedVariante = variante;
        });
        widget.onVarianteSelected?.call(variante);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Imagen miniatura si existe
                if (variante.imagenPrincipal != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      variante.thumbnailPrincipal!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
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
                                fontSize: 15,
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
                          const SizedBox(width: 4),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
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

            const SizedBox(height: 12),

            // Precio y stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Precio
                Text(
                  '\$${variante.precioEfectivo.toStringAsFixed(2)}',
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
                        'Stock: ${variante.stock}',
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
    if (variante.isOutOfStock) return Colors.red;
    if (variante.isStockLow) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon(ProductoVariante variante) {
    if (variante.isOutOfStock) return Icons.cancel;
    if (variante.isStockLow) return Icons.warning;
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

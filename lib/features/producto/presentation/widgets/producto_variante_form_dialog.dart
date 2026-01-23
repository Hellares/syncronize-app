import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/precio_nivel/precio_nivel_state.dart';
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import 'precio_niveles_section.dart';
import 'variante_atributos_section.dart';

class ProductoVarianteFormDialog extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive; // Estado del producto padre
  final ProductoVariante? variante;
  final List<ProductoAtributo>? atributosDisponibles;
  final Function(Map<String, dynamic>) onSave;

  const ProductoVarianteFormDialog({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    this.variante,
    this.atributosDisponibles,
    required this.onSave,
  });

  @override
  State<ProductoVarianteFormDialog> createState() =>
      _ProductoVarianteFormDialogState();
}

class _ProductoVarianteFormDialogState
    extends State<ProductoVarianteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _skuController;
  late TextEditingController _codigoBarrasController;
  late TextEditingController _precioController;
  late TextEditingController _precioCostoController;
  late TextEditingController _precioOfertaController;
  late TextEditingController _stockController;
  late TextEditingController _pesoController;

  bool _isActive = true;
  int _orden = 0;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.variante?.nombre);
    _skuController = TextEditingController(text: widget.variante?.sku);
    _codigoBarrasController =
        TextEditingController(text: widget.variante?.codigoBarras);
    _precioController = TextEditingController(
      text: widget.variante?.precio.toStringAsFixed(2),
    );
    _precioCostoController = TextEditingController(
      text: widget.variante?.precioCosto?.toStringAsFixed(2),
    );
    _precioOfertaController = TextEditingController(
      text: widget.variante?.precioOferta?.toStringAsFixed(2),
    );
    // NOTA: El stock ahora se maneja por sede mediante ProductoStock
    // Por compatibilidad temporal, se inicializa en 0
    _stockController = TextEditingController(
      text: widget.variante?.stockTotal.toString() ?? '0',
    );
    _pesoController = TextEditingController(
      text: widget.variante?.peso?.toString(),
    );

    if (widget.variante != null) {
      _isActive = widget.variante!.isActive;
      _orden = widget.variante!.orden;

      // Cargar niveles de precio y atributos de la variante
      Future.microtask(() {
        if (mounted) {
          context.read<PrecioNivelCubit>().loadNivelesVariante(widget.variante!.id);
          // TODO: Get empresaId from auth/storage
          context.read<VarianteAtributoCubit>().loadVarianteAtributos(
            varianteId: widget.variante!.id,
            empresaId: 'empresa-id-placeholder',
          );
        }
      });
    } else {
      // Modo creación - inicializar cubit con lista vacía
      Future.microtask(() {
        if (mounted) {
          context.read<VarianteAtributoCubit>().initialize();
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _skuController.dispose();
    _codigoBarrasController.dispose();
    _precioController.dispose();
    _precioCostoController.dispose();
    _precioOfertaController.dispose();
    _stockController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Widget _buildPrecioNivelesSection() {
    return BlocConsumer<PrecioNivelCubit, PrecioNivelState>(
      listener: (context, state) {
        if (state is PrecioNivelLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<PrecioNivelCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state is PrecioNivelLoading) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is PrecioNivelLoaded) {
          final precioBase = double.tryParse(_precioController.text);

          return PrecioNivelesSection(
            niveles: state.niveles,
            precioBase: precioBase,
            onNivelCreated: (dto) => context
                .read<PrecioNivelCubit>()
                .crearNivelVariante(
                  varianteId: widget.variante!.id,
                  dto: dto,
                ),
            onNivelUpdated: (nivelId, dto) => context
                .read<PrecioNivelCubit>()
                .actualizarNivel(nivelId: nivelId, dto: dto),
            onNivelDeleted: (nivelId) =>
                context.read<PrecioNivelCubit>().eliminarNivel(nivelId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.variante == null
                              ? 'Nueva Variante'
                              : 'Editar Variante',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Producto: ${widget.productoNombre}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Atributos - Sistema unificado para creación y edición
                    VarianteAtributosSection(
                      atributosDisponibles: widget.atributosDisponibles ?? [],
                      showPlantillaButton: true,
                      empresaId: 'empresa-id-placeholder', // TODO: Get from auth/storage
                    ),
                    const SizedBox(height: 24),

                    // Información básica
                    const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la variante *',
                        hintText: 'Ej: Teclado Lenovo Rojo USB',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _skuController,
                                decoration: const InputDecoration(
                                  labelText: 'SKU *',
                                  hintText: 'TEC-LEN-001',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El SKU es requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: Tooltip(
                                message: 'Generar SKU automático',
                                child: OutlinedButton.icon(
                                  onPressed: _generateSKU,
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('Auto'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _codigoBarrasController,
                          decoration: const InputDecoration(
                            labelText: 'Código de barras',
                            prefixIcon: Icon(Icons.barcode_reader),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Precios
                    const Text(
                      'Precios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio de venta *',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El precio es requerido';
                              }
                              final precio = double.tryParse(value);
                              if (precio == null || precio <= 0) {
                                return 'Precio inválido';
                              }

                              // Validar precio >= costo
                              final costoText = _precioCostoController.text.trim();
                              if (costoText.isNotEmpty) {
                                final costo = double.tryParse(costoText);
                                if (costo != null && precio < costo) {
                                  return 'El precio debe ser mayor o igual al costo';
                                }
                              }

                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _precioCostoController,
                            decoration: const InputDecoration(
                              labelText: 'Precio de costo',
                              prefixIcon: Icon(Icons.money_off),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _precioOfertaController,
                      decoration: const InputDecoration(
                        labelText: 'Precio de oferta',
                        hintText: 'Opcional',
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Inventario
                    const Text(
                      'Inventario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // NOTA: El campo de stock ha sido removido porque ahora se gestiona por sede
                    // mediante ProductoStock. El stock se debe agregar/editar desde el módulo de inventario.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El stock se gestiona por sede desde el módulo de inventario',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Niveles de precio (solo en modo edición)
                    if (widget.variante != null) ...[
                      _buildPrecioNivelesSection(),
                      const SizedBox(height: 24),
                    ],

                    // Peso
                    TextFormField(
                      controller: _pesoController,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Estado
                    SwitchListTile(
                      value: _isActive,
                      onChanged: widget.productoIsActive ? (value) {
                        // Validar que no se pueda activar la variante si el padre está inactivo
                        if (value && !widget.productoIsActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se puede activar una variante cuando el producto padre está inactivo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() => _isActive = value);
                      } : null, // Deshabilitar si el padre está inactivo
                      title: const Text('Variante activa'),
                      subtitle: Text(
                        widget.productoIsActive
                            ? 'Las variantes inactivas no se muestran a los clientes'
                            : 'El producto padre está inactivo. Actívalo primero para poder activar variantes.',
                        style: TextStyle(
                          color: widget.productoIsActive ? Colors.grey[600] : Colors.red[600],
                        ),
                      ),
                    ),
                    if (!widget.productoIsActive)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El producto padre debe estar activo para activar variantes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera un SKU automático basado en el producto
  void _generateSKU() {
    // Obtener las primeras 3-4 letras del nombre del producto
    final productPrefix = widget.productoNombre
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase()
        .substring(0, widget.productoNombre.length >= 3 ? 3 : widget.productoNombre.length);

    // Generar timestamp único (últimos 4 dígitos del timestamp)
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;

    // Construir SKU final
    final sku = '$productPrefix-VAR-$timestamp';

    setState(() {
      _skuController.text = sku;
    });

    // Mostrar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SKU generado: $sku'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validación: No permitir crear/activar variante si el producto padre está inactivo
    if (_isActive && !widget.productoIsActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede activar una variante cuando el producto padre está inactivo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener atributos desde el cubit ANTES de cualquier operación async
    final cubit = context.read<VarianteAtributoCubit>();
    final atributosEstructurados = cubit.getAtributosAsDto();

    // Si estamos EDITANDO una variante, guardar atributos primero
    if (widget.variante != null) {
      try {
        // TODO: Get empresaId from auth/storage
        await cubit.saveAtributos(
          varianteId: widget.variante!.id,
          empresaId: 'empresa-id-placeholder',
        );
      } catch (e) {
        // El error ya se muestra en el listener del widget
        return;
      }
    }

    // Verificar que el widget sigue montado después del await
    if (!mounted) return;

    final data = {
      'nombre': _nombreController.text.trim(),
      'sku': _skuController.text.trim(),
      'codigoBarras': _codigoBarrasController.text.trim().isEmpty
          ? null
          : _codigoBarrasController.text.trim(),
      if (atributosEstructurados.isNotEmpty)
        'atributosEstructurados': atributosEstructurados,
      'precio': double.parse(_precioController.text),
      'precioCosto': _precioCostoController.text.isEmpty
          ? null
          : double.parse(_precioCostoController.text),
      'precioOferta': _precioOfertaController.text.isEmpty
          ? null
          : double.parse(_precioOfertaController.text),
      // NOTA: El campo 'stock' ha sido removido del backend.
      // Use ProductoStock para gestionar stock por sede después de crear la variante.
      // 'stock': int.parse(_stockController.text),
      'peso': _pesoController.text.isEmpty
          ? null
          : double.parse(_pesoController.text),
      'isActive': _isActive,
      'orden': _orden,
    };

    widget.onSave(data);
    Navigator.pop(context);
  }
}

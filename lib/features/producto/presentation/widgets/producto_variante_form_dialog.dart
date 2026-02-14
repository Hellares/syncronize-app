import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/theme/gradient_container.dart';
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
  final String empresaId;
  final ProductoVariante? variante;
  final List<ProductoAtributo>? atributosDisponibles;
  final Function(Map<String, dynamic>) onSave;

  const ProductoVarianteFormDialog({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    required this.empresaId,
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
          context.read<VarianteAtributoCubit>().loadVarianteAtributos(
            varianteId: widget.variante!.id,
            empresaId: widget.empresaId,
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
          // Obtener precio base desde stocksPorSede
          final stocks = widget.variante?.stocksPorSede;
          final stockConPrecio = stocks != null && stocks.isNotEmpty
              ? (stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull ?? stocks.first)
              : null;
          final precioBase = stockConPrecio?.precio;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GradientContainer(
        // constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(right: 14, left: 14, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.blue1, size: 18,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle(widget.variante == null ? 'NUEVA VARIANTE' : 'EDITAR VARIANTE'),
                        AppText('Producto: ${widget.productoNombre}',)
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.blue1, size: 18,),
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
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  children: [
                    // Atributos - Sistema unificado para creación y edición
                    VarianteAtributosSection(
                      atributosDisponibles: widget.atributosDisponibles ?? [],
                      showPlantillaButton: true,
                      empresaId: widget.empresaId,
                    ),
                    const SizedBox(height: 16),

                    // Información básica
                    AppSubtitle('INFORMACION BASICA'),
                    const SizedBox(height: 12),

                    CustomText(
                      borderColor: AppColors.blue1,
                      controller: _nombreController,
                      label: 'Nombre de la variante *',
                      hintText: 'Ej: Teclado Lenovo Rojo USB',
                      prefixIcon: Icon(Icons.label),
                      validator: (value){
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: CustomText(
                                controller: _skuController,
                                borderColor: AppColors.blue1,
                                label: 'SKU *',
                                hintText: 'TEC-LEN-001',
                                prefixIcon: Icon(Icons.qr_code_rounded),
                                validator: (value){
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
                              child: Padding(
                                padding: const EdgeInsets.only(top: 13),
                                child: Tooltip(
                                  message: 'Generar SKU automático',
                                  child: FloatingButtonText(
                                    onPressed: _generateSKU,
                                    icon: Icons.auto_awesome,
                                    label: 'Auto',
                                    width: 32,
                                    height: 33,
                                    
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          controller: _codigoBarrasController,
                          borderColor: AppColors.blue1,
                          label: 'Codigo de barras',
                          hintText: 'Codigo de barras',
                          prefixIcon: Icon(Icons.barcode_reader),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Precios y Stock - se gestionan por sede vía ProductoStock
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
                              'Los precios y el stock se gestionan por sede desde el módulo de inventario',
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
        await cubit.saveAtributos(
          varianteId: widget.variante!.id,
          empresaId: widget.empresaId,
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
      // NOTA: Los precios y stock se gestionan vía ProductoStock (por sede).
      // No se envían en la creación/actualización de la variante.
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

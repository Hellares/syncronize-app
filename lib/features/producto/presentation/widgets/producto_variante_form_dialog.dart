import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/barcode_scanner_button.dart';
import '../../data/datasources/producto_remote_datasource.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/precio_nivel/precio_nivel_state.dart';
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import 'form_sections/producto_unidad_presentacion_section.dart';
import 'form_sections/variante_apertura_section.dart';
import 'precio_niveles_section.dart';
import 'variante_atributos_section.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/widgets/unidad_medida_dropdown.dart';

class ProductoVarianteFormDialog extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive; // Estado del producto padre
  final String empresaId;
  final ProductoVariante? variante;
  final List<ProductoAtributo>? atributosDisponibles;

  /// Las otras variantes del mismo producto, para poder elegir en cuál se
  /// convierte ésta al abrirla. Excluye la que se está editando.
  final List<ProductoVariante> variantesHermanas;
  final Function(Map<String, dynamic>) onSave;

  const ProductoVarianteFormDialog({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    required this.empresaId,
    this.variante,
    this.atributosDisponibles,
    this.variantesHermanas = const [],
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

  late TextEditingController _factorPresentacionController;
  late TextEditingController _rendimientoAperturaController;

  bool _isActive = true;
  int _orden = 0;

  /// Mientras se pide el nombre rearmado al backend.
  bool _regenerando = false;

  /// Unidad de VENTA propia. null = hereda la del producto, que es el caso de
  /// casi todas las variantes (colores, tallas).
  String? _unidadMedidaId;
  String? _unidadPresentacionId;
  String? _varianteAperturaId;

  /// Pide al backend el nombre armado desde los atributos de la variante y lo
  /// escribe en el campo.
  ///
  /// Solo toca el CAMPO: recién se persiste al guardar el diálogo, así que si
  /// el resultado no gusta alcanza con cancelar. El endpoint igual lo guarda
  /// del lado del servidor, pero el usuario ve el cambio antes de aceptarlo.
  Future<void> _regenerarNombre() async {
    final variante = widget.variante;
    if (variante == null) return;

    setState(() => _regenerando = true);
    try {
      final data = await locator<ProductoRemoteDataSource>()
          .regenerarNombreVariante(varianteId: variante.id);
      final nombre = data['nombre'] as String?;
      if (!mounted) return;
      if (nombre != null && nombre.isNotEmpty) {
        _nombreController.text = nombre;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo rearmar el nombre. ¿La variante tiene atributos cargados?',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _regenerando = false);
    }
  }

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
    _factorPresentacionController = TextEditingController(
      text: _numTexto(widget.variante?.factorPresentacion),
    );
    _rendimientoAperturaController = TextEditingController(
      text: _numTexto(widget.variante?.rendimientoApertura),
    );
    _unidadMedidaId = widget.variante?.unidadMedidaId;
    _unidadPresentacionId = widget.variante?.unidadPresentacionId;
    _varianteAperturaId = widget.variante?.varianteAperturaId;

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
    _factorPresentacionController.dispose();
    _rendimientoAperturaController.dispose();
    super.dispose();
  }

  /// Un factor de 1000 se escribe "1000", no "1000.0".
  static String? _numTexto(double? v) {
    if (v == null) return null;
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  static double? _parseNum(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
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
                      // Rearma el nombre desde los atributos de la variante.
                      // Va acá y no en el menú de la tarjeta porque ese admite
                      // cuatro ítems como máximo —lo assertea `popup_item`— y
                      // porque al lado del campo es donde uno lo busca.
                      //
                      // Solo al EDITAR: una variante nueva todavía no tiene
                      // atributos con los que armar nada.
                      suffixIcon: widget.variante == null
                          ? null
                          : IconButton(
                              icon: _regenerando
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_fix_high_outlined,
                                      size: 18),
                              color: AppColors.blue1,
                              tooltip: 'Rearmar desde los atributos',
                              onPressed:
                                  _regenerando ? null : _regenerarNombre,
                            ),
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
                          prefixIcon: const Icon(Icons.barcode_reader),
                          suffixIcon: BarcodeScannerButton(
                            onScanned: (code) => _codigoBarrasController.text = code,
                          ),
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
                              'El precio se hereda del producto base. El stock se configura desde inventario.',
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

                    // ─── Unidad propia de la variante ───────────────
                    // Casi ninguna variante la necesita: un color o una talla
                    // se vende en la misma unidad que el producto. La usa el
                    // bulto cerrado, que se vende por unidad dentro de un
                    // producto que se guarda en gramos.
                    AppSubtitle('UNIDAD DE ESTA VARIANTE'),
                    const SizedBox(height: 4),
                    Text(
                      'Si la dejás vacía, la variante se vende en la misma unidad que el producto.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
                      builder: (context, state) {
                        if (state is! EmpresaContextLoaded) {
                          return const SizedBox.shrink();
                        }
                        return UnidadMedidaDropdown(
                          empresaId: state.context.empresa.id,
                          selectedUnidadId: _unidadMedidaId,
                          onChanged: (v) => setState(() => _unidadMedidaId = v),
                          labelText: 'Unidad de venta (opcional)',
                          hintText: 'Hereda la del producto',
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Presentación PROPIA de la variante. Se reusa la misma
                    // sección del formulario de producto: la regla es idéntica
                    // (factor > 1, unidad distinta a la de venta) y así lo que
                    // se ve acá coincide con lo que ya conoce el usuario.
                    ProductoUnidadPresentacionSection(
                      selectedUnidadMedidaId: _unidadMedidaId,
                      selectedUnidadPresentacionId: _unidadPresentacionId,
                      factorPresentacionController:
                          _factorPresentacionController,
                      onUnidadPresentacionChanged: (v) =>
                          setState(() => _unidadPresentacionId = v),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Vínculo de apertura (saco cerrado → granel).
                    VarianteAperturaSection(
                      variantesHermanas: widget.variantesHermanas,
                      selectedVarianteAperturaId: _varianteAperturaId,
                      rendimientoController: _rendimientoAperturaController,
                      onVarianteAperturaChanged: (v) =>
                          setState(() => _varianteAperturaId = v),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Niveles de precio (solo en modo edición)
                    if (widget.variante != null) ...[
                      _buildPrecioNivelesSection(),
                      const SizedBox(height: 24),
                    ],

                    // Peso
                    CustomText(
                      controller: _pesoController,
                      borderColor: AppColors.blue1,
                      label: 'Peso (kg)',
                      hintText: 'Ej: 0.50',
                      prefixIcon: const Icon(Icons.scale),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Estado
                    CustomSwitchTile(
                      value: _isActive,
                      activeColor: AppColors.blue1,
                      title: 'Variante activa',
                      subtitle: widget.productoIsActive
                          ? 'Las variantes inactivas no se muestran a los clientes'
                          : 'El producto padre está inactivo. Actívalo primero para poder activar variantes.',
                      subtitleStyle: TextStyle(
                        color: widget.productoIsActive
                            ? Colors.grey[600]
                            : Colors.red[600],
                            fontSize: 10,
                      ),
                      // Deshabilitado si el padre está inactivo.
                      onChanged: widget.productoIsActive
                          ? (value) {
                              if (value && !widget.productoIsActive) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No se puede activar una variante cuando el producto padre está inactivo'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setState(() => _isActive = value);
                            }
                          : null,
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
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      backgroundColor: AppColors.white,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Guardar',
                      backgroundColor: AppColors.blue1,
                      iconColor: AppColors.white,
                      icon: const Icon(Icons.save, size: 16, color: Colors.white),
                      onPressed: _save,
                    ),
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
      // ⚠️ Estos cinco van SIEMPRE, incluso en null. Si se omitieran cuando
      // están vacíos, el backend lo leería como "no tocar" y la configuración
      // no se podría APAGAR nunca — es el bug que tiene hoy la unidad de
      // compra del producto.
      'unidadMedidaId': _unidadMedidaId,
      'unidadPresentacionId': _unidadPresentacionId,
      'factorPresentacion': _parseNum(_factorPresentacionController.text),
      'varianteAperturaId': _varianteAperturaId,
      'rendimientoApertura': _parseNum(_rendimientoAperturaController.text),
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
  }
}

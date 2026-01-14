import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/services/storage_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/usecases/crear_producto_usecase.dart';
import '../../domain/usecases/actualizar_producto_usecase.dart';
import '../../domain/entities/producto.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../bloc/producto_detail/producto_detail_cubit.dart';
import '../bloc/producto_detail/producto_detail_state.dart';
import '../bloc/producto_images/producto_images_cubit.dart';
import '../bloc/producto_images/producto_images_state.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_state.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/precio_nivel/precio_nivel_state.dart';
import '../bloc/configuracion_precio/configuracion_precio_cubit.dart';
import '../bloc/configuracion_precio/configuracion_precio_state.dart';
import '../widgets/producto_images_manager.dart';
import '../widgets/producto_video_manager.dart';
import '../widgets/atributo_input_widget.dart';
import '../widgets/precio_niveles_section.dart';
import '../widgets/configuracion_precio_selector.dart';
import '../../data/datasources/producto_remote_datasource.dart';
import '../../data/models/producto_atributo_valor_dto.dart';
import '../../data/models/precio_nivel_model.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_state.dart';
import '../../../empresa/presentation/widgets/unidad_medida_dropdown.dart';

class ProductoFormPage extends StatelessWidget {
  final String? productoId;

  const ProductoFormPage({
    super.key,
    this.productoId,
  });

  bool get isEditing => productoId != null;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => locator<ProductoDetailCubit>()),
          BlocProvider(create: (_) => locator<ProductoImagesCubit>()),
          BlocProvider(create: (_) => locator<AtributoPlantillaCubit>()),
          BlocProvider(create: (_) => locator<PrecioNivelCubit>()),
        ],
        child: _ProductoFormView(
          productoId: productoId,
          isEditing: isEditing,
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<ProductoImagesCubit>()),
        BlocProvider(create: (_) => locator<AtributoPlantillaCubit>()),
        BlocProvider(create: (_) => locator<PrecioNivelCubit>()),
      ],
      child: _ProductoFormView(
        productoId: productoId,
        isEditing: isEditing,
      ),
    );
  }
}

class _ProductoFormView extends StatefulWidget {
  final String? productoId;
  final bool isEditing;

  const _ProductoFormView({
    this.productoId,
    required this.isEditing,
  });

  @override
  State<_ProductoFormView> createState() => _ProductoFormViewState();
}

class _ProductoFormViewState extends State<_ProductoFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _skuController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _precioController = TextEditingController();
  final _precioCostoController = TextEditingController();
  final _stockController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _precioOfertaController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _impuestoPorcentajeController = TextEditingController();
  final _descuentoMaximoController = TextEditingController();
  final _dimensionLargoController = TextEditingController();
  final _dimensionAnchoController = TextEditingController();
  final _dimensionAltoController = TextEditingController();

  String? _selectedCategoriaId;
  String? _selectedMarcaId;
  String? _selectedSedeId;  // Sede donde se encuentra el producto
  String? _selectedUnidadMedidaId;  // Unidad de medida del producto
  bool _visibleMarketplace = true;
  bool _destacado = false;
  bool _enOferta = false;
  bool _tieneVariantes = false;
  bool _esCombo = false; // Agregado para validación XOR
  String? _tipoPrecioCombo; // FIJO, CALCULADO, CALCULADO_CON_DESCUENTO
  bool _productoIsActive = true; // Estado del producto para validación de variantes
  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;
  bool _isLoading = false;

  // Control de cambios sin guardar
  bool _hasUnsavedChanges = false;
  bool _formSubmittedSuccessfully = false;

  // Plantilla de atributos
  String? _selectedPlantillaId;
  AtributoPlantilla? _selectedPlantilla;
  final Map<String, String> _plantillaAtributosValues = {};

  // Configuración de precios
  String? _selectedConfiguracionPrecioId;


  @override
  void initState() {
    super.initState();
    _loadCatalogos();
    _setupChangeListeners();

    // Inicializar cubit de imágenes y precio niveles con estado vacío
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isEditing) {
        context.read<ProductoImagesCubit>().clear();
        context.read<PrecioNivelCubit>().initialize();

        // Inicializar sede principal por defecto
        final empresaState = context.read<EmpresaContextCubit>().state;
        if (empresaState is EmpresaContextLoaded) {
          // Buscar la sede principal
          final sedesActivas = empresaState.context.sedes.where((s) => s.isActive).toList();

          if (sedesActivas.isNotEmpty) {
            // Buscar sede principal, si no existe tomar la primera activa
            String? sedeIdInicial;

            // Buscar sede principal
            try {
              final sedePrincipal = sedesActivas.firstWhere((sede) => sede.esPrincipal);
              sedeIdInicial = sedePrincipal.id;
            } catch (e) {
              // Si no hay sede principal, tomar la primera
              sedeIdInicial = sedesActivas.first.id;
            }

            setState(() {
              _selectedSedeId = sedeIdInicial;
            });
          }
        }
      }
    });

    if (widget.isEditing) {
      _loadProducto();
    }
  }

  /// Configurar listeners para detectar cambios en el formulario
  void _setupChangeListeners() {
    final controllers = [
      _nombreController,
      _descripcionController,
      _skuController,
      _codigoBarrasController,
      _precioController,
      _precioCostoController,
      _stockController,
      _stockMinimoController,
      _pesoController,
      _precioOfertaController,
      _videoUrlController,
      _impuestoPorcentajeController,
      _descuentoMaximoController,
      _dimensionLargoController,
      _dimensionAnchoController,
      _dimensionAltoController,
    ];

    for (var controller in controllers) {
      controller.addListener(_markAsChanged);
    }
  }

  /// Marcar que hay cambios sin guardar
  void _markAsChanged() {
    if (!_hasUnsavedChanges && !_formSubmittedSuccessfully) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  /// Verificar si hay cambios sin guardar (incluyendo imágenes)
  bool _hasChanges() {
    if (_formSubmittedSuccessfully) return false;

    // Verificar cambios en el formulario
    if (_hasUnsavedChanges) return true;

    // Verificar si hay imágenes agregadas
    final imageState = context.read<ProductoImagesCubit>().state;
    if (imageState is ProductoImagesLoaded && imageState.images.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Mostrar diálogo de confirmación antes de salir
  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true; // Permitir salir sin confirmación
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que deseas salir sin guardar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _loadProducto() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded && widget.productoId != null) {
      context.read<ProductoDetailCubit>().loadProducto(
            productoId: widget.productoId!,
            empresaId: empresaState.context.empresa.id,
          );
      // Cargar niveles de precio del producto
      context.read<PrecioNivelCubit>().loadNivelesProducto(widget.productoId!);
    }
  }

  void _fillFormWithProducto(dynamic producto) {
    _nombreController.text = producto.nombre;
    _descripcionController.text = producto.descripcion ?? '';
    _skuController.text = producto.sku ?? '';
    _codigoBarrasController.text = producto.codigoBarras ?? '';
    _precioController.currencyValue = producto.precio;
    _precioCostoController.currencyValue = producto.precioCosto ?? 0.0;
    _stockController.text = producto.stock.toString();
    _stockMinimoController.text = producto.stockMinimo?.toString() ?? '';
    _pesoController.text = producto.peso?.toString() ?? '';
    _videoUrlController.text = producto.videoUrl ?? '';
    _impuestoPorcentajeController.text = producto.impuestoPorcentaje?.toString() ?? '';
    _descuentoMaximoController.text = producto.descuentoMaximo?.toString() ?? '';

    // Cargar estado de esCombo para validación XOR
    _esCombo = producto.esCombo ?? false;
    // Cargar tipo de precio combo si existe
    _tipoPrecioCombo = producto.tipoPrecioCombo;

    // Cargar estado isActive para validación de variantes
    _productoIsActive = producto.isActive ?? true;

    // Cargar dimensiones si existen
    if (producto.dimensiones != null && producto.dimensiones is Map) {
      _dimensionLargoController.text = producto.dimensiones['largo']?.toString() ?? '';
      _dimensionAnchoController.text = producto.dimensiones['ancho']?.toString() ?? '';
      _dimensionAltoController.text = producto.dimensiones['alto']?.toString() ?? '';
    }

    // Cargar imágenes existentes
    if (producto.archivos != null && producto.archivos is List) {
      final existingImages = (producto.archivos as List).map((archivo) {
        return ProductoImage(
          id: archivo.id,
          url: archivo.url,
          urlThumbnail: archivo.urlThumbnail,
          isUploading: false,
          uploadProgress: 1.0,
          hasError: false,
          order: archivo.orden ?? 0,
        );
      }).toList();

      // Ordenar por orden
      existingImages.sort((a, b) => a.order.compareTo(b.order));

      // Cargar en el cubit
      context.read<ProductoImagesCubit>().loadExistingImages(existingImages);
    }

    setState(() {
      _selectedCategoriaId = producto.empresaCategoriaId;
      _selectedMarcaId = producto.empresaMarcaId;
      _selectedSedeId = producto.sedeId;  // Cargar sede del producto
      _selectedUnidadMedidaId = producto.unidadMedidaId;  // Cargar unidad de medida del producto
      _selectedConfiguracionPrecioId = producto.configuracionPrecioId;
      _visibleMarketplace = producto.visibleMarketplace;
      _destacado = producto.destacado;
      _enOferta = producto.enOferta;
      _tieneVariantes = producto.tieneVariantes;

      if (producto.enOferta) {
        _precioOfertaController.currencyValue = producto.precioOferta ?? 0.0;
        _fechaInicioOferta = producto.fechaInicioOferta;
        _fechaFinOferta = producto.fechaFinOferta;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _skuController.dispose();
    _codigoBarrasController.dispose();
    _precioController.dispose();
    _precioCostoController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    _pesoController.dispose();
    _precioOfertaController.dispose();
    _videoUrlController.dispose();
    _impuestoPorcentajeController.dispose();
    _descuentoMaximoController.dispose();
    _dimensionLargoController.dispose();
    _dimensionAnchoController.dispose();
    _dimensionAltoController.dispose();
    super.dispose();
  }

  void _loadCatalogos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final empresaId = empresaState.context.empresa.id;
      context.read<CategoriasEmpresaCubit>().loadCategorias(empresaId);
      context.read<MarcasEmpresaCubit>().loadMarcas(empresaId);
      context.read<ConfiguracionPrecioCubit>().loadConfiguraciones();
      context.read<UnidadMedidaCubit>().getUnidadesEmpresa(empresaId);
      _loadPlantillas(empresaId);
    }
  }

  void _loadPlantillas(String empresaId) {
    // Cargar todas las plantillas de la empresa (sin filtrar por categoría)
    context.read<AtributoPlantillaCubit>().loadPlantillas(categoriaId: null);
  }

  void _onPlantillaSelected(String? plantillaId) {
    if (plantillaId == null) {
      setState(() {
        _selectedPlantillaId = null;
        _selectedPlantilla = null;
        _plantillaAtributosValues.clear();
      });
      return;
    }

    // Buscar la plantilla en la lista cargada
    final state = context.read<AtributoPlantillaCubit>().state;
    if (state is AtributoPlantillaLoaded) {
      AtributoPlantilla? foundPlantilla;
      for (final p in state.plantillas) {
        if (p.id == plantillaId) {
          foundPlantilla = p;
          break;
        }
      }
      if (foundPlantilla != null) {
        setState(() {
          _selectedPlantillaId = plantillaId;
          _selectedPlantilla = foundPlantilla;
          _plantillaAtributosValues.clear();
          // Inicializar valores vacíos para cada atributo
          for (final atributo in foundPlantilla!.atributos) {
            _plantillaAtributosValues[atributo.atributo.id] = '';
          }
        });
      }
    }
  }

  void _onPlantillaAtributoChanged(String atributoId, String value) {
    setState(() {
      _plantillaAtributosValues[atributoId] = value;
      _markAsChanged();
    });
  }

  /// Valida que todos los atributos requeridos tengan valor
  bool _validarAtributosRequeridos() {
    // Validar atributos de plantilla
    if (_selectedPlantilla != null) {
      for (final plantillaAtributo in _selectedPlantilla!.atributos) {
        if (plantillaAtributo.esRequerido) {
          final valor = _plantillaAtributosValues[plantillaAtributo.atributo.id];
          if (valor == null || valor.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El atributo "${plantillaAtributo.atributo.nombre}" es requerido'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Guarda los atributos de un producto (ya sea de categoría o de plantilla)
  Future<void> _guardarAtributos({
    required String productoId,
    required String empresaId,
    required Map<String, String> valores,
    String tipoFuente = '',
  }) async {
    if (valores.isEmpty) return;

    try {
      final atributos = valores.entries
          .map((e) => VarianteAtributoDto(
                atributoId: e.key,
                valor: e.value,
              ))
          .toList();

      await locator<ProductoRemoteDataSource>().setProductoAtributos(
        productoId: productoId,
        empresaId: empresaId,
        data: {'atributos': atributos.map((a) => a.toJson()).toList()},
      );
    } catch (e) {
      // Si falla guardando atributos, mostrar advertencia pero no bloquear
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Producto guardado, pero hubo un error al guardar atributos${tipoFuente.isNotEmpty ? " de $tipoFuente" : ""}: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar atributos requeridos antes de continuar
    if (!_tieneVariantes && !_esCombo) {
      if (!_validarAtributosRequeridos()) {
        return;
      }
    }

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final empresaId = empresaState.context.empresa.id;
      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();

      // Si es combo con precio calculado, enviar 0 o null
      final double precio;
      if (_esCombo && (_tipoPrecioCombo == 'CALCULADO' || _tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO')) {
        precio = 0.0; // El precio se calculará en el backend cuando se agreguen los componentes
      } else {
        precio = _precioController.currencyValue;
      }

      // Preparar dimensiones si hay valores
      Map<String, dynamic>? dimensiones;
      if (_dimensionLargoController.text.isNotEmpty ||
          _dimensionAnchoController.text.isNotEmpty ||
          _dimensionAltoController.text.isNotEmpty) {
        dimensiones = {
          if (_dimensionLargoController.text.isNotEmpty)
            'largo': double.tryParse(_dimensionLargoController.text) ?? 0.0,
          if (_dimensionAnchoController.text.isNotEmpty)
            'ancho': double.tryParse(_dimensionAnchoController.text) ?? 0.0,
          if (_dimensionAltoController.text.isNotEmpty)
            'alto': double.tryParse(_dimensionAltoController.text) ?? 0.0,
        };
      }

      // Subir todas las imágenes locales pendientes antes de guardar el producto
      final imagesCubit = context.read<ProductoImagesCubit>();
      final imagesState = imagesCubit.state;

      List<String> uploadedIds = [];

      if (imagesState is ProductoImagesLoaded) {
        // Si hay imágenes locales o con error, intentar subirlas
        if (imagesState.hasPendingImages || imagesState.hasErrors) {
          try {
            // Subir imágenes locales pendientes
            final newIds = await imagesCubit.uploadAllPendingImages(empresaId);
            uploadedIds.addAll(newIds);

            // Reintentar imágenes con error
            if (imagesState.hasErrors) {
              final retriedIds = await imagesCubit.retryFailedUploads(empresaId);
              uploadedIds.addAll(retriedIds);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al subir imágenes: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return; // No continuar si falla la subida de imágenes
          }
        }
      }

      // Obtener todos los IDs de imágenes subidas (las que ya estaban + las nuevas)
      final imagenesIds = imagesCubit.getUploadedImageIds();

      final result = widget.isEditing
          ? await locator<ActualizarProductoUseCase>()(
              productoId: widget.productoId!,
              empresaId: empresaId,
              sedeId: _selectedSedeId,  // Incluir sede seleccionada
              unidadMedidaId: _selectedUnidadMedidaId,  // Incluir unidad de medida
              nombre: nombre,
              descripcion: descripcion.isEmpty ? null : descripcion,
              precio: precio,
              empresaCategoriaId: _selectedCategoriaId,
              empresaMarcaId: _selectedMarcaId,
              sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
              codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
              precioCosto: _precioCostoController.currencyValue > 0 ? _precioCostoController.currencyValue : null,
              stock: _stockController.text.isEmpty ? null : int.tryParse(_stockController.text),
              stockMinimo: _stockMinimoController.text.isEmpty ? null : int.tryParse(_stockMinimoController.text),
              peso: _pesoController.text.isEmpty ? null : double.tryParse(_pesoController.text),
              dimensiones: dimensiones,
              videoUrl: _videoUrlController.text.trim(), // Enviar cadena vacía si está vacío, el backend lo convierte a null
              impuestoPorcentaje: _impuestoPorcentajeController.text.isEmpty
                  ? null
                  : double.tryParse(_impuestoPorcentajeController.text),
              descuentoMaximo: _descuentoMaximoController.text.isEmpty
                  ? null
                  : double.tryParse(_descuentoMaximoController.text),
              visibleMarketplace: _visibleMarketplace,
              destacado: _destacado,
              enOferta: _enOferta,
              tieneVariantes: _tieneVariantes,
              esCombo: _esCombo,
              tipoPrecioCombo: _esCombo ? _tipoPrecioCombo : null,
              precioOferta: _enOferta ? _precioOfertaController.currencyValue : null,
              fechaInicioOferta: _enOferta ? _fechaInicioOferta : null,
              fechaFinOferta: _enOferta ? _fechaFinOferta : null,
              imagenesIds: imagenesIds.isNotEmpty ? imagenesIds : null,
              configuracionPrecioId: _selectedConfiguracionPrecioId,
            )
          : await locator<CrearProductoUseCase>()(
              empresaId: empresaId,
              sedeId: _selectedSedeId,  // Incluir sede seleccionada
              unidadMedidaId: _selectedUnidadMedidaId,  // Incluir unidad de medida
              nombre: nombre,
              descripcion: descripcion.isEmpty ? null : descripcion,
              precio: precio,
              empresaCategoriaId: _selectedCategoriaId,
              empresaMarcaId: _selectedMarcaId,
              sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
              codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
              precioCosto: _precioCostoController.currencyValue > 0 ? _precioCostoController.currencyValue : null,
              stock: _stockController.text.isEmpty ? 0 : int.tryParse(_stockController.text) ?? 0,
              stockMinimo: _stockMinimoController.text.isEmpty ? null : int.tryParse(_stockMinimoController.text),
              peso: _pesoController.text.isEmpty ? null : double.tryParse(_pesoController.text),
              dimensiones: dimensiones,
              videoUrl: _videoUrlController.text.trim(), // Enviar cadena vacía si está vacío, el backend lo convierte a null
              impuestoPorcentaje: _impuestoPorcentajeController.text.isEmpty
                  ? null
                  : double.tryParse(_impuestoPorcentajeController.text),
              descuentoMaximo: _descuentoMaximoController.text.isEmpty
                  ? null
                  : double.tryParse(_descuentoMaximoController.text),
              visibleMarketplace: _visibleMarketplace,
              destacado: _destacado,
              enOferta: _enOferta,
              tieneVariantes: _tieneVariantes,
              esCombo: _esCombo,
              tipoPrecioCombo: _esCombo ? _tipoPrecioCombo : null,
              precioOferta: _enOferta ? _precioOfertaController.currencyValue : null,
              fechaInicioOferta: _enOferta ? _fechaInicioOferta : null,
              fechaFinOferta: _enOferta ? _fechaFinOferta : null,
              imagenesIds: imagenesIds.isNotEmpty ? imagenesIds : null,
              configuracionPrecioId: _selectedConfiguracionPrecioId,
            );


      if (mounted) {
        if (result is Success<Producto>) {
          final producto = (result).data;

          // Guardar atributos de plantilla si hay (solo para productos simples)
          if (!_tieneVariantes && !_esCombo && _selectedPlantillaId != null) {
            await _guardarAtributos(
              productoId: producto.id,
              empresaId: empresaId,
              valores: _plantillaAtributosValues,
              tipoFuente: 'plantilla',
            );
          }

          // Verificar nuevamente mounted después de la operación asíncrona
          if (!mounted) return;

          // Marcar como guardado exitosamente para no mostrar confirmación al salir
          setState(() {
            _formSubmittedSuccessfully = true;
          });

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditing ? 'Producto actualizado' : 'Producto creado'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar de regreso ANTES de recargar datos
          // Esto evita el error "Cannot emit new states after calling close"
          context.pop();

          // NOTA: No recargar niveles aquí porque el BLoC ya fue disposed tras el pop
          // Los niveles se recargarán automáticamente en la página anterior si es necesario
        } else if (result is Error) {
          final error = result as Error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      backgroundColor: Colors.transparent,// Hacer el scaffold transparente
      extendBodyBehindAppBar: true,// Extender el body detrás del AppBar
      appBar: SmartAppBar(
        title: widget.isEditing ? 'Editar Producto' : 'Nuevo Producto',
      ),
      body: GradientBackground(
        style: GradientStyle.professional, // Estilo directo sin variable
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Quitar el foco de cualquier campo al tocar fuera
              FocusScope.of(context).unfocus();
            },
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildTieneVariantesSection(),
                const SizedBox(height: 24),
                _buildCategoriaSection(),
                const SizedBox(height: 24),
                // Plantilla de atributos (solo para productos simples)
                if (!_tieneVariantes && !_esCombo) ...[
                  _buildPlantillasSection(),
                  const SizedBox(height: 24),
                ],
                if (!_tieneVariantes && !_esCombo) ...[
                  _buildPricingSection(),
                  const SizedBox(height: 24),
                  // Selector de configuración de precios
                  _buildConfiguracionPrecioSelector(),
                  const SizedBox(height: 24),
                  // Sección de precios por volumen (solo en modo edición)
                  if (widget.isEditing) ...[
                    _buildPrecioNivelesSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildOfertaSection(),
                  const SizedBox(height: 24),
                  _buildInventorySection(),
                  const SizedBox(height: 24),
                ] else if (_tieneVariantes) ...[
                  _buildVariantesInfoBanner(),
                  const SizedBox(height: 24),
                ] else if (_esCombo) ...[
                  _buildComboInfoBanner(),
                  const SizedBox(height: 24),
                ],
                _buildImagesSection(),
                const SizedBox(height: 24),
                _buildDimensionesSection(),
                const SizedBox(height: 24),
                _buildImpuestosDescuentosSection(),
                const SizedBox(height: 24),
                _buildMultimediaSection(),
                const SizedBox(height: 24),
                _buildOptionsSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ),
    );

    // Envolver con PopScope para interceptar el botón de retroceso
    content = PopScope(
      canPop: !_hasChanges(),
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: content,
    );

    if (widget.isEditing) {
      return BlocListener<ProductoDetailCubit, ProductoDetailState>(
        listener: (context, state) {
          if (state is ProductoDetailLoaded) {
            _fillFormWithProducto(state.producto);
          }
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildBasicInfoSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('INFORMACION BÁSICA'),
            const SizedBox(height: 16),
            CustomText(
              controller: _nombreController,
              borderColor: AppColors.blue1,
              label: 'Nombre del Producto *',
              hintText: 'Ej: Laptop HP Pavilion',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _descripcionController,
              borderColor: AppColors.blue1,
              label: 'Descripción',
              hintText: 'Descripción del producto',
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _skuController,
                    prefixIcon: Icon(Icons.numbers, size: 16,),
                    borderColor: AppColors.blue1,
                    label: 'SKU',
                    hintText: 'Código SKU',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomText(
                    controller: _codigoBarrasController,
                    prefixIcon: Icon(Icons.qr_code_scanner_outlined, size: 16,),
                    borderColor: AppColors.blue1,
                    label: 'Código de Barras',
                    hintText: 'EAN/UPC',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      
    );
  }

  Widget _buildTieneVariantesSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: _tieneVariantes ? Colors.purple : (_esCombo ? Colors.blue : AppColors.blueborder),
      gradient: _tieneVariantes
        ? LinearGradient(colors: [Colors.purple.shade50, Colors.purple.shade50])
        : (_esCombo
          ? LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade50])
          : AppGradients.fondo),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: _tieneVariantes ? Colors.purple : (_esCombo ? Colors.blue : AppColors.blueGrey),
                  size: 20,
                ),
                const SizedBox(width: 8),
                AppSubtitle('TIPO DE PRODUCTO')
              ],
            ),
            const SizedBox(height: 8),
            // Switch para Producto Combo
            CustomSwitchTile(
              activeColor: AppColors.green,
              activeTrackColor: AppColors.blue,
              trackOutlineColor: AppColors.blueGrey,
              title: 'Producto Combo',
              trackOutlineWidth: 1,
              subtitle: _esCombo
                  ? 'Este producto es un combo de otros productos'
                  : 'Producto simple o con variantes',
              value: _esCombo,
              onChanged: _tieneVariantes ? null : (value) {
                // Validación XOR: No permitir combo si tiene variantes
                if (value && _tieneVariantes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se puede activar combo en un producto con variantes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() {
                  _esCombo = value;
                  _markAsChanged();
                  // Si se desactiva combo, limpiar tipoPrecioCombo
                  if (!value) {
                    _tipoPrecioCombo = null;
                  }
                });
              },
            ),
            // Switch para Producto con Variantes (existente)
            CustomSwitchTile(
              activeColor: AppColors.green,
              activeTrackColor: AppColors.blue,
              trackOutlineColor: AppColors.blueGrey,
              title: 'Producto con Variantes',
              trackOutlineWidth: 1,
              subtitle: _esCombo
                  ? 'No se puede activar variantes en un producto combo'
                  : (_tieneVariantes
                      ? 'El producto tiene variantes (capacidad, color, etc.)'
                      : 'Producto simple sin variantes'),
              value: _tieneVariantes,
              onChanged: _esCombo ? null : (value) async {
                // Validación XOR: No permitir variantes si es combo
                if (value && _esCombo) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se puede activar variantes en un producto que es combo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Si está editando y va a activar variantes, mostrar confirmación
                if (widget.isEditing && value && !_tieneVariantes) {
                  final confirmar = await _mostrarDialogoConversionVariantes();
                  if (confirmar != true) return;
                }

                setState(() {
                  _tieneVariantes = value;
                  _markAsChanged();

                  // Si activa variantes, limpiar campos que no se usarán
                  if (value) {
                    _precioController.text = '0';
                    _stockController.text = '0';
                    _skuController.clear();
                    _enOferta = false;
                    _precioOfertaController.clear();
                  }
                });
              },
            ),
            // Selector de Tipo de Precio Combo (solo si es combo)
            if (_esCombo) ...[
              const SizedBox(height: 16),
              CustomDropdown<String>(
                label: 'Tipo de Precio del Combo',
                hintText: 'Selecciona cómo se calculará el precio',
                borderColor: AppColors.blue1,
                value: _tipoPrecioCombo,
                items: const [
                  DropdownItem(
                    value: 'FIJO',
                    label: 'Precio Fijo',
                  ),
                  DropdownItem(
                    value: 'CALCULADO',
                    label: 'Calculado (suma de productos)',
                  ),
                  DropdownItem(
                    value: 'CALCULADO_CON_DESCUENTO',
                    label: 'Calculado con Descuento',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoPrecioCombo = value;
                    _markAsChanged();
                  });
                },
                validator: (value) {
                  if (_esCombo && (value == null || value.isEmpty)) {
                    return 'Selecciona un tipo de precio para el combo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSubtitle(
                        'Un producto combo no puede tener variantes. Los combos se gestionan en la sección de "Combos" después de crear el producto.',
                        fontSize: 10,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_tieneVariantes && !widget.isEditing) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSubtitle(
                        'Después de crear el producto, podrás agregar las variantes (colores, tallas, etc.) con sus precios y stock individuales.',
                        fontSize: 10,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      
    );
  }

  Future<bool?> _mostrarDialogoConversionVariantes() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(child: Text('Convertir a Variantes')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Al activar variantes en este producto:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDialogoItem(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              text: 'Se creará automáticamente una variante "Original" con el precio y stock actuales',
            ),
            const SizedBox(height: 8),
            _buildDialogoItem(
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              text: 'Podrás agregar más variantes (colores, tallas, etc.)',
            ),
            const SizedBox(height: 8),
            _buildDialogoItem(
              icon: Icons.info_outline,
              color: Colors.orange,
              text: 'El precio y stock del producto base se ignorarán',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Precio actual: \$${_precioController.text}\nStock actual: ${_stockController.text}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Convertir a Variantes'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogoItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantesInfoBanner() {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.amber,
      gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.amber.shade50]),
      padding: const EdgeInsets.all(16),
      child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto con Variantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isEditing
                            ? 'Los precios y stock se gestionan en cada variante individual.'
                            : 'Una vez creado el producto, podrás agregar variantes con sus precios y stock individuales.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final nombre = _nombreController.text.isNotEmpty
                        ? _nombreController.text
                        : 'Producto';
                    final categoriaIdParam = _selectedCategoriaId != null ? '&categoriaId=${Uri.encodeComponent(_selectedCategoriaId!)}' : '';
                    context.push(
                      '/empresa/productos/${widget.productoId}/variantes?nombre=${Uri.encodeComponent(nombre)}&isActive=$_productoIsActive$categoriaIdParam',
                    );
                  },
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Gestionar Variantes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      
    );
  }

  Widget _buildComboInfoBanner() {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.blue,
      gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade50]),
      padding: const EdgeInsets.all(16),
      child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto Combo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isEditing
                            ? 'El precio y stock se calculan automáticamente según los productos componentes del combo.'
                            : 'Una vez creado el combo, podrás agregar los productos que lo componen. El precio y stock se calcularán automáticamente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tipo de precio: ${_tipoPrecioCombo ?? "No definido"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tipoPrecioCombo == 'FIJO'
                        ? '• El precio es fijo y definido manualmente'
                        : _tipoPrecioCombo == 'CALCULADO'
                            ? '• El precio es la suma de todos los productos componentes'
                            : _tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO'
                                ? '• El precio es la suma de componentes con descuento aplicado'
                                : '• Selecciona un tipo de precio arriba',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• El stock disponible depende del stock de cada componente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navegar a página de gestión de componentes del combo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de gestión de combos próximamente'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.category, size: 20),
                  label: const Text('Gestionar Componentes del Combo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      
    );
  }

  Widget _buildCategoriaSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Categorización',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            AppSubtitle('CATEGORIZACIÓN'),
            const SizedBox(height: 12),
            BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
              builder: (context, state) {
                if (state is CategoriasEmpresaLoaded) {
                  return CustomDropdown<String>(
                    label: 'Categoría',
                    hintText: 'Selecciona una categoría',
                    borderColor: AppColors.blue1,
                    value: _selectedCategoriaId,
                    prefixIcon: const Icon(Icons.category_outlined, size: 16, color: AppColors.blue1,),
                    items: state.categorias.map((cat) {
                      return DropdownItem(
                        value: cat.id,
                        label: cat.nombreDisplay,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoriaId = value;
                      });
                    },
                  );
                }
                return const SizedBox(
                  height: 35,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
              builder: (context, state) {
                if (state is MarcasEmpresaLoaded) {
                  return CustomDropdown<String>(
                    label: 'Marca',
                    hintText: 'Selecciona una marca',
                    borderColor: AppColors.blue1,
                    value: _selectedMarcaId,
                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.blue1,),
                    items: state.marcas.map((marca) {
                      return DropdownItem(
                        value: marca.id,
                        label: marca.nombreDisplay,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMarcaId = value;
                      });
                    },
                  );
                }
                return const SizedBox(
                  height: 35,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Dropdown de Sedes
            BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
              builder: (context, state) {
                if (state is EmpresaContextLoaded) {
                  final sedesActivas = state.context.sedes
                      .where((sede) => sede.isActive)
                      .toList();

                  return CustomDropdown<String>(
                    label: 'Sede *',
                    hintText: 'Selecciona la sede donde se encuentra el producto',
                    borderColor: AppColors.blue1,
                    value: _selectedSedeId,
                    prefixIcon: const Icon(Icons.business, size: 16, color: AppColors.blue1,),
                    items: sedesActivas.map((sede) {
                      return DropdownItem(
                        value: sede.id,
                        label: sede.nombre + (sede.esPrincipal ? ' (Principal)' : ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSedeId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debe seleccionar una sede';
                      }
                      return null;
                    },
                  );
                }
                return const SizedBox(
                  height: 35,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Dropdown de Unidades de Medida con listener para seleccionar "Unidad" por defecto
            BlocConsumer<UnidadMedidaCubit, UnidadMedidaState>(
              listener: (context, state) {
                // Cuando se carguen las unidades y no haya una seleccionada, seleccionar "Unidad" (NIU)
                if (state is UnidadesEmpresaLoaded &&
                    _selectedUnidadMedidaId == null &&
                    !widget.isEditing &&
                    state.unidadesEmpresa.isNotEmpty) {
                  // Buscar la unidad "Unidad" (NIU)
                  try {
                    final unidadPorDefecto = state.unidadesEmpresa.firstWhere(
                      (u) => u.unidadMaestra?.codigo == 'NIU',
                      orElse: () => state.unidadesEmpresa.first,
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedUnidadMedidaId = unidadPorDefecto.id;
                        });
                      }
                    });
                  } catch (e) {
                    // Si hay error buscando la unidad, no hacer nada
                  }
                }
              },
              builder: (context, state) {
                final empresaState = context.read<EmpresaContextCubit>().state;
                if (empresaState is EmpresaContextLoaded) {
                  return UnidadMedidaDropdown(
                    empresaId: empresaState.context.empresa.id,
                    selectedUnidadId: _selectedUnidadMedidaId,
                    onChanged: (value) {
                      setState(() {
                        _selectedUnidadMedidaId = value;
                        _markAsChanged();
                      });
                    },
                    labelText: 'Unidad de medida',
                    hintText: 'Selecciona la unidad',
                    required: false,
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            

          ],
        ),

    );
  }

  Widget _buildPricingSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blue1,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Precios',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            AppSubtitle('PRECIOS'),
            const SizedBox(height: 12),
            // Mensaje informativo para combos con precio calculado
            if (_esCombo && (_tipoPrecioCombo == 'CALCULADO' || _tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO')) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El precio de este combo se calculará automáticamente cuando agregues los productos componentes.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: CurrencyTextField(
                    controller: _precioController,
                    label: _esCombo && (_tipoPrecioCombo == 'CALCULADO' || _tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO')
                        ? 'Precio de Venta (calculado)'
                        : 'Precio de Venta *',
                    hintText: '0.00',
                    borderColor: AppColors.blue1,
                    enabled: !_esCombo || _tipoPrecioCombo == 'FIJO' || _tipoPrecioCombo == null,
                    enableRealTimeValidation: true,
                    validator: (value) {
                      // Si es combo con precio calculado, el precio NO es requerido
                      if (_esCombo && (_tipoPrecioCombo == 'CALCULADO' || _tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO')) {
                        return null; // Válido sin importar el valor
                      }

                      // Para otros casos, el precio es requerido
                      if (value == null || value.trim().isEmpty) {
                        return 'El precio es requerido';
                      }

                      final precio = CurrencyUtilsImproved.parseToDouble(value);
                      if (precio <= 0) {
                        return 'El precio debe ser mayor a 0';
                      }

                      // Validar precio >= costo
                      final costo = _precioCostoController.currencyValue;
                      if (costo > 0 && precio < costo) {
                        return 'El precio debe ser ≥ al costo';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CurrencyTextField(
                    allowZero: false,
                    requiredField: true,
                    controller: _precioCostoController,
                    label: 'Precio de Costo',
                    hintText: '0.00',
                    borderColor: AppColors.blue1,
                    enableRealTimeValidation: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      
    );
  }

  Widget _buildOfertaSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.orange,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.orange,size: 16,),
                const SizedBox(width: 8),
                AppSubtitle('OFERTAS'),
              ],
            ),
            // const SizedBox(height: 8),
            CustomSwitchTile(
              title: 'Producto en Oferta',
              activeColor: Colors.orange,
              activeTrackColor: Colors.orange.shade200,
              subtitle: 'Activar precio especial para este producto',
              value: _enOferta,
              onChanged: (value) {
                setState(() {
                  _enOferta = value;
                  if (!value) {
                    // Limpiar valores cuando se desactiva
                    _precioOfertaController.clear();
                    _fechaInicioOferta = null;
                    _fechaFinOferta = null;
                  }
                });
              },
            ),
            if (_enOferta) ...[
              const SizedBox(height: 5),
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
                    CurrencyTextField(
                      controller: _precioOfertaController,
                      label: 'Precio de Oferta *',
                      hintText: '0.00',
                      borderColor: Colors.orange,
                      enableRealTimeValidation: true,
                      validator: _enOferta
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El precio de oferta es requerido';
                              }

                              final precioOferta = CurrencyUtilsImproved.parseToDouble(value);
                              if (precioOferta <= 0) {
                                return 'El precio debe ser mayor a 0';
                              }

                              final precioNormal = _precioController.currencyValue;
                              if (precioNormal > 0 && precioOferta >= precioNormal) {
                                return 'Debe ser menor al precio normal';
                              }
                              return null;
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppSubtitle('PERÍODO DE OFERTA (OPCIONAL)', fontSize: 10,),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -4),
                      minVerticalPadding: 0,
                      leading: const Icon(Icons.calendar_today, color: Colors.orange,size: 17,),
                      title: AppSubtitle(
                        _fechaInicioOferta == null
                            ? 'Fecha de Inicio'
                            : 'Desde: ${_fechaInicioOferta!.day}/${_fechaInicioOferta!.month}/${_fechaInicioOferta!.year}',
                        fontSize: 10,
                      ),
                      trailing: _fechaInicioOferta != null
                          ? IconButton(
                              icon: const Icon(Icons.clear,size: 16,),
                              onPressed: () {
                                setState(() {
                                  _fechaInicioOferta = null;
                                });
                              },
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _fechaInicioOferta ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _fechaInicioOferta = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: const VisualDensity(vertical: -4),
                      minVerticalPadding: 0,
                      leading: const Icon(Icons.event, color: Colors.orange,size: 17,),
                      title: AppSubtitle(
                        _fechaFinOferta == null
                            ? 'Fecha de Fin'
                            : 'Hasta: ${_fechaFinOferta!.day}/${_fechaFinOferta!.month}/${_fechaFinOferta!.year}',
                        fontSize: 10,
                      ),
                      trailing: _fechaFinOferta != null
                          ? IconButton(
                              icon: const Icon(Icons.clear,size: 16,),
                              onPressed: () {
                                setState(() {
                                  _fechaFinOferta = null;
                                });
                              },
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _fechaFinOferta ?? _fechaInicioOferta ?? DateTime.now(),
                          firstDate: _fechaInicioOferta ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _fechaFinOferta = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      
    );
  }

  Widget _buildInventorySection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('INVENTARIO'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _stockController,
                    borderColor: AppColors.blue1,
                    label: 'Stock Inicial',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    controller: _stockMinimoController,
                    borderColor: AppColors.blue1,
                    label: 'Stock Mínimo',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _pesoController,
              borderColor: AppColors.blue1,
              label: 'Peso (kg)',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      
    );
  }

  Widget _buildImagesSection() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      return const SizedBox.shrink();
    }

    return ProductoImagesManager(
      empresaId: empresaState.context.empresa.id,
      maxImages: 10,
    );
  }

  Widget _buildDimensionesSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 
            AppSubtitle('DIMENSIONES (cm)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _dimensionLargoController,
                    borderColor: AppColors.blue1,
                    label: 'Largo',
                    hintText: '0.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    controller: _dimensionAnchoController,
                    borderColor: AppColors.blue1,
                    label: 'Ancho',
                    hintText: '0.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    controller: _dimensionAltoController,
                    borderColor: AppColors.blue1,
                    label: 'Alto',
                    hintText: '0.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      
    );
  }

  Widget _buildImpuestosDescuentosSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            AppSubtitle('IMPUESTOS Y DESCUENTOS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _impuestoPorcentajeController,
                    borderColor: AppColors.blue1,
                    label: 'Impuesto (%)',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return 'Ingrese un valor entre 0 y 100';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomText(
                    controller: _descuentoMaximoController,
                    borderColor: AppColors.blue1,
                    label: 'Descuento Máx. (%)',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return 'Ingrese un valor entre 0 y 100';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      
    );
  }

  Widget _buildMultimediaSection() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      return const SizedBox.shrink();
    }

    return ProductoVideoManager(
      empresaId: empresaState.context.empresa.id,
      initialVideoUrl: _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
      storageService: locator<StorageService>(),
      onVideoUploaded: (String? videoUrl) {
        // Actualizar el controller cuando el video se suba o elimine
        _videoUrlController.text = videoUrl ?? '';
        _markAsChanged();
      },
    );
  }

  Widget _buildOptionsSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('OPCIONES'),
            const SizedBox(height: 8),
            CustomSwitchTile(
              activeColor: Colors.green,
              activeTrackColor: Colors.green.shade200,
              title: 'Visible en Marketplace',
              subtitle: 'El producto aparecerá en el marketplace público',
              value: _visibleMarketplace,
              onChanged: (value) {
                setState(() {
                  _visibleMarketplace = value;
                  _markAsChanged();
                });
              },
            ),
            const SizedBox(height: 4),
            CustomSwitchTile(
              title: 'Producto Destacado',
              subtitle: 'Se mostrará con prioridad en listados',
              value: _destacado,
              onChanged: (value) {
                setState(() {
                  _destacado = value;
                  _markAsChanged();
                });
              },
            ),
          ],
        ),
      
    );
  }

  Widget _buildPlantillasSection() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      return const SizedBox.shrink();
    }

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('PLANTILLA DE ATRIBUTOS'),
            const SizedBox(height: 8),

            AppSubtitle('Selecciona una plantilla para cargar automáticamente sus atributos. Esto reemplazará los atributos por categoría.', fontSize: 10, color: Colors.blueGrey,),
            const SizedBox(height: 16),
            BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
              builder: (context, state) {
                if (state is AtributoPlantillaLoading) {
                  return const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator( strokeWidth: 1)),);
                }
                if (state is AtributoPlantillaLoaded) {
                  final plantillas = state.plantillas;
                  if (plantillas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppSubtitle(
                        'No hay plantillas creadas. Puedes crearlas en la sección "Plantillas de Atributos".',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  }

                  // Verificar que el valor seleccionado esté en la lista
                  // Usar 'none' en lugar de null para evitar problemas con el dropdown
                  String selectedValue = _selectedPlantillaId ?? 'none';
                  final plantillaIds = plantillas.map((p) => p.id).toSet();
                  if (_selectedPlantillaId != null && !plantillaIds.contains(_selectedPlantillaId)) {
                    // Si el valor seleccionado no está en la lista, resetear
                    selectedValue = 'none';
                    // También limpiar la plantilla seleccionada
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _onPlantillaSelected(null);
                      }
                    });
                  }

                  // Crear items sin duplicados usando Set para eliminar IDs duplicados
                  final uniquePlantillas = <String, AtributoPlantilla>{};
                  for (final plantilla in plantillas) {
                    uniquePlantillas[plantilla.id] = plantilla;
                  }

                  final items = <DropdownItem<String>>[
                    const DropdownItem(
                      value: 'none',
                      label: 'Ninguna (sin plantilla)',
                    ),
                    ...uniquePlantillas.values.map((plantilla) {
                      return DropdownItem(
                        value: plantilla.id,
                        label: plantilla.nombre,
                      );
                    }),
                  ];

                  return CustomDropdown<String>(
                    label: 'Seleccionar Plantilla',
                    hintText: 'Elige una plantilla de atributos',
                    borderColor: AppColors.blue1,
                    prefixIcon: const Icon(Icons.description_outlined, size: 16, color: AppColors.blue1,),
                    value: selectedValue,
                    items: items,
                    onChanged: (value) {
                      // Convertir 'none' a null antes de pasar a _onPlantillaSelected
                      _onPlantillaSelected(value == 'none' ? null : value);
                    },
                  );
                }
                if (state is AtributoPlantillaError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error al cargar plantillas: ${state.message}',
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (_selectedPlantilla != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  AppSubtitle('ATRIBUTOS DE LA PLANTILLA'),
                  const Spacer(),
                  InfoChip(icon: Icons.info_outline, text: '${_selectedPlantilla!.atributos.length} atributo(s)'),
                  if (_selectedPlantilla!.atributos.any((a) => a.esRequerido)) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '${_selectedPlantilla!.atributos.where((a) => a.esRequerido).length} requerido(s)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppSubtitle(
                        'Completa los valores de los atributos. Los marcados como "Requerido" son obligatorios.',
                        fontSize: 10,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._selectedPlantilla!.atributos.map((plantillaAtributo) {
                final atributoInfo = plantillaAtributo.atributo;
                // Convertir AtributoInfo a ProductoAtributo
                // Usar valoresActuales que retorna valoresOverride si existe, sino valores base
                final productoAtributo = ProductoAtributo(
                  id: atributoInfo.id,
                  empresaId: '', // No necesario para visualización
                  categoriaId: null,
                  nombre: atributoInfo.nombre,
                  clave: atributoInfo.clave,
                  tipo: atributoInfo.tipoEnum,
                  requerido: plantillaAtributo.esRequerido,
                  descripcion: atributoInfo.descripcion,
                  unidad: atributoInfo.unidad,
                  valores: plantillaAtributo.valoresActuales, // ✅ Usa override o base
                  orden: plantillaAtributo.orden,
                  mostrarEnListado: false,
                  usarParaFiltros: false,
                  mostrarEnMarketplace: false,
                  isActive: true,
                  creadoEn: DateTime.now(),
                  actualizadoEn: DateTime.now(),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AtributoInputWidget(
                    atributo: productoAtributo,
                    valorActual: _plantillaAtributosValues[atributoInfo.id] ?? '',
                    onChanged: (value) => _onPlantillaAtributoChanged(atributoInfo.id, value),
                  ),
                );
              }),
            ],
          ],
        ),
      
    );
  }

  Widget _buildConfiguracionPrecioSelector() {
    return BlocBuilder<ConfiguracionPrecioCubit, ConfiguracionPrecioState>(
      builder: (context, state) {
        if (state is ConfiguracionPrecioLoaded) {
          return ConfiguracionPrecioSelector(
            configuraciones: state.configuraciones,
            configuracionSeleccionadaId: _selectedConfiguracionPrecioId,
            onChanged: (value) {
              setState(() {
                _selectedConfiguracionPrecioId = value;
                _markAsChanged();
              });
            },
            onManageConfigurations: () {
              context.push('/empresa/configuraciones-precio');
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
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
          // Limpiar el error después de mostrarlo
          context.read<PrecioNivelCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state is PrecioNivelLoading) {
          return const GradientContainer(
            shadowStyle: ShadowStyle.neumorphic,
            borderColor: AppColors.blue1,
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PrecioNivelLoaded) {
          // Obtener precio base del producto
          final precioBase = double.tryParse(_precioController.text);

          return PrecioNivelesSection(
            niveles: state.niveles,
            precioBase: precioBase,
            onNivelCreated: (dto) => _handleNivelCreated(dto),
            onNivelUpdated: (nivelId, dto) => _handleNivelUpdated(nivelId, dto),
            onNivelDeleted: (nivelId) => _handleNivelDeleted(nivelId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _handleNivelCreated(PrecioNivelDto dto) {
    if (widget.productoId != null) {
      context.read<PrecioNivelCubit>().crearNivelProducto(
            productoId: widget.productoId!,
            dto: dto,
          );
    }
  }

  void _handleNivelUpdated(String nivelId, PrecioNivelDto dto) {
    context.read<PrecioNivelCubit>().actualizarNivel(
          nivelId: nivelId,
          dto: dto,
        );
  }

  void _handleNivelDeleted(String nivelId) {
    context.read<PrecioNivelCubit>().eliminarNivel(nivelId);
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      backgroundColor: AppColors.blue1,
      text: widget.isEditing ? 'Actualizar Producto' : 'Crear Producto',
      isLoading: _isLoading,
      onPressed: _submit,
    );
  }
}

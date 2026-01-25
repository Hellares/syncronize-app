import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/services/storage_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/atributo_valor.dart';
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
import '../bloc/agregar_stock_inicial/agregar_stock_inicial_cubit.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import 'agregar_stock_inicial_page.dart';
import '../../domain/entities/producto.dart';
import '../bloc/configuracion_precio/configuracion_precio_state.dart';
import '../bloc/producto_form/producto_form_cubit.dart';
import '../bloc/producto_form/producto_form_state.dart';
import '../widgets/producto_images_manager.dart';
import '../widgets/producto_video_manager.dart';
import '../widgets/atributo_input_widget.dart';
import '../widgets/precio_niveles_section.dart';
import '../widgets/configuracion_precio_selector.dart';
import '../../data/models/precio_nivel_model.dart';
import '../widgets/form_sections/producto_basic_info_section.dart';
import '../widgets/form_sections/producto_pricing_section.dart';
import '../widgets/form_sections/producto_oferta_section.dart';
import '../widgets/form_sections/producto_inventory_section.dart';
import '../widgets/form_sections/producto_dimensiones_section.dart';
import '../widgets/form_sections/producto_options_section.dart';
import '../widgets/form_sections/producto_tipo_section.dart';
import '../widgets/form_sections/producto_categorizacion_section.dart';
import '../widgets/form_sections/producto_impuestos_section.dart';
import '../widgets/form_sections/producto_variantes_banner.dart';
import '../widgets/form_sections/producto_combo_banner.dart';
import '../controllers/producto_form_controller.dart';

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
          BlocProvider(create: (_) => ProductoFormCubit()),
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
        BlocProvider(create: (_) => ProductoFormCubit()),
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
  /// Controller centralizado para el estado del formulario
  late final ProductoFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductoFormController();
    _controller.addListener(_onControllerChanged);
    _controller.setupChangeListeners();
    _loadCatalogos();

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
            final sedeIdInicial = () {
              try {
                final sedePrincipal = sedesActivas.firstWhere((sede) => sede.esPrincipal);
                return sedePrincipal.id;
              } catch (e) {
                // Si no hay sede principal, tomar la primera
                return sedesActivas.first.id;
              }
            }();

            setState(() {
              _controller.selectedSedesIds = [sedeIdInicial];
            });
          }
        }
      }
    });

    if (widget.isEditing) {
      _loadProducto();
    }
  }

  /// Callback cuando el controller notifica cambios
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Marcar que hay cambios sin guardar
  void _markAsChanged() {
    _controller.markAsChanged();
  }

  /// Verificar si hay cambios sin guardar (incluyendo imágenes)
  bool _hasChanges() {
    // if (_formSubmittedSuccessfully) return false;
    if (_controller.formSubmittedSuccessfully) return false;

    // Verificar cambios en el formulario
    if (_controller.hasUnsavedChanges) return true;

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
    _controller.nombreController.text = producto.nombre;
    _controller.descripcionController.text = producto.descripcion ?? '';
    _controller.skuController.text = producto.sku ?? '';
    _controller.codigoBarrasController.text = producto.codigoBarras ?? '';
    _controller.precioController.currencyValue = producto.precio;
    _controller.precioCostoController.currencyValue = producto.precioCosto ?? 0.0;
    // NOTA: El stock ya no se edita desde el formulario de producto.
    // Ahora se maneja por sede mediante ProductoStock
    // _controller.stockController.text = producto.stockTotal.toString();
    // _controller.stockMinimoController.text = '';
    _controller.pesoController.text = producto.peso?.toString() ?? '';
    _controller.videoUrlController.text = producto.videoUrl ?? '';
    _controller.impuestoPorcentajeController.text = producto.impuestoPorcentaje?.toString() ?? '';
    _controller.descuentoMaximoController.text = producto.descuentoMaximo?.toString() ?? '';

    // Cargar estado de esCombo para validación XOR
    _controller.esCombo = producto.esCombo ?? false;
    // Cargar tipo de precio combo si existe
    // _tipoPrecioCombo = producto.tipoPrecioCombo;
    _controller.tipoPrecioCombo = producto.tipoPrecioCombo;

    // Cargar estado isActive para validación de variantes
    // _productoIsActive = producto.isActive ?? true;
    _controller.productoIsActive = producto.isActive ?? true;

    // Cargar dimensiones si existen
    if (producto.dimensiones != null && producto.dimensiones is Map) {
      _controller.dimensionLargoController.text = producto.dimensiones['largo']?.toString() ?? '';
      _controller.dimensionAnchoController.text = producto.dimensiones['ancho']?.toString() ?? '';
      _controller.dimensionAltoController.text = producto.dimensiones['alto']?.toString() ?? '';
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

    // Cargar atributos del producto (si tiene y no es variante ni combo)
    if (!producto.tieneVariantes && !producto.esCombo &&
        producto.atributosValores != null &&
        producto.atributosValores!.isNotEmpty) {
      _cargarAtributosProducto(producto.atributosValores!);
    }

    setState(() {
      _controller.selectedCategoriaId = producto.empresaCategoriaId;
      _controller.selectedMarcaId = producto.empresaMarcaId;

      // Cargar todas las sedes donde está el producto (basado en stocksPorSede)
      if (producto.stocksPorSede != null && producto.stocksPorSede!.isNotEmpty) {
        _controller.selectedSedesIds = (producto.stocksPorSede as List)
            .map<String>((stock) => stock.sedeId as String)
            .toList();
      } else if (producto.sedeId != null) {
        // Fallback para productos antiguos sin stocksPorSede
        _controller.selectedSedesIds = [producto.sedeId!];
      } else {
        _controller.selectedSedesIds = [];
      }

      _controller.selectedUnidadMedidaId = producto.unidadMedidaId;  // Cargar unidad de medida del producto
      // _selectedConfiguracionPrecioId = producto.configuracionPrecioId;
      _controller.selectedConfiguracionPrecioId = producto.configuracionPrecioId;
      _controller.visibleMarketplace = producto.visibleMarketplace;
      _controller.destacado = producto.destacado;
      _controller.enOferta = producto.enOferta;
      _controller.tieneVariantes = producto.tieneVariantes;

      if (producto.enOferta) {
        _controller.precioOfertaController.currencyValue = producto.precioOferta ?? 0.0;
        // _fechaInicioOferta = producto.fechaInicioOferta;
        // _fechaFinOferta = producto.fechaFinOferta;
        _controller.fechaInicioOferta = producto.fechaInicioOferta;
        _controller.fechaFinOferta = producto.fechaFinOferta;
      }
    });
  }

  /// Cargar atributos del producto y detectar la plantilla correspondiente
  void _cargarAtributosProducto(List<AtributoValor> atributosValores) {
    if (atributosValores.isEmpty) return;

    // Obtener los IDs de los atributos del producto
    final atributosIds = atributosValores.map((av) => av.atributoId).toSet();

    // Buscar plantilla que coincida con estos atributos
    final plantillaState = context.read<AtributoPlantillaCubit>().state;
    if (plantillaState is AtributoPlantillaLoaded) {
      // Buscar plantilla que contenga exactamente los mismos atributos
      AtributoPlantilla? plantillaCoincidente;

      for (final plantilla in plantillaState.plantillas) {
        final plantillaAtributosIds = plantilla.atributos.map((pa) => pa.atributo.id).toSet();

        // Verificar si los atributos del producto están contenidos en esta plantilla
        // (puede que la plantilla tenga más atributos, pero debe tener al menos los del producto)
        if (atributosIds.every((id) => plantillaAtributosIds.contains(id))) {
          plantillaCoincidente = plantilla;
          break;
        }
      }

      if (plantillaCoincidente != null) {
        // Cargar la plantilla encontrada
        setState(() {
          _controller.selectedPlantillaId = plantillaCoincidente!.id;
          _controller.selectedPlantilla = plantillaCoincidente;
          _controller.plantillaAtributosValues.clear();

          // Cargar los valores de los atributos
          for (final atributoValor in atributosValores) {
            _controller.plantillaAtributosValues[atributoValor.atributoId] = atributoValor.valor;
          }

          // Inicializar valores vacíos para atributos que no tienen valor
          for (final atributo in plantillaCoincidente.atributos) {
            if (!_controller.plantillaAtributosValues.containsKey(atributo.atributo.id)) {
              _controller.plantillaAtributosValues[atributo.atributo.id] = '';
            }
          }
        });
      } else {
        // Si no se encuentra plantilla coincidente, cargar los valores sin plantilla
        // En este caso, los atributos se asignaron manualmente (sin plantilla)
        // No hacer nada, ya que la UI solo muestra plantillas
      }
    }
  }

  @override
  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _loadCatalogos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final empresaId = empresaState.context.empresa.id;
      context.read<CategoriasEmpresaCubit>().loadCategorias(empresaId);
      context.read<MarcasEmpresaCubit>().loadMarcas(empresaId);
      context.read<ConfiguracionPrecioCubit>().loadConfiguraciones();
      // UnidadMedidaDropdown carga las unidades internamente
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
        _controller.selectedPlantillaId = null;
        _controller.selectedPlantilla = null;
        _controller.plantillaAtributosValues.clear();
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
          _controller.selectedPlantillaId = plantillaId;
          _controller.selectedPlantilla = foundPlantilla;
          _controller.plantillaAtributosValues.clear();
          // Inicializar valores vacíos para cada atributo
          for (final atributo in foundPlantilla!.atributos) {
            _controller.plantillaAtributosValues[atributo.atributo.id] = '';
          }
        });
      }
    }
  }

  void _onPlantillaAtributoChanged(String atributoId, String value) {
    setState(() {
      _controller.plantillaAtributosValues[atributoId] = value;
      _markAsChanged();
    });
  }

  Future<void> _submit() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;
    final imagesCubit = context.read<ProductoImagesCubit>();

    // Obtener IDs de imágenes ya subidas
    final imagenesIds = imagesCubit.getUploadedImageIds();

    // Llamar al cubit para manejar el submit
    context.read<ProductoFormCubit>().submit(
      controller: _controller,
      empresaId: empresaId,
      isEditing: widget.isEditing,
      productoId: widget.productoId,
      imagenesIds: imagenesIds,
      uploadPendingImages: () async {
        final imagesState = imagesCubit.state;
        List<String> uploadedIds = [];

        if (imagesState is ProductoImagesLoaded) {
          if (imagesState.hasPendingImages) {
            final newIds = await imagesCubit.uploadAllPendingImages(empresaId);
            uploadedIds.addAll(newIds);
          }
          if (imagesState.hasErrors) {
            final retriedIds = await imagesCubit.retryFailedUploads(empresaId);
            uploadedIds.addAll(retriedIds);
          }
        }

        return uploadedIds;
      },
    );
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
              key: _controller.formKey,
              child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                children: [
                ProductoBasicInfoSection(
                  nombreController: _controller.nombreController,
                  descripcionController: _controller.descripcionController,
                  skuController: _controller.skuController,
                  codigoBarrasController: _controller.codigoBarrasController,
                ),
                const SizedBox(height: 24),
                ProductoTipoSection(
                  tieneVariantes: _controller.tieneVariantes,
                  esCombo: _controller.esCombo,
                  tipoPrecioCombo: _controller.tipoPrecioCombo, //_tipoPrecioCombo,
                  isEditing: widget.isEditing,
                  onTieneVariantesChanged: (value) {
                    setState(() {
                      _controller.tieneVariantes = value;
                      _markAsChanged();
                      if (value) {
                        _controller.precioController.text = '0';
                        // Stock ya no se maneja aquí, se agrega después mediante ProductoStock
                        _controller.skuController.clear();
                        _controller.enOferta = false;
                        _controller.precioOfertaController.clear();
                      }
                    });
                  },
                  onEsComboChanged: (value) {
                    setState(() {
                      _controller.esCombo = value;
                      _markAsChanged();
                      if (!value) {
                        // _tipoPrecioCombo = null;
                        _controller.tipoPrecioCombo = null;
                      }
                    });
                  },
                  onTipoPrecioComboChanged: (value) {
                    setState(() {
                      // _tipoPrecioCombo = value;
                      _controller.tipoPrecioCombo = value;
                      _markAsChanged();
                    });
                  },
                  onShowConversionDialog: _mostrarDialogoConversionVariantes,
                ),
                const SizedBox(height: 24),
                ProductoCategorizacionSection(
                  selectedCategoriaId: _controller.selectedCategoriaId,
                  selectedMarcaId: _controller.selectedMarcaId,
                  selectedSedesIds: _controller.selectedSedesIds,
                  selectedUnidadMedidaId: _controller.selectedUnidadMedidaId,
                  isEditing: widget.isEditing,
                  onCategoriaChanged: (value) {
                    setState(() => _controller.selectedCategoriaId = value);
                  },
                  onMarcaChanged: (value) {
                    setState(() => _controller.selectedMarcaId = value);
                  },
                  onSedesChanged: (value) {
                    setState(() => _controller.selectedSedesIds = value);
                  },
                  onUnidadMedidaChanged: (value) {
                    setState(() {
                      _controller.selectedUnidadMedidaId = value;
                      _markAsChanged();
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Plantilla de atributos (solo para productos simples)
                if (!_controller.tieneVariantes && !_controller.esCombo) ...[
                  _buildPlantillasSection(),
                  const SizedBox(height: 24),
                ],
                if (!_controller.tieneVariantes && !_controller.esCombo) ...[
                  ProductoPricingSection(
                    precioController: _controller.precioController,
                    precioCostoController: _controller.precioCostoController,
                    esCombo: _controller.esCombo,
                    tipoPrecioCombo: _controller.tipoPrecioCombo,//_tipoPrecioCombo,
                  ),
                  const SizedBox(height: 24),
                  // Selector de configuración de precios
                  _buildConfiguracionPrecioSelector(),
                  const SizedBox(height: 24),
                  // Sección de precios por volumen (solo en modo edición)
                  if (widget.isEditing) ...[
                    _buildPrecioNivelesSection(),
                    const SizedBox(height: 24),
                  ],
                  ProductoOfertaSection(
                    enOferta: _controller.enOferta,
                    onEnOfertaChanged: (value) {
                      setState(() {
                        _controller.enOferta = value;
                        if (!value) {
                          _controller.precioOfertaController.clear();
                          _controller.fechaInicioOferta = null;
                          _controller.fechaFinOferta = null;
                        }
                      });
                    },
                    precioOfertaController: _controller.precioOfertaController,
                    precioController: _controller.precioController,
                    // fechaInicioOferta: _fechaInicioOferta,
                    // fechaFinOferta: _fechaFinOferta,
                    fechaInicioOferta: _controller.fechaInicioOferta,
                    fechaFinOferta: _controller.fechaFinOferta,                    
                    onFechaInicioChanged: (date) {
                      setState(() {
                        _controller.fechaInicioOferta = date;
                      });
                    },
                    onFechaFinChanged: (date) {
                      setState(() {
                        _controller.fechaFinOferta = date;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ProductoInventorySection(
                    pesoController: _controller.pesoController,
                  ),
                  const SizedBox(height: 24),
                ] else if (_controller.tieneVariantes) ...[
                  ProductoVariantesBanner(
                    isEditing: widget.isEditing,
                    productoId: widget.productoId,
                    nombreProducto: _controller.nombreController.text,
                    categoriaId: _controller.selectedCategoriaId,
                    productoIsActive: _controller.productoIsActive,
                  ),
                  const SizedBox(height: 24),
                ] else if (_controller.esCombo) ...[
                  ProductoComboBanner(
                    isEditing: widget.isEditing,
                    tipoPrecioCombo: _controller.tipoPrecioCombo,
                  ),
                  const SizedBox(height: 24),
                ],
                _buildImagesSection(),
                const SizedBox(height: 24),
                ProductoDimensionesSection(
                  largoController: _controller.dimensionLargoController,
                  anchoController: _controller.dimensionAnchoController,
                  altoController: _controller.dimensionAltoController,
                ),
                const SizedBox(height: 24),
                ProductoImpuestosSection(
                  impuestoPorcentajeController: _controller.impuestoPorcentajeController,
                  descuentoMaximoController: _controller.descuentoMaximoController,
                ),
                const SizedBox(height: 24),
                _buildMultimediaSection(),
                const SizedBox(height: 24),
                ProductoOptionsSection(
                  visibleMarketplace: _controller.visibleMarketplace,
                  destacado: _controller.destacado,
                  onVisibleMarketplaceChanged: (value) {
                    setState(() {
                      _controller.visibleMarketplace = value;
                      _markAsChanged();
                    });
                  },
                  onDestacadoChanged: (value) {
                    setState(() {
                      _controller.destacado = value;
                      _markAsChanged();
                    });
                  },
                ),
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

    // Envolver con BlocListener para el cubit del formulario
    content = BlocListener<ProductoFormCubit, ProductoFormState>(
      listener: (context, state) {
        if (state is ProductoFormLoading) {
          setState(() =>  _controller.isLoading = true);
        } else if (state is ProductoFormSuccess) {
          setState(() {
            _controller.isLoading = false;
            _controller.formSubmittedSuccessfully = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );

          // Si es creación (no edición), preguntar si desea agregar stock
          if (widget.productoId == null) {
            _mostrarDialogoAgregarStock(state.producto);
          } else {
            context.pop();
          }
        } else if (state is ProductoFormError) {
          setState(() =>  _controller.isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ProductoFormValidationError) {
          setState(() =>  _controller.isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is ProductoFormInitial) {
          setState(() =>  _controller.isLoading = false);
        }
      },
      child: content,
    );

    if (widget.isEditing) {
      // Listener para cuando se carga el producto
      content = BlocListener<ProductoDetailCubit, ProductoDetailState>(
        listener: (context, state) {
          if (state is ProductoDetailLoaded) {
            _fillFormWithProducto(state.producto);
          }
        },
        child: content,
      );

      // Listener para cuando se cargan las plantillas (para productos con atributos)
      content = BlocListener<AtributoPlantillaCubit, AtributoPlantillaState>(
        listener: (context, state) {
          if (state is AtributoPlantillaLoaded) {
            // Si ya se cargó el producto y tiene atributos, intentar cargarlos
            final productoState = context.read<ProductoDetailCubit>().state;
            if (productoState is ProductoDetailLoaded) {
              final producto = productoState.producto;
              if (!producto.tieneVariantes && !producto.esCombo &&
                  producto.atributosValores != null &&
                  producto.atributosValores!.isNotEmpty) {
                _cargarAtributosProducto(producto.atributosValores!);
              }
            }
          }
        },
        child: content,
      );
    }

    return content;
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
                      'Precio actual: \$${_controller.precioController.text}\nEl stock se agregará después por sede',
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

  Widget _buildMultimediaSection() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      return const SizedBox.shrink();
    }

    return ProductoVideoManager(
      empresaId: empresaState.context.empresa.id,
      initialVideoUrl: _controller.videoUrlController.text.isEmpty ? null : _controller.videoUrlController.text,
      storageService: locator<StorageService>(),
      onVideoUploaded: (String? videoUrl) {
        // Actualizar el controller cuando el video se suba o elimine
        _controller.videoUrlController.text = videoUrl ?? '';
        _markAsChanged();
      },
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
                  String selectedValue = _controller.selectedPlantillaId ?? 'none';
                  final plantillaIds = plantillas.map((p) => p.id).toSet();
                    // Si el valor seleccionado no está en la lista, resetear
                  if (_controller.selectedPlantillaId != null && !plantillaIds.contains(_controller.selectedPlantillaId)) {
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
            if (_controller.selectedPlantilla != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  AppSubtitle('ATRIBUTOS DE LA PLANTILLA'),
                  const Spacer(),
                  InfoChip(icon: Icons.info_outline, text: '${_controller.selectedPlantilla!.atributos.length} atributo(s)'),
                  if (_controller.selectedPlantilla!.atributos.any((a) => a.esRequerido)) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '${_controller.selectedPlantilla!.atributos.where((a) => a.esRequerido).length} requerido(s)',
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
              ..._controller.selectedPlantilla!.atributos.map((plantillaAtributo) {
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
                    valorActual: _controller.plantillaAtributosValues[atributoInfo.id] ?? '',
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
            configuracionSeleccionadaId: _controller.selectedConfiguracionPrecioId,
            onChanged: (value) {
              setState(() {
                _controller.selectedConfiguracionPrecioId = value;
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
          final precioBase = double.tryParse(_controller.precioController.text);

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

  Future<void> _mostrarDialogoAgregarStock(Producto producto) async {
    final agregarStock = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Producto creado',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El producto "${producto.nombre}" fue creado exitosamente.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.blue1.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.blue1,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Desea agregar stock inicial ahora?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.blue1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Podrá agregarlo más tarde desde la gestión de inventario.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Más tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.inventory_2),
            label: const Text('Agregar stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );

    if (agregarStock == true && mounted) {
      // Navegar a la página de agregar stock
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => locator<AgregarStockInicialCubit>(),
              ),
              BlocProvider(
                create: (context) => locator<SedeListCubit>(),
              ),
            ],
            child: AgregarStockInicialPage(producto: producto),
          ),
        ),
      );

      // Volver a la pantalla anterior
      if (mounted) {
        context.pop();
      }
    } else {
      // Si no quiere agregar stock, simplemente volver
      if (mounted) {
        context.pop();
      }
    }
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      backgroundColor: AppColors.blue1,
      text: widget.isEditing ? 'Actualizar Producto' : 'Crear Producto',
      // isLoading: _isLoading,
      isLoading: _controller.isLoading,
      onPressed: _submit,
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';

/// Controller que centraliza el estado del formulario de producto.
/// Usa ChangeNotifier para notificar cambios a los widgets.
class ProductoFormController extends ChangeNotifier {
  // ============================================================
  // TEXT EDITING CONTROLLERS
  // ============================================================
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final skuController = TextEditingController();
  final codigoBarrasController = TextEditingController();
  final precioController = TextEditingController();
  final precioCostoController = TextEditingController();
  // DEPRECATED: Stock ahora se maneja mediante ProductoStock por sede
  // Mantenidos solo para compatibilidad al editar productos legacy
  final stockController = TextEditingController();
  final stockMinimoController = TextEditingController();
  final pesoController = TextEditingController();
  final precioOfertaController = TextEditingController();
  final videoUrlController = TextEditingController();
  final impuestoPorcentajeController = TextEditingController();
  final descuentoMaximoController = TextEditingController();
  final dimensionLargoController = TextEditingController();
  final dimensionAnchoController = TextEditingController();
  final dimensionAltoController = TextEditingController();

  /// Lista de todos los controllers para facilitar operaciones en lote
  List<TextEditingController> get allControllers => [
        nombreController,
        descripcionController,
        skuController,
        codigoBarrasController,
        precioController,
        precioCostoController,
        stockController,
        stockMinimoController,
        pesoController,
        precioOfertaController,
        videoUrlController,
        impuestoPorcentajeController,
        descuentoMaximoController,
        dimensionLargoController,
        dimensionAnchoController,
        dimensionAltoController,
      ];

  // ============================================================
  // FORM KEY
  // ============================================================
  final formKey = GlobalKey<FormState>();

  // ============================================================
  // SELECCIONES (Dropdowns)
  // ============================================================
  String? _selectedCategoriaId;
  String? get selectedCategoriaId => _selectedCategoriaId;
  set selectedCategoriaId(String? value) {
    _selectedCategoriaId = value;
    markAsChanged();
    notifyListeners();
  }

  String? _selectedMarcaId;
  String? get selectedMarcaId => _selectedMarcaId;
  set selectedMarcaId(String? value) {
    _selectedMarcaId = value;
    markAsChanged();
    notifyListeners();
  }

  List<String> _selectedSedesIds = [];
  List<String> get selectedSedesIds => _selectedSedesIds;
  set selectedSedesIds(List<String> value) {
    _selectedSedesIds = value;
    markAsChanged();
    notifyListeners();
  }

  String? _selectedUnidadMedidaId;
  String? get selectedUnidadMedidaId => _selectedUnidadMedidaId;
  set selectedUnidadMedidaId(String? value) {
    _selectedUnidadMedidaId = value;
    markAsChanged();
    notifyListeners();
  }

  String? _selectedConfiguracionPrecioId;
  String? get selectedConfiguracionPrecioId => _selectedConfiguracionPrecioId;
  set selectedConfiguracionPrecioId(String? value) {
    _selectedConfiguracionPrecioId = value;
    markAsChanged();
    notifyListeners();
  }

  // ============================================================
  // FLAGS BOOLEANOS
  // ============================================================
  bool _visibleMarketplace = true;
  bool get visibleMarketplace => _visibleMarketplace;
  set visibleMarketplace(bool value) {
    _visibleMarketplace = value;
    markAsChanged();
    notifyListeners();
  }

  bool _destacado = false;
  bool get destacado => _destacado;
  set destacado(bool value) {
    _destacado = value;
    markAsChanged();
    notifyListeners();
  }

  bool _enOferta = false;
  bool get enOferta => _enOferta;
  set enOferta(bool value) {
    _enOferta = value;
    if (!value) {
      // Limpiar valores de oferta cuando se desactiva
      precioOfertaController.clear();
      _fechaInicioOferta = null;
      _fechaFinOferta = null;
    }
    markAsChanged();
    notifyListeners();
  }

  bool _tieneVariantes = false;
  bool get tieneVariantes => _tieneVariantes;
  set tieneVariantes(bool value) {
    _tieneVariantes = value;
    markAsChanged();
    notifyListeners();
  }

  bool _esCombo = false;
  bool get esCombo => _esCombo;
  set esCombo(bool value) {
    _esCombo = value;
    if (!value) {
      _tipoPrecioCombo = null;
    }
    markAsChanged();
    notifyListeners();
  }

  bool _productoIsActive = true;
  bool get productoIsActive => _productoIsActive;
  set productoIsActive(bool value) {
    _productoIsActive = value;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // OTRAS VARIABLES
  // ============================================================
  String? _tipoPrecioCombo;
  String? get tipoPrecioCombo => _tipoPrecioCombo;
  set tipoPrecioCombo(String? value) {
    _tipoPrecioCombo = value;
    markAsChanged();
    notifyListeners();
  }

  DateTime? _fechaInicioOferta;
  DateTime? get fechaInicioOferta => _fechaInicioOferta;
  set fechaInicioOferta(DateTime? value) {
    _fechaInicioOferta = value;
    markAsChanged();
    notifyListeners();
  }

  DateTime? _fechaFinOferta;
  DateTime? get fechaFinOferta => _fechaFinOferta;
  set fechaFinOferta(DateTime? value) {
    _fechaFinOferta = value;
    markAsChanged();
    notifyListeners();
  }

  // ============================================================
  // PLANTILLA DE ATRIBUTOS
  // ============================================================
  String? _selectedPlantillaId;
  String? get selectedPlantillaId => _selectedPlantillaId;
  set selectedPlantillaId(String? value) {
    _selectedPlantillaId = value;
    markAsChanged();
    notifyListeners();
  }

  AtributoPlantilla? _selectedPlantilla;
  AtributoPlantilla? get selectedPlantilla => _selectedPlantilla;
  set selectedPlantilla(AtributoPlantilla? value) {
    _selectedPlantilla = value;
    notifyListeners();
  }

  final Map<String, String> plantillaAtributosValues = {};

  void setPlantillaAtributoValue(String atributoId, String value) {
    plantillaAtributosValues[atributoId] = value;
    markAsChanged();
    notifyListeners();
  }

  // ============================================================
  // CONTROL DE CAMBIOS
  // ============================================================
  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  bool _formSubmittedSuccessfully = false;
  bool get formSubmittedSuccessfully => _formSubmittedSuccessfully;
  set formSubmittedSuccessfully(bool value) {
    _formSubmittedSuccessfully = value;
    notifyListeners();
  }

  /// Marca que hay cambios sin guardar
  void markAsChanged() {
    if (!_hasUnsavedChanges && !_formSubmittedSuccessfully) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// Resetea el flag de cambios (después de guardar exitosamente)
  void clearChanges() {
    _hasUnsavedChanges = false;
    _formSubmittedSuccessfully = true;
    notifyListeners();
  }

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  /// Configura listeners en los controllers para detectar cambios
  void setupChangeListeners() {
    for (var controller in allControllers) {
      controller.addListener(markAsChanged);
    }
  }

  /// Llena el formulario con los datos de un producto existente
  void fillFromProducto(Producto producto) {
    nombreController.text = producto.nombre;
    descripcionController.text = producto.descripcion ?? '';
    skuController.text = producto.sku ?? '';
    codigoBarrasController.text = producto.codigoBarras ?? '';
    precioController.currencyValue = producto.precio;
    precioCostoController.currencyValue = producto.precioCosto ?? 0.0;
    // NOTA: Los campos stock y stockMinimo fueron removidos.
    // El stock se gestiona por sede usando ProductoStock después de crear el producto.
    stockController.text = '0'; // Default para compatibilidad del formulario
    stockMinimoController.text = ''; // Default vacío
    pesoController.text = producto.peso?.toString() ?? '';
    precioOfertaController.currencyValue = producto.precioOferta ?? 0.0;
    videoUrlController.text = producto.videoUrl ?? '';
    impuestoPorcentajeController.text = producto.impuestoPorcentaje?.toString() ?? '';
    descuentoMaximoController.text = producto.descuentoMaximo?.toString() ?? '';

    // Dimensiones vienen en un Map
    if (producto.dimensiones != null) {
      dimensionLargoController.text = producto.dimensiones!['largo']?.toString() ?? '';
      dimensionAnchoController.text = producto.dimensiones!['ancho']?.toString() ?? '';
      dimensionAltoController.text = producto.dimensiones!['alto']?.toString() ?? '';
    }

    _selectedCategoriaId = producto.empresaCategoriaId;
    _selectedMarcaId = producto.empresaMarcaId;
    _selectedSedesIds = producto.sedeId != null ? [producto.sedeId!] : [];
    _selectedUnidadMedidaId = producto.unidadMedidaId;
    _selectedConfiguracionPrecioId = producto.configuracionPrecioId;
    _visibleMarketplace = producto.visibleMarketplace;
    _destacado = producto.destacado;
    _enOferta = producto.enOferta;
    _tieneVariantes = producto.tieneVariantes;
    _esCombo = producto.esCombo;
    _tipoPrecioCombo = producto.tipoPrecioCombo;
    _productoIsActive = producto.isActive;
    _fechaInicioOferta = producto.fechaInicioOferta;
    _fechaFinOferta = producto.fechaFinOferta;

    // Resetear el flag de cambios después de llenar el formulario
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Establece la sede por defecto (sede principal o primera activa)
  void setDefaultSede(String? sedeId) {
    if (_selectedSedesIds.isEmpty && sedeId != null) {
      _selectedSedesIds = [sedeId];
      notifyListeners();
    }
  }

  /// Resetea el formulario a valores por defecto
  void reset() {
    for (var controller in allControllers) {
      controller.clear();
    }

    _selectedCategoriaId = null;
    _selectedMarcaId = null;
    _selectedSedesIds = [];
    _selectedUnidadMedidaId = null;
    _selectedConfiguracionPrecioId = null;
    _selectedPlantillaId = null;
    _selectedPlantilla = null;
    plantillaAtributosValues.clear();

    _visibleMarketplace = true;
    _destacado = false;
    _enOferta = false;
    _tieneVariantes = false;
    _esCombo = false;
    _tipoPrecioCombo = null;
    _productoIsActive = true;
    _fechaInicioOferta = null;
    _fechaFinOferta = null;

    _hasUnsavedChanges = false;
    _formSubmittedSuccessfully = false;
    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // VALIDACIÓN DE ATRIBUTOS
  // ============================================================

  /// Valida que los atributos requeridos de la plantilla estén completos
  bool validarAtributosRequeridos() {
    if (_selectedPlantilla == null) return true;

    for (final atributo in _selectedPlantilla!.atributos) {
      if (atributo.esRequerido) {
        final value = plantillaAtributosValues[atributo.id];
        if (value == null || value.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  @override
  void dispose() {
    for (var controller in allControllers) {
      controller.removeListener(markAsChanged);
      controller.dispose();
    }
    super.dispose();
  }
}

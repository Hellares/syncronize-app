import 'package:flutter/material.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto.dart';
import '../../domain/entities/stock_por_sede_info.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';

/// Controller que centraliza el estado del formulario de producto.
/// Usa ChangeNotifier para notificar cambios a los widgets.
///
/// NOTA: Precio, precioCosto, stock, ofertas se gestionan por sede
/// mediante ProductoStock. Este formulario solo maneja datos del producto base.
class ProductoFormController extends ChangeNotifier {
  // ============================================================
  // TEXT EDITING CONTROLLERS
  // ============================================================
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final skuController = TextEditingController();

  /// Rótulo del identificador que se pide al vender ("IMEI", "Placa").
  final etiquetaIdentificadorCtrl = TextEditingController();
  final codigoBarrasController = TextEditingController();
  // precioController se mantiene solo como referencia para PrecioNivelesSection
  final precioController = TextEditingController();
  final precioCostoController = TextEditingController();
  final pesoController = TextEditingController();
  final videoUrlController = TextEditingController();
  final impuestoPorcentajeController = TextEditingController();
  final descuentoMaximoController = TextEditingController();
  String tipoAfectacionIgv = 'GRAVADO';
  bool aplicaIcbper = false;

  /// Código de producto SUNAT (catálogos 25.1/25.2/25.3). null = sin código.
  String? codigoProductoSunat;
  final dimensionLargoController = TextEditingController();
  final dimensionAnchoController = TextEditingController();
  final dimensionAltoController = TextEditingController();

  /// Lista de todos los controllers para facilitar operaciones en lote
  List<TextEditingController> get allControllers => [
        nombreController,
        descripcionController,
        skuController,
        etiquetaIdentificadorCtrl,
        codigoBarrasController,
        precioController,
        precioCostoController,
        pesoController,
        videoUrlController,
        impuestoPorcentajeController,
        descuentoMaximoController,
        dimensionLargoController,
        dimensionAnchoController,
        dimensionAltoController,
        factorCompraController,
        factorPresentacionController,
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

  /// Unidad de COMPRA (opcional). Cuando el proveedor te vende en una
  /// unidad distinta a la de venta (ej: PAQUETE de 100 BOLSAS).
  String? _selectedUnidadCompraId;
  String? get selectedUnidadCompraId => _selectedUnidadCompraId;
  set selectedUnidadCompraId(String? value) {
    _selectedUnidadCompraId = value;
    markAsChanged();
    notifyListeners();
  }

  /// Factor de conversión: cuántas unidades de venta trae 1 unidad
  /// de compra. Ej: 100 (BOLSAS por PAQUETE), 1000 (GR por KG).
  final TextEditingController factorCompraController = TextEditingController();

  /// Unidad de PRESENTACIÓN (opcional). Cómo se le habla al cliente cuando
  /// la unidad de venta es demasiado chica: se guarda en gramos y se cobra
  /// en KILOS. No cambia stock ni costo, que siguen en unidad de venta.
  String? _selectedUnidadPresentacionId;
  String? get selectedUnidadPresentacionId => _selectedUnidadPresentacionId;
  set selectedUnidadPresentacionId(String? value) {
    _selectedUnidadPresentacionId = value;
    markAsChanged();
    notifyListeners();
  }

  /// Cuántas unidades de venta trae 1 de presentación (1 kg = 1000 g).
  /// El backend exige que sea > 1: la presentación existe para AGRUPAR.
  final TextEditingController factorPresentacionController =
      TextEditingController();

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
  bool _visibleMarketplace = false;
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

  bool _requiereIdentificador = false;
  bool get requiereIdentificador => _requiereIdentificador;
  set requiereIdentificador(bool value) {
    _requiereIdentificador = value;
    markAsChanged();
    notifyListeners();
  }

  bool _esInsumo = false;
  bool get esInsumo => _esInsumo;
  set esInsumo(bool value) {
    _esInsumo = value;
    // Insumos no se muestran en marketplace ni se destacan
    if (value) {
      _visibleMarketplace = false;
      _destacado = false;
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

  // ============================================================
  // PLANTILLAS DE ATRIBUTOS (varias: son SECCIONES de la ficha técnica)
  // ============================================================
  //
  // Un celular puede traer PROCESADOR, MEMORIA, PANTALLA y DISEÑO, y ese mismo
  // DISEÑO lo reusa un peluche sin arrastrar nada de procesador. Con una sola
  // plantilla por producto habría que crear una por cada tipo repitiendo las
  // partes comunes.
  //
  // 🔑 Los valores viven por ATRIBUTO (`plantillaAtributosValues`), no por
  // plantilla: quitar una sección no borra lo que ya se cargó.

  final List<AtributoPlantilla> _plantillas = [];

  List<AtributoPlantilla> get plantillasSeleccionadas =>
      List.unmodifiable(_plantillas);

  List<String> get plantillasIds =>
      _plantillas.map((p) => p.id).toList(growable: false);

  bool tienePlantilla(String id) => _plantillas.any((p) => p.id == id);

  void agregarPlantilla(AtributoPlantilla plantilla) {
    if (tienePlantilla(plantilla.id)) return;
    _plantillas.add(plantilla);
    // Los atributos nuevos arrancan vacíos; los que ya tenían valor —porque
    // otra sección los traía— se respetan.
    for (final pa in plantilla.atributos) {
      plantillaAtributosValues.putIfAbsent(pa.atributo.id, () => '');
    }
    markAsChanged();
    notifyListeners();
  }

  /// Los atributos que SOLO trae [plantillaId].
  ///
  /// Son los que se van si se quita la sección. Un COLOR que otra sección
  /// aplicada también usa NO está acá: sigue teniendo dónde vivir.
  List<PlantillaAtributo> atributosExclusivosDe(String plantillaId) {
    final deOtras = <String>{};
    for (final p in _plantillas) {
      if (p.id == plantillaId) continue;
      for (final pa in p.atributos) {
        deOtras.add(pa.atributo.id);
      }
    }

    final out = <PlantillaAtributo>[];
    for (final p in _plantillas) {
      if (p.id != plantillaId) continue;
      for (final pa in p.atributos) {
        if (!deOtras.contains(pa.atributo.id)) out.add(pa);
      }
    }
    return out;
  }

  /// Saca una sección y, con ella, los valores de los atributos que solo esa
  /// sección traía.
  ///
  /// 🔴 Antes solo desagrupaba: los valores quedaban guardados y reaparecían
  /// en el detalle como características SUELTAS. Uno quitaba la plantilla,
  /// guardaba, y las mismas características seguían ahí bajo "Otras" sin que
  /// nada explicara por qué.
  void quitarPlantilla(String plantillaId) {
    for (final pa in atributosExclusivosDe(plantillaId)) {
      plantillaAtributosValues.remove(pa.atributo.id);
    }
    _plantillas.removeWhere((p) => p.id == plantillaId);
    markAsChanged();
    notifyListeners();
  }

  void setPlantillas(List<AtributoPlantilla> plantillas) {
    _plantillas
      ..clear()
      ..addAll(plantillas);
    notifyListeners();
  }

  /// Los atributos de TODAS las secciones, sin repetir.
  ///
  /// Un mismo atributo puede estar en dos plantillas —COLOR en DISEÑO y en
  /// otra—: el valor no se duplica porque se guarda por `atributoId`, pero sí
  /// se dibujaría el campo dos veces. Gana la primera sección que lo trae.
  List<PlantillaAtributo> get atributosAplicados {
    final vistos = <String>{};
    final out = <PlantillaAtributo>[];
    for (final plantilla in _plantillas) {
      for (final pa in plantilla.atributos) {
        if (vistos.add(pa.atributo.id)) out.add(pa);
      }
    }
    return out;
  }

  /// Los atributos de [plantillaId] que le toca dibujar a ESA sección, ya sin
  /// los que una sección anterior mostró.
  List<PlantillaAtributo> atributosDeSeccion(String plantillaId) {
    final vistos = <String>{};
    for (final plantilla in _plantillas) {
      final propios = <PlantillaAtributo>[];
      for (final pa in plantilla.atributos) {
        if (vistos.add(pa.atributo.id)) propios.add(pa);
      }
      if (plantilla.id == plantillaId) {
        propios.sort((a, b) => a.orden.compareTo(b.orden));
        return propios;
      }
    }
    return const [];
  }

  final Map<String, String> plantillaAtributosValues = {};

  /// El producto YA traía atributos guardados cuando se abrió el formulario.
  ///
  /// Hace falta para poder VACIAR la ficha: si se quitan todas las secciones,
  /// el guardado tiene que salir igual —con la lista corta o vacía— para que
  /// el backend borre lo que quedó afuera. Sin esta marca, un producto que
  /// nunca tuvo atributos se comería un guardado inútil cada vez.
  bool teniaAtributos = false;

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

  /// Llena el formulario con los datos de un producto existente.
  /// Precio/costo se cargan como referencia desde la primera sede con precio configurado.
  void fillFromProducto(Producto producto) {
    nombreController.text = producto.nombre;
    descripcionController.text = producto.descripcion ?? '';
    skuController.text = producto.sku ?? '';
    codigoBarrasController.text = producto.codigoBarras ?? '';

    // Cargar precio de referencia desde stocksPorSede (para PrecioNivelesSection)
    if (producto.stocksPorSede != null && producto.stocksPorSede!.isNotEmpty) {
      final stocks = producto.stocksPorSede!;
      final stockConPrecio = stocks.cast<StockPorSedeInfo>().firstWhere(
        (s) => s.precioConfigurado && s.precio != null,
        orElse: () => stocks.first,
      );
      precioController.currencyValue = stockConPrecio.precio ?? 0.0;
      precioCostoController.currencyValue = stockConPrecio.precioCosto ?? 0.0;
    }

    pesoController.text = producto.peso?.toString() ?? '';
    videoUrlController.text = producto.videoUrl ?? '';
    impuestoPorcentajeController.text = producto.impuestoPorcentaje?.toString() ?? '';
    descuentoMaximoController.text = producto.descuentoMaximo?.toString() ?? '';
    tipoAfectacionIgv = producto.tipoAfectacionIgv ?? 'GRAVADO';
    aplicaIcbper = producto.aplicaIcbper ?? false;
    codigoProductoSunat = producto.codigoProductoSunat;

    // Dimensiones
    if (producto.dimensiones != null) {
      dimensionLargoController.text = producto.dimensiones!['largo']?.toString() ?? '';
      dimensionAnchoController.text = producto.dimensiones!['ancho']?.toString() ?? '';
      dimensionAltoController.text = producto.dimensiones!['alto']?.toString() ?? '';
    }

    _selectedCategoriaId = producto.empresaCategoriaId;
    _selectedMarcaId = producto.empresaMarcaId;
    _selectedUnidadMedidaId = producto.unidadMedidaId;
    _selectedUnidadCompraId = producto.unidadCompraId;
    factorCompraController.text = producto.factorCompra?.toString() ?? '';
    _selectedUnidadPresentacionId = producto.unidadPresentacionId;
    // Sin decimales de relleno: un factor de 1000 se guarda como 1000.0 y
    // "1000.0" en el campo se lee como si tuviera precisión que no aporta.
    factorPresentacionController.text = _factorTexto(producto.factorPresentacion);
    _selectedConfiguracionPrecioId = producto.configuracionPrecioId;
    _visibleMarketplace = producto.visibleMarketplace;
    _destacado = producto.destacado;
    _tieneVariantes = producto.tieneVariantes;
    _esCombo = producto.esCombo;
    _esInsumo = producto.esInsumo;
    _requiereIdentificador = producto.requiereIdentificador;
    etiquetaIdentificadorCtrl.text = producto.etiquetaIdentificador ?? '';
    _tipoPrecioCombo = producto.tipoPrecioCombo;
    _productoIsActive = producto.isActive;

    // Cargar sedes desde stocksPorSede
    if (producto.stocksPorSede != null && producto.stocksPorSede!.isNotEmpty) {
      _selectedSedesIds = producto.stocksPorSede!
          .map<String>((stock) => stock.sedeId)
          .toList();
    } else if (producto.sedeId != null) {
      _selectedSedesIds = [producto.sedeId!];
    } else {
      _selectedSedesIds = [];
    }

    // Resetear el flag de cambios después de llenar el formulario
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Factor → texto editable. `1000.0` se muestra "1000": los decimales de
  /// relleno sugieren una precisión que el factor no tiene y encima el
  /// usuario los tiene que borrar a mano para corregirlo.
  static String _factorTexto(double? factor) {
    if (factor == null) return '';
    if (factor == factor.truncateToDouble()) return factor.toInt().toString();
    return factor.toString();
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
    _selectedUnidadCompraId = null;
    factorCompraController.clear();
    _selectedUnidadPresentacionId = null;
    factorPresentacionController.clear();
    _selectedConfiguracionPrecioId = null;
    _plantillas.clear();
    plantillaAtributosValues.clear();

    _visibleMarketplace = false;
    _destacado = false;
    _tieneVariantes = false;
    _esCombo = false;
    _esInsumo = false;
    _requiereIdentificador = false;
    etiquetaIdentificadorCtrl.clear();
    _tipoPrecioCombo = null;
    _productoIsActive = true;

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
    if (_plantillas.isEmpty) return true;

    for (final atributo in atributosAplicados) {
      if (atributo.esRequerido) {
        // 🔴 La clave del mapa es el id del ATRIBUTO, no el de la fila de la
        // plantilla. Con `atributo.id` buscaba una clave que nunca existe, así
        // que un requerido vacío pasaba como completo.
        final value = plantillaAtributosValues[atributo.atributo.id];
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

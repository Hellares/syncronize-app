import 'package:equatable/equatable.dart';

/// Tipos de atributos disponibles.
///
/// Comparte vocabulario con los tipos de campo de las plantillas de servicio:
/// las etiquetas y los íconos de los dos salen de `core/constants/tipos_dato`.
/// Qué tipos ofrece el selector, y en qué orden, lo define
/// `kTiposAtributoProducto` — este enum es solo lo que el backend acepta.
enum AtributoTipo {
  // Con lista de valores predefinidos
  select('SELECT'),
  multiSelect('MULTI_SELECT'),
  // Dato libre
  texto('TEXTO'),
  textoArea('TEXTO_AREA'),
  numero('NUMERO'),
  moneda('MONEDA'),
  boolean('BOOLEAN'),
  fecha('FECHA'),
  hora('HORA'),
  email('EMAIL'),
  telefono('TELEFONO'),
  url('URL'),
  // Códigos e identificación
  codigoBarras('CODIGO_BARRAS'),
  pinClave('PIN_CLAVE'),
  patronDesbloqueo('PATRON_DESBLOQUEO'),
  documentoIdentidad('DOCUMENTO_IDENTIDAD'),
  placaVehiculo('PLACA_VEHICULO'),
  licenciaConducir('LICENCIA_CONDUCIR'),
  // Archivos: el valor guardado es la URL del storage
  foto('FOTO'),
  firma('FIRMA'),
  archivo('ARCHIVO'),
  // Otros
  inspeccionVisual('INSPECCION_VISUAL'),
  productoCatalogo('PRODUCTO_CATALOGO'),
  // Legacy: nombres de atributo disfrazados de tipo. Fuera del selector, se
  // comportan como `select`. Cero filas los usan en beta y en prod.
  color('COLOR'),
  talla('TALLA'),
  material('MATERIAL'),
  capacidad('CAPACIDAD');

  final String value;
  const AtributoTipo(this.value);

  static AtributoTipo fromString(String value) {
    return AtributoTipo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AtributoTipo.texto,
    );
  }

  /// Se llena eligiendo de una lista. Son los únicos que EXIGEN `valores` y,
  /// por eso, los únicos que el generador de combinaciones puede usar como eje
  /// de variante — que filtra por `valores.isNotEmpty`, no por el tipo.
  bool get usaListaDeValores =>
      this == AtributoTipo.select ||
      this == AtributoTipo.multiSelect ||
      esLegacy;

  /// Los cuatro que quedaron del modelo viejo. Se siguen mostrando si una fila
  /// los trae, pero no se ofrecen al crear.
  bool get esLegacy =>
      this == AtributoTipo.color ||
      this == AtributoTipo.talla ||
      this == AtributoTipo.material ||
      this == AtributoTipo.capacidad;
}

/// Entity que representa un atributo configurable de producto
class ProductoAtributo extends Equatable {
  final String id;
  final String empresaId;
  final List<String> categoriaIds;
  final String nombre;
  final String clave;
  final AtributoTipo tipo;
  final bool requerido;
  final String? descripcion;
  final String? unidad;
  final List<String> valores;
  final int orden;
  final bool mostrarEnListado;
  final bool usarParaFiltros;
  final bool mostrarEnMarketplace;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const ProductoAtributo({
    required this.id,
    required this.empresaId,
    this.categoriaIds = const [],
    required this.nombre,
    required this.clave,
    required this.tipo,
    required this.requerido,
    this.descripcion,
    this.unidad,
    required this.valores,
    required this.orden,
    required this.mostrarEnListado,
    required this.usarParaFiltros,
    required this.mostrarEnMarketplace,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Crea un ProductoAtributo desde la información de una plantilla.
  /// Usado para renderizar AtributoInputWidget con datos de plantilla.
  factory ProductoAtributo.fromPlantillaInfo({
    required String atributoId,
    required String nombre,
    required String clave,
    required AtributoTipo tipo,
    required bool requerido,
    String? descripcion,
    String? unidad,
    required List<String> valores,
    required int orden,
    String empresaId = '',
  }) {
    return ProductoAtributo(
      id: atributoId,
      empresaId: empresaId,
      categoriaIds: const [],
      nombre: nombre,
      clave: clave,
      tipo: tipo,
      requerido: requerido,
      descripcion: descripcion,
      unidad: unidad,
      valores: valores,
      orden: orden,
      mostrarEnListado: true,
      usarParaFiltros: true,
      mostrarEnMarketplace: true,
      isActive: true,
      creadoEn: DateTime.timestamp(),
      actualizadoEn: DateTime.timestamp(),
    );
  }

  /// Verifica si tiene valores predefinidos
  bool get hasValores => valores.isNotEmpty;

  /// Verifica si es un atributo de selección múltiple
  bool get isMultiSelect => tipo == AtributoTipo.multiSelect;

  /// Verifica si es un atributo de color
  bool get isColor => tipo == AtributoTipo.color;

  /// Verifica si es un atributo de talla
  bool get isTalla => tipo == AtributoTipo.talla;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        categoriaIds,
        nombre,
        clave,
        tipo,
        requerido,
        descripcion,
        unidad,
        valores,
        orden,
        mostrarEnListado,
        usarParaFiltros,
        mostrarEnMarketplace,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}

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
  /// Sus opciones dependen del valor elegido en el atributo padre
  /// (`dependeDeAtributoId`): FABRICANTE → FAMILIA → PROCESADOR.
  selectDependiente('SELECT_DEPENDIENTE'),
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
      this == AtributoTipo.selectDependiente ||
      esLegacy;

  /// Sus opciones se filtran por lo elegido en el atributo padre.
  bool get dependeDeOtro => this == AtributoTipo.selectDependiente;

  /// Los cuatro que quedaron del modelo viejo. Se siguen mostrando si una fila
  /// los trae, pero no se ofrecen al crear.
  bool get esLegacy =>
      this == AtributoTipo.color ||
      this == AtributoTipo.talla ||
      this == AtributoTipo.material ||
      this == AtributoTipo.capacidad;
}

/// Una opción elegible de un atributo, y de qué opción del padre cuelga.
///
/// `padreValor` es el VALOR del padre, no su id: es lo que la pantalla tiene a
/// mano para filtrar. El id se usa del lado del backend, que es donde importa
/// que renombrar no huerfanice.
class OpcionAtributo extends Equatable {
  final String id;
  final String valor;
  final String? padreValor;
  final int orden;

  const OpcionAtributo({
    required this.id,
    required this.valor,
    this.padreValor,
    this.orden = 0,
  });

  @override
  List<Object?> get props => [id, valor, padreValor, orden];
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

  /// Lista PLANA de todos los valores. En un atributo dependiente están todos
  /// mezclados (los de Samsung y los de Qualcomm juntos): para mostrar solo la
  /// rama que corresponde hay que usar [opcionesPara].
  final List<String> valores;

  /// Las opciones con su jerarquía. Vacío en los tipos sin lista.
  final List<OpcionAtributo> opciones;

  /// Atributo del que dependen estas opciones. Null si es raíz.
  final String? dependeDeAtributoId;

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
    this.opciones = const [],
    this.dependeDeAtributoId,
    required this.orden,
    required this.mostrarEnListado,
    required this.usarParaFiltros,
    required this.mostrarEnMarketplace,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Las opciones que corresponden a [valorPadre].
  ///
  /// En un atributo raíz devuelve todas. En uno dependiente, solo las de esa
  /// rama; y si el padre todavía no tiene valor, ninguna — es lo que mantiene
  /// el desplegable bloqueado hasta que se elija arriba.
  ///
  /// 🔁 Respaldo: si el atributo es dependiente pero NO llegaron `opciones`
  /// (app vieja contra backend nuevo, o al revés), devuelve la lista plana en
  /// vez de dejar la pantalla vacía sin explicación.
  List<String> opcionesPara(String? valorPadre) {
    if (!tipo.dependeDeOtro) return valores;
    if (opciones.isEmpty) return valores;
    if (valorPadre == null || valorPadre.isEmpty) return const [];
    return opciones
        .where((o) => o.padreValor == valorPadre)
        .map((o) => o.valor)
        .toList(growable: false);
  }

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
    // 🔴 Sin estos dos, un atributo dependiente creado desde una plantilla
    // nace sin jerarquía: el desplegable queda bloqueado para siempre porque
    // nunca sabe de qué cuelga. Es lo que pasaba en el form de producto.
    List<OpcionAtributo> opciones = const [],
    String? dependeDeAtributoId,
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
      opciones: opciones,
      dependeDeAtributoId: dependeDeAtributoId,
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
        opciones,
        dependeDeAtributoId,
        orden,
        mostrarEnListado,
        usarParaFiltros,
        mostrarEnMarketplace,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}

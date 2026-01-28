import 'package:equatable/equatable.dart';

/// Tipos de incidencias que pueden ocurrir al recibir una transferencia
enum TipoIncidenciaTransferencia {
  faltante('FALTANTE', 'Faltante'),
  danado('DANADO', 'Dañado'),
  calidadRechazada('CALIDAD_RECHAZADA', 'Calidad Rechazada'),
  excedente('EXCEDENTE', 'Excedente'),
  empaqueDanado('EMPAQUE_DANADO', 'Empaque Dañado'),
  productoIncorrecto('PRODUCTO_INCORRECTO', 'Producto Incorrecto');

  const TipoIncidenciaTransferencia(this.value, this.displayName);
  final String value;
  final String displayName;

  String get descripcion => displayName;

  static TipoIncidenciaTransferencia fromString(String value) {
    return TipoIncidenciaTransferencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoIncidenciaTransferencia.danado,
    );
  }
}

/// Acciones que se pueden tomar para resolver una incidencia
enum AccionResolucionIncidencia {
  devolverOrigen('DEVOLVER_ORIGEN', 'Devolver al Origen'),
  darDeBaja('DAR_DE_BAJA', 'Dar de Baja'),
  reparar('REPARAR', 'Enviar a Reparación'),
  aceptarConDescuento('ACEPTAR_CON_DESCUENTO', 'Aceptar con Descuento'),
  reclamarProveedor('RECLAMAR_PROVEEDOR', 'Reclamar a Proveedor');

  const AccionResolucionIncidencia(this.value, this.displayName);
  final String value;
  final String displayName;

  String get descripcion => displayName;

  static AccionResolucionIncidencia fromString(String value) {
    return AccionResolucionIncidencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AccionResolucionIncidencia.reclamarProveedor,
    );
  }
}

/// Entidad que representa una incidencia reportada en una transferencia
class TransferenciaIncidencia extends Equatable {
  final String id;
  final String empresaId;
  final String transferenciaId;
  final String transferenciaItemId;
  final TipoIncidenciaTransferencia tipo;
  final int cantidadAfectada;
  final String? descripcion;
  final List<String> evidenciasUrls;
  final String? observaciones;
  final bool resuelto;
  final DateTime? fechaResolucion;
  final AccionResolucionIncidencia? accionTomada;
  final String? documentoRelacionado;
  final String reportadoPor;
  final String? resueltoPor;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones opcionales (pueden venir del API)
  final TransferenciaIncidenciaInfo? transferencia;
  final ItemIncidenciaInfo? item;
  final UsuarioInfo? reportadoPorUsuario;
  final UsuarioInfo? resueltoPorUsuario;

  const TransferenciaIncidencia({
    required this.id,
    required this.empresaId,
    required this.transferenciaId,
    required this.transferenciaItemId,
    required this.tipo,
    required this.cantidadAfectada,
    this.descripcion,
    this.evidenciasUrls = const [],
    this.observaciones,
    required this.resuelto,
    this.fechaResolucion,
    this.accionTomada,
    this.documentoRelacionado,
    required this.reportadoPor,
    this.resueltoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.transferencia,
    this.item,
    this.reportadoPorUsuario,
    this.resueltoPorUsuario,
  });

  /// Retorna el nombre descriptivo del tipo de incidencia
  String get tipoDisplayName => tipo.displayName;

  /// Retorna el nombre de la acción tomada
  String? get accionDisplayName => accionTomada?.displayName;

  /// Indica si la incidencia está pendiente de resolución
  bool get estaPendiente => !resuelto;

  /// Indica si tiene evidencias adjuntas
  bool get tieneEvidencias => evidenciasUrls.isNotEmpty;

  /// Cantidad de archivos de evidencia
  int get cantidadEvidencias => evidenciasUrls.length;

  /// Indica si la incidencia es de tipo que afecta el stock físico
  bool get afectaStockFisico =>
      tipo == TipoIncidenciaTransferencia.faltante ||
      tipo == TipoIncidenciaTransferencia.danado ||
      tipo == TipoIncidenciaTransferencia.calidadRechazada;

  /// Nombre del producto afectado (si está disponible)
  String? get nombreProducto =>
      item?.producto?.nombre ?? item?.variante?.nombre;

  /// Código del producto afectado
  String? get codigoProducto =>
      item?.producto?.codigoEmpresa ?? item?.variante?.codigoEmpresa;

  /// SKU del producto afectado
  String? get skuProducto => item?.producto?.sku ?? item?.variante?.sku;

  /// Nombre completo del usuario que reportó
  String? get nombreReportadoPor {
    if (reportadoPorUsuario?.persona != null) {
      final p = reportadoPorUsuario!.persona!;
      return '${p.nombres} ${p.apellidos}';
    }
    return null;
  }

  /// Nombre completo del usuario que resolvió
  String? get nombreResueltoPor {
    if (resueltoPorUsuario?.persona != null) {
      final p = resueltoPorUsuario!.persona!;
      return '${p.nombres} ${p.apellidos}';
    }
    return null;
  }

  /// Días transcurridos desde que se creó la incidencia
  int get diasDesdeCreacion => DateTime.now().difference(creadoEn).inDays;

  /// Mensaje de resumen de la incidencia para mostrar en listas
  String get resumen {
    final producto = nombreProducto ?? 'Producto';
    final cantidad = cantidadAfectada;
    return '$tipo.displayName: $cantidad unidades de $producto';
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        transferenciaId,
        transferenciaItemId,
        tipo,
        cantidadAfectada,
        descripcion,
        evidenciasUrls,
        observaciones,
        resuelto,
        fechaResolucion,
        accionTomada,
        documentoRelacionado,
        reportadoPor,
        resueltoPor,
        creadoEn,
        actualizadoEn,
      ];

  @override
  String toString() => 'TransferenciaIncidencia('
      'id: $id, '
      'tipo: ${tipo.value}, '
      'cantidadAfectada: $cantidadAfectada, '
      'resuelto: $resuelto)';
}

/// Información resumida de la transferencia (para relaciones)
class TransferenciaIncidenciaInfo extends Equatable {
  final String id;
  final String codigo;
  final SedeInfo? sedeOrigen;
  final SedeInfo? sedeDestino;

  const TransferenciaIncidenciaInfo({
    required this.id,
    required this.codigo,
    this.sedeOrigen,
    this.sedeDestino,
  });

  @override
  List<Object?> get props => [id, codigo, sedeOrigen, sedeDestino];
}

/// Información resumida de la sede
class SedeInfo extends Equatable {
  final String id;
  final String nombre;
  final String codigo;

  const SedeInfo({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}

/// Información del item afectado
class ItemIncidenciaInfo extends Equatable {
  final ProductoInfoBasico? producto;
  final ProductoInfoBasico? variante;

  const ItemIncidenciaInfo({
    this.producto,
    this.variante,
  });

  @override
  List<Object?> get props => [producto, variante];
}

/// Información básica del producto
class ProductoInfoBasico extends Equatable {
  final String id;
  final String nombre;
  final String? codigoEmpresa;
  final String? sku;

  const ProductoInfoBasico({
    required this.id,
    required this.nombre,
    this.codigoEmpresa,
    this.sku,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa, sku];
}

/// Información del usuario
class UsuarioInfo extends Equatable {
  final String id;
  final PersonaInfo? persona;

  const UsuarioInfo({
    required this.id,
    this.persona,
  });

  @override
  List<Object?> get props => [id, persona];
}

/// Información de la persona
class PersonaInfo extends Equatable {
  final String nombres;
  final String apellidos;

  const PersonaInfo({
    required this.nombres,
    required this.apellidos,
  });

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [nombres, apellidos];
}

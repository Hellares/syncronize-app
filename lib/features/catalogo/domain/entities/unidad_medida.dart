import 'package:equatable/equatable.dart';

/// Categorías de unidades de medida SUNAT
enum CategoriaUnidad {
  cantidad('CANTIDAD', 'Cantidad'),
  masa('MASA', 'Masa'),
  longitud('LONGITUD', 'Longitud'),
  area('AREA', 'Área'),
  volumen('VOLUMEN', 'Volumen'),
  tiempo('TIEMPO', 'Tiempo'),
  servicio('SERVICIO', 'Servicio');

  final String value;
  final String label;

  const CategoriaUnidad(this.value, this.label);

  static CategoriaUnidad fromString(String value) {
    return CategoriaUnidad.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoriaUnidad.cantidad,
    );
  }
}

/// Unidad de medida maestra (catálogo SUNAT)
class UnidadMedidaMaestra extends Equatable {
  final String id;
  final String codigo; // "NIU", "KGM", "MTR", "LTR", "ZZ"
  final String nombre; // "Unidad", "Kilogramo", "Metro", "Litro"
  final String? simbolo; // "und", "kg", "m", "L"
  final String? descripcion;
  final CategoriaUnidad categoria;
  final bool esPopular;
  final int? orden;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const UnidadMedidaMaestra({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.simbolo,
    this.descripcion,
    required this.categoria,
    this.esPopular = false,
    this.orden,
    this.isActive = true,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Display para UI - usa símbolo si está disponible, sino nombre
  String get displayCorto => simbolo ?? nombre;

  /// Display completo para listas
  String get displayCompleto => simbolo != null ? '$nombre ($simbolo)' : nombre;

  /// Display con código SUNAT
  String get displayConCodigo => '$codigo - $nombre${simbolo != null ? " ($simbolo)" : ""}';

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        simbolo,
        descripcion,
        categoria,
        esPopular,
        orden,
        isActive,
        creadoEn,
        actualizadoEn,
      ];

  factory UnidadMedidaMaestra.fromJson(Map<String, dynamic> json) {
    return UnidadMedidaMaestra(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      simbolo: json['simbolo'] as String?,
      descripcion: json['descripcion'] as String?,
      categoria: CategoriaUnidad.fromString(json['categoria'] as String),
      esPopular: json['esPopular'] as bool? ?? false,
      orden: json['orden'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'simbolo': simbolo,
      'descripcion': descripcion,
      'categoria': categoria.value,
      'esPopular': esPopular,
      'orden': orden,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }
}

/// Unidad de medida activada por empresa (con personalización)
class EmpresaUnidadMedida extends Equatable {
  final String id;
  final String empresaId;
  final String? unidadMaestraId;

  // Campos personalizados (solo si unidadMaestraId es null)
  final String? nombrePersonalizado;
  final String? simboloPersonalizado;
  final String? codigoPersonalizado;
  final String? descripcion;

  // Personalización (override del maestro)
  final String? nombreLocal;
  final String? simboloLocal;

  // Configuración
  final int? orden;
  final bool isVisible;
  final bool isActive;
  final DateTime? deletedAt;

  // Auditoría
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Datos maestros incluidos (cuando viene de servidor)
  final UnidadMedidaMaestra? unidadMaestra;

  const EmpresaUnidadMedida({
    required this.id,
    required this.empresaId,
    this.unidadMaestraId,
    this.nombrePersonalizado,
    this.simboloPersonalizado,
    this.codigoPersonalizado,
    this.descripcion,
    this.nombreLocal,
    this.simboloLocal,
    this.orden,
    this.isVisible = true,
    this.isActive = true,
    this.deletedAt,
    required this.creadoEn,
    required this.actualizadoEn,
    this.unidadMaestra,
  });

  /// Nombre efectivo - usa personalizado, local, o maestro
  String get nombreEfectivo {
    if (nombrePersonalizado != null) return nombrePersonalizado!;
    if (nombreLocal != null) return nombreLocal!;
    if (unidadMaestra != null) return unidadMaestra!.nombre;
    return 'Sin nombre';
  }

  /// Símbolo efectivo - usa personalizado, local, o maestro
  String? get simboloEfectivo {
    if (simboloPersonalizado != null) return simboloPersonalizado;
    if (simboloLocal != null) return simboloLocal;
    if (unidadMaestra != null) return unidadMaestra!.simbolo;
    return null;
  }

  /// Código efectivo - usa personalizado o maestro
  String? get codigoEfectivo {
    if (codigoPersonalizado != null) return codigoPersonalizado;
    if (unidadMaestra != null) return unidadMaestra!.codigo;
    return null;
  }

  /// Display corto para UI (prioriza símbolo)
  String get displayCorto => simboloEfectivo ?? nombreEfectivo;

  /// Display completo
  String get displayCompleto =>
      simboloEfectivo != null ? '$nombreEfectivo ($simboloEfectivo)' : nombreEfectivo;

  /// Display con código SUNAT (si existe)
  String get displayConCodigo {
    final codigo = codigoEfectivo;
    final simbolo = simboloEfectivo;
    if (codigo != null) {
      return simbolo != null
          ? '$codigo - $nombreEfectivo ($simbolo)'
          : '$codigo - $nombreEfectivo';
    }
    return displayCompleto;
  }

  /// Es unidad personalizada (no viene del catálogo maestro)
  bool get esPersonalizada => unidadMaestraId == null;

  /// Categoría de la unidad (solo si tiene unidad maestra)
  CategoriaUnidad? get categoria => unidadMaestra?.categoria;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        unidadMaestraId,
        nombrePersonalizado,
        simboloPersonalizado,
        codigoPersonalizado,
        descripcion,
        nombreLocal,
        simboloLocal,
        orden,
        isVisible,
        isActive,
        deletedAt,
        creadoEn,
        actualizadoEn,
        unidadMaestra,
      ];

  factory EmpresaUnidadMedida.fromJson(Map<String, dynamic> json) {
    return EmpresaUnidadMedida(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      unidadMaestraId: json['unidadMaestraId'] as String?,
      nombrePersonalizado: json['nombrePersonalizado'] as String?,
      simboloPersonalizado: json['simboloPersonalizado'] as String?,
      codigoPersonalizado: json['codigoPersonalizado'] as String?,
      descripcion: json['descripcion'] as String?,
      nombreLocal: json['nombreLocal'] as String?,
      simboloLocal: json['simboloLocal'] as String?,
      orden: json['orden'] as int?,
      isVisible: json['isVisible'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      unidadMaestra: json['unidadMaestra'] != null
          ? UnidadMedidaMaestra.fromJson(json['unidadMaestra'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'unidadMaestraId': unidadMaestraId,
      'nombrePersonalizado': nombrePersonalizado,
      'simboloPersonalizado': simboloPersonalizado,
      'codigoPersonalizado': codigoPersonalizado,
      'descripcion': descripcion,
      'nombreLocal': nombreLocal,
      'simboloLocal': simboloLocal,
      'orden': orden,
      'isVisible': isVisible,
      'isActive': isActive,
      'deletedAt': deletedAt?.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
      'unidadMaestra': unidadMaestra?.toJson(),
    };
  }
}

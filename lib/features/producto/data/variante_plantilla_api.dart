import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/dio_client.dart';

/// Plantillas de VARIANTES ("Edredones", "Peluches"): la estructura de una
/// colección guardada para crear otra igual. No confundir con las plantillas
/// de atributos (la ficha técnica del producto).

class ValorPlantilla {
  final String atributoId;
  final String valor;
  const ValorPlantilla(this.atributoId, this.valor);

  factory ValorPlantilla.fromJson(Map<String, dynamic> j) =>
      ValorPlantilla(j['atributoId'] as String, j['valor'] as String);
  Map<String, dynamic> toJson() => {'atributoId': atributoId, 'valor': valor};
}

class CombinacionPlantilla {
  final String? id;
  final List<ValorPlantilla> valores;
  final double? precio;
  final double? precioCosto;

  /// Precios por mayor sugeridos, tal cual los guarda el backend.
  final List<Map<String, dynamic>> niveles;

  const CombinacionPlantilla({
    this.id,
    required this.valores,
    this.precio,
    this.precioCosto,
    this.niveles = const [],
  });

  factory CombinacionPlantilla.fromJson(Map<String, dynamic> j) => CombinacionPlantilla(
        id: j['id'] as String?,
        valores: [
          for (final v in (j['valores'] as List? ?? const []))
            ValorPlantilla.fromJson(v as Map<String, dynamic>),
        ],
        precio: (j['precio'] as num?)?.toDouble(),
        precioCosto: (j['precioCosto'] as num?)?.toDouble(),
        niveles: [
          for (final n in (j['niveles'] as List? ?? const [])) Map<String, dynamic>.from(n as Map),
        ],
      );

  Map<String, dynamic> toJson() => {
        'valores': valores.map((v) => v.toJson()).toList(),
        if (precio != null) 'precio': precio,
        if (precioCosto != null) 'precioCosto': precioCosto,
        if (niveles.isNotEmpty) 'niveles': niveles,
      };

  /// "2 PLAZAS · TELA · 3 PZS".
  String get etiqueta => valores.map((v) => v.valor).join(' · ');
}

class AtributoDePlantilla {
  final String id;
  final String nombre;
  final bool activo;
  const AtributoDePlantilla(this.id, this.nombre, this.activo);

  factory AtributoDePlantilla.fromJson(Map<String, dynamic> j) => AtributoDePlantilla(
        j['id'] as String,
        (j['nombre'] as String?) ?? '',
        j['activo'] != false,
      );
}

class VariantePlantilla {
  final String id;
  final String nombre;
  final String? descripcion;
  final AtributoDePlantilla atributoColeccion;
  final List<AtributoDePlantilla> atributos;
  final List<CombinacionPlantilla> combinaciones;

  const VariantePlantilla({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.atributoColeccion,
    required this.atributos,
    required this.combinaciones,
  });

  factory VariantePlantilla.fromJson(Map<String, dynamic> j) => VariantePlantilla(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        atributoColeccion:
            AtributoDePlantilla.fromJson(j['atributoColeccion'] as Map<String, dynamic>),
        atributos: [
          for (final a in (j['atributos'] as List? ?? const []))
            AtributoDePlantilla.fromJson(a as Map<String, dynamic>),
        ],
        combinaciones: [
          for (final c in (j['combinaciones'] as List? ?? const []))
            CombinacionPlantilla.fromJson(c as Map<String, dynamic>),
        ],
      );
}

/// Resultado de aplicar una plantilla.
class ResultadoAplicar {
  final List<String> creadas;
  final List<String> omitidas;
  const ResultadoAplicar(this.creadas, this.omitidas);
}

/// Llamadas a `/variante-plantillas`.
class VariantePlantillaApi {
  DioClient get _dio => locator<DioClient>();
  static const _base = ApiConstants.variantePlantillas;

  Future<List<VariantePlantilla>> listar() async {
    final r = await _dio.get(_base);
    return [
      for (final p in (r.data as List)) VariantePlantilla.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<VariantePlantilla> guardar({
    String? id,
    required String nombre,
    String? descripcion,
    required String atributoColeccionId,
    required List<String> atributoIds,
    required List<CombinacionPlantilla> combinaciones,
  }) async {
    final body = {
      'nombre': nombre,
      if (descripcion != null && descripcion.trim().isNotEmpty) 'descripcion': descripcion.trim(),
      'atributoColeccionId': atributoColeccionId,
      'atributoIds': atributoIds,
      'combinaciones': combinaciones.map((c) => c.toJson()).toList(),
    };
    final r = id == null ? await _dio.post(_base, data: body) : await _dio.put('$_base/$id', data: body);
    return VariantePlantilla.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) => _dio.delete('$_base/$id');

  Future<VariantePlantilla> desdeColeccion({
    required String nombre,
    required String productoId,
    required String atributoColeccionId,
    required String valorColeccion,
  }) async {
    final r = await _dio.post('$_base/desde-coleccion', data: {
      'nombre': nombre,
      'productoId': productoId,
      'atributoColeccionId': atributoColeccionId,
      'valorColeccion': valorColeccion,
    });
    return VariantePlantilla.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ResultadoAplicar> aplicar({
    required String plantillaId,
    required String productoId,
    required String valorColeccion,
    required List<({String combinacionId, double? precio, double? precioCosto})> combinaciones,
  }) async {
    final r = await _dio.post('$_base/$plantillaId/aplicar', data: {
      'productoId': productoId,
      'valorColeccion': valorColeccion,
      'combinaciones': [
        for (final c in combinaciones)
          {
            'combinacionId': c.combinacionId,
            if (c.precio != null) 'precio': c.precio,
            if (c.precioCosto != null) 'precioCosto': c.precioCosto,
          },
      ],
    });
    final data = r.data as Map<String, dynamic>;
    return ResultadoAplicar(
      [for (final c in (data['creadas'] as List? ?? const [])) (c as Map)['nombre'] as String],
      [for (final o in (data['omitidas'] as List? ?? const [])) o as String],
    );
  }
}

/// El mensaje del backend, o uno por defecto.
String mensajeDeError(Object e, String porDefecto) {
  if (e is DioException) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? porDefecto;
  }
  return e.toString();
}

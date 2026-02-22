import '../../domain/entities/plantilla_documento.dart';

class PlantillaDocumentoModel extends PlantillaDocumento {
  const PlantillaDocumentoModel({
    required super.id,
    required super.empresaId,
    required super.tipoDocumento,
    super.formatoPapel,
    required super.nombre,
    super.margenSuperior,
    super.margenInferior,
    super.margenIzquierdo,
    super.margenDerecho,
    super.mostrarLogo,
    super.mostrarDatosEmpresa,
    super.mostrarDatosCliente,
    super.mostrarDetalles,
    super.mostrarTotales,
    super.mostrarObservaciones,
    super.mostrarCondiciones,
    super.mostrarFirma,
    super.mostrarCodigoQR,
    super.mostrarPiePagina,
    super.colorEncabezado,
    super.colorCuerpo,
  });

  factory PlantillaDocumentoModel.fromJson(Map<String, dynamic> json) {
    return PlantillaDocumentoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      tipoDocumento:
          TipoDocumento.fromString(json['tipoDocumento'] as String),
      formatoPapel:
          FormatoPapel.fromString((json['formatoPapel'] as String?) ?? 'A4'),
      nombre: json['nombre'] as String,
      margenSuperior: _toDouble(json['margenSuperior']),
      margenInferior: _toDouble(json['margenInferior']),
      margenIzquierdo: _toDouble(json['margenIzquierdo']),
      margenDerecho: _toDouble(json['margenDerecho']),
      mostrarLogo: (json['mostrarLogo'] as bool?) ?? true,
      mostrarDatosEmpresa: (json['mostrarDatosEmpresa'] as bool?) ?? true,
      mostrarDatosCliente: (json['mostrarDatosCliente'] as bool?) ?? true,
      mostrarDetalles: (json['mostrarDetalles'] as bool?) ?? true,
      mostrarTotales: (json['mostrarTotales'] as bool?) ?? true,
      mostrarObservaciones: (json['mostrarObservaciones'] as bool?) ?? true,
      mostrarCondiciones: (json['mostrarCondiciones'] as bool?) ?? true,
      mostrarFirma: (json['mostrarFirma'] as bool?) ?? true,
      mostrarCodigoQR: (json['mostrarCodigoQR'] as bool?) ?? false,
      mostrarPiePagina: (json['mostrarPiePagina'] as bool?) ?? true,
      colorEncabezado: json['colorEncabezado'] as String?,
      colorCuerpo: json['colorCuerpo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'tipoDocumento': tipoDocumento.apiValue,
      'formatoPapel': formatoPapel.apiValue,
      'nombre': nombre,
      'margenSuperior': margenSuperior,
      'margenInferior': margenInferior,
      'margenIzquierdo': margenIzquierdo,
      'margenDerecho': margenDerecho,
      'mostrarLogo': mostrarLogo,
      'mostrarDatosEmpresa': mostrarDatosEmpresa,
      'mostrarDatosCliente': mostrarDatosCliente,
      'mostrarDetalles': mostrarDetalles,
      'mostrarTotales': mostrarTotales,
      'mostrarObservaciones': mostrarObservaciones,
      'mostrarCondiciones': mostrarCondiciones,
      'mostrarFirma': mostrarFirma,
      'mostrarCodigoQR': mostrarCodigoQR,
      'mostrarPiePagina': mostrarPiePagina,
      if (colorEncabezado != null) 'colorEncabezado': colorEncabezado,
      if (colorCuerpo != null) 'colorCuerpo': colorCuerpo,
    };
  }

  PlantillaDocumento toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 10.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 10.0;
    return 10.0;
  }
}

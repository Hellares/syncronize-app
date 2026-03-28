import 'package:equatable/equatable.dart';

class ArchivoEmpresa extends Equatable {
  final String id;
  final String url;
  final String? urlThumbnail;
  final String nombreOriginal;
  final String tipoArchivo;
  final String mimeType;
  final int tamanoBytes;
  final String? entidadTipo;
  final String? entidadId;
  final String? entidadNombre;
  final String? categoria;
  final int? ancho;
  final int? alto;
  final DateTime creadoEn;

  const ArchivoEmpresa({
    required this.id,
    required this.url,
    this.urlThumbnail,
    required this.nombreOriginal,
    required this.tipoArchivo,
    required this.mimeType,
    required this.tamanoBytes,
    this.entidadTipo,
    this.entidadId,
    this.entidadNombre,
    this.categoria,
    this.ancho,
    this.alto,
    required this.creadoEn,
  });

  bool get esImagen => tipoArchivo == 'IMAGEN';
  bool get esVideo => tipoArchivo == 'VIDEO';
  bool get esDocumento => !esImagen && !esVideo;

  String get tamanoFormateado {
    if (tamanoBytes >= 1024 * 1024) {
      return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(tamanoBytes / 1024).toStringAsFixed(0)} KB';
  }

  String get entidadLabel {
    if (entidadNombre != null && entidadNombre!.isNotEmpty) return entidadNombre!;
    if (entidadTipo == null) return nombreOriginal;
    final labels = {
      'PRODUCTO': 'Producto',
      'PRODUCTO_VARIANTE': 'Variante',
      'SERVICIO': 'Servicio',
      'EMPRESA': 'Empresa',
      'SEDE': 'Sede',
    };
    return labels[entidadTipo] ?? entidadTipo!;
  }

  String get tipoLabel {
    final labels = {
      'PRODUCTO': 'Producto',
      'PRODUCTO_VARIANTE': 'Variante',
      'SERVICIO': 'Servicio',
      'EMPRESA': 'Empresa',
      'IMAGEN': 'Imagen',
      'VIDEO': 'Video',
      'PDF': 'PDF',
    };
    return labels[entidadTipo] ?? labels[tipoArchivo] ?? tipoArchivo;
  }

  @override
  List<Object?> get props => [id];
}

class GaleriaStats extends Equatable {
  final int totalArchivos;
  final int usadoMB;
  final int? limiteMB;
  final String? plan;
  final List<TipoStats> porTipo;

  const GaleriaStats({
    required this.totalArchivos,
    required this.usadoMB,
    this.limiteMB,
    this.plan,
    required this.porTipo,
  });

  @override
  List<Object?> get props => [totalArchivos, usadoMB, limiteMB];
}

class TipoStats extends Equatable {
  final String tipo;
  final int cantidad;
  final int mb;

  const TipoStats({required this.tipo, required this.cantidad, required this.mb});

  @override
  List<Object?> get props => [tipo, cantidad, mb];
}

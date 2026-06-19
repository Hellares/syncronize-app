/// Resultado de consultar una Guía de Remisión (GRE) en SUNAT (vía backend →
/// Factiliza). Forma limpia ya mapeada por el backend.
class GuiaRemisionConsulta {
  final String? serie;
  final int? numero;
  final String tipoDesc;
  final DateTime? fechaEmision;
  final String? emisorRuc;
  final String? emisorNombre;
  final String? receptorDoc;
  final String? receptorNombre;
  final String? remitenteNombre;
  final String? motivoCod;
  final String? motivoDesc;
  final DateTime? fechaInicio;
  final double? pesoBruto;
  final String? modalidad;
  final List<GuiaBien> bienes;
  final String? origenDireccion;
  final String? destinoDireccion;
  final String? vehiculoPlaca;
  final String? conductorNombre;
  final String? conductorDoc;
  final String? conductorLicencia;

  const GuiaRemisionConsulta({
    this.serie,
    this.numero,
    this.tipoDesc = 'Guía de remisión',
    this.fechaEmision,
    this.emisorRuc,
    this.emisorNombre,
    this.receptorDoc,
    this.receptorNombre,
    this.remitenteNombre,
    this.motivoCod,
    this.motivoDesc,
    this.fechaInicio,
    this.pesoBruto,
    this.modalidad,
    this.bienes = const [],
    this.origenDireccion,
    this.destinoDireccion,
    this.vehiculoPlaca,
    this.conductorNombre,
    this.conductorDoc,
    this.conductorLicencia,
  });

  String get numeroCompleto =>
      '${serie ?? ''}-${numero ?? ''}';

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory GuiaRemisionConsulta.fromJson(Map<String, dynamic> j) {
    final em = j['emisor'] as Map<String, dynamic>?;
    final re = j['receptor'] as Map<String, dynamic>?;
    final rm = j['remitente'] as Map<String, dynamic>?;
    final t = j['traslado'] as Map<String, dynamic>?;
    final ori = j['origen'] as Map<String, dynamic>?;
    final des = j['destino'] as Map<String, dynamic>?;
    final veh = j['vehiculo'] as Map<String, dynamic>?;
    final con = j['conductor'] as Map<String, dynamic>?;
    return GuiaRemisionConsulta(
      serie: j['serie'] as String?,
      numero: (j['numero'] as num?)?.toInt(),
      tipoDesc: (j['tipoDesc'] as String?)?.trim().isNotEmpty == true
          ? j['tipoDesc'] as String
          : 'Guía de remisión',
      fechaEmision: _date(j['fechaEmision']),
      emisorRuc: em?['ruc'] as String?,
      emisorNombre: em?['nombre'] as String?,
      receptorDoc: re?['doc'] as String?,
      receptorNombre: re?['nombre'] as String?,
      remitenteNombre: rm?['nombre'] as String?,
      motivoCod: t?['motivoCod'] as String?,
      motivoDesc: t?['motivoDesc'] as String?,
      fechaInicio: _date(t?['fechaInicio']),
      pesoBruto: _dbl(t?['pesoBruto']),
      modalidad: t?['modalidad'] as String?,
      bienes: (j['bienes'] as List<dynamic>? ?? [])
          .map((e) => GuiaBien.fromJson(e as Map<String, dynamic>))
          .toList(),
      origenDireccion: ori?['direccion'] as String?,
      destinoDireccion: des?['direccion'] as String?,
      vehiculoPlaca: veh?['placa'] as String?,
      conductorNombre: con?['nombre'] as String?,
      conductorDoc: con?['doc'] as String?,
      conductorLicencia: con?['licencia'] as String?,
    );
  }
}

class GuiaBien {
  final String? descripcion;
  final double? cantidad;
  final String? unidad;

  const GuiaBien({this.descripcion, this.cantidad, this.unidad});

  factory GuiaBien.fromJson(Map<String, dynamic> j) => GuiaBien(
        descripcion: j['descripcion'] as String?,
        cantidad: GuiaRemisionConsulta._dbl(j['cantidad']),
        unidad: j['unidad'] as String?,
      );
}

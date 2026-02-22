import '../../domain/entities/combo_config_historial.dart';

class ComboConfigHistorialModel extends ComboConfigHistorialEntry {
  const ComboConfigHistorialModel({
    required super.id,
    required super.comboId,
    required super.tipoCambio,
    super.valorAnterior,
    required super.valorNuevo,
    super.razon,
    super.sedeId,
    required super.usuarioNombre,
    required super.creadoEn,
  });

  factory ComboConfigHistorialModel.fromJson(Map<String, dynamic> json) {
    // Extract usuario nombre
    String usuarioNombre = 'Usuario';
    final usuario = json['usuario'] as Map<String, dynamic>?;
    if (usuario != null) {
      final persona = usuario['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        usuarioNombre = '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (usuarioNombre == 'Usuario' && usuario['email'] != null) {
        usuarioNombre = usuario['email'] as String;
      }
    }

    return ComboConfigHistorialModel(
      id: json['id'] as String,
      comboId: json['comboId'] as String,
      tipoCambio: json['tipoCambio'] as String,
      valorAnterior: json['valorAnterior'] != null
          ? Map<String, dynamic>.from(json['valorAnterior'] as Map)
          : null,
      valorNuevo: Map<String, dynamic>.from(json['valorNuevo'] as Map),
      razon: json['razon'] as String?,
      sedeId: json['sedeId'] as String?,
      usuarioNombre: usuarioNombre,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  ComboConfigHistorialEntry toEntity() {
    return ComboConfigHistorialEntry(
      id: id,
      comboId: comboId,
      tipoCambio: tipoCambio,
      valorAnterior: valorAnterior,
      valorNuevo: valorNuevo,
      razon: razon,
      sedeId: sedeId,
      usuarioNombre: usuarioNombre,
      creadoEn: creadoEn,
    );
  }
}

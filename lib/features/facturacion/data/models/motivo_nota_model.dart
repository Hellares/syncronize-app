import '../../domain/entities/motivo_nota.dart';

class MotivoNotaModel extends MotivoNota {
  const MotivoNotaModel({
    required super.codigo,
    required super.codigoString,
    required super.descripcion,
  });

  factory MotivoNotaModel.fromJson(Map<String, dynamic> json) {
    return MotivoNotaModel(
      codigo: json['codigo'] as int,
      codigoString: json['codigoString'] as String,
      descripcion: json['descripcion'] as String,
    );
  }
}

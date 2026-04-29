import 'package:equatable/equatable.dart';

/// Motivo de nota según catálogo SUNAT (09 para NC, 10 para ND).
class MotivoNota extends Equatable {
  final int codigo;
  final String codigoString;
  final String descripcion;

  const MotivoNota({
    required this.codigo,
    required this.codigoString,
    required this.descripcion,
  });

  String get displayName => '$codigoString — $descripcion';

  @override
  List<Object?> get props => [codigo];
}

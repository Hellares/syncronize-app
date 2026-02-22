import 'package:equatable/equatable.dart';

class ComboConfigHistorialEntry extends Equatable {
  final String id;
  final String comboId;
  final String tipoCambio;
  final Map<String, dynamic>? valorAnterior;
  final Map<String, dynamic> valorNuevo;
  final String? razon;
  final String? sedeId;
  final String usuarioNombre;
  final DateTime creadoEn;

  const ComboConfigHistorialEntry({
    required this.id,
    required this.comboId,
    required this.tipoCambio,
    this.valorAnterior,
    required this.valorNuevo,
    this.razon,
    this.sedeId,
    required this.usuarioNombre,
    required this.creadoEn,
  });

  @override
  List<Object?> get props => [id, comboId, tipoCambio, valorAnterior, valorNuevo, razon, sedeId, usuarioNombre, creadoEn];
}

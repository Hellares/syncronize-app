import 'package:equatable/equatable.dart';

class ConfiguracionCampo extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String tipoCampo; // TipoCampoServicio enum as string
  final String? categoria; // CategoriaCampo enum as string
  final String? descripcion;
  final String? placeholder;
  final bool esRequerido;
  final String? defaultValue;
  final dynamic opciones; // JSON
  final bool permiteOtro;
  final bool isActive;
  final int? orden;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const ConfiguracionCampo({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.tipoCampo,
    this.categoria,
    this.descripcion,
    this.placeholder,
    this.esRequerido = false,
    this.defaultValue,
    this.opciones,
    this.permiteOtro = false,
    this.isActive = true,
    this.orden,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  @override
  List<Object?> get props => [id, nombre, tipoCampo, categoria, esRequerido, isActive, orden];
}

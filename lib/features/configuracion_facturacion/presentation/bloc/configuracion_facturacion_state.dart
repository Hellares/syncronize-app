import 'package:equatable/equatable.dart';
import '../../domain/entities/configuracion_facturacion.dart';

abstract class ConfiguracionFacturacionState extends Equatable {
  const ConfiguracionFacturacionState();

  @override
  List<Object?> get props => [];
}

class ConfiguracionFacturacionInitial extends ConfiguracionFacturacionState {
  const ConfiguracionFacturacionInitial();
}

class ConfiguracionFacturacionLoading extends ConfiguracionFacturacionState {
  const ConfiguracionFacturacionLoading();
}

class ConfiguracionFacturacionError extends ConfiguracionFacturacionState {
  final String mensaje;
  const ConfiguracionFacturacionError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

/// Estado principal: config cargada en memoria, con flags auxiliares de UI.
class ConfiguracionFacturacionLoaded extends ConfiguracionFacturacionState {
  final ConfiguracionFacturacion original; // estado guardado en servidor
  final ConfiguracionFacturacion editada;  // estado editado por el usuario
  final bool guardando;
  final bool probando;
  final ResultadoProbarConexion? resultadoPrueba;
  final String? mensajeExito;

  const ConfiguracionFacturacionLoaded({
    required this.original,
    required this.editada,
    this.guardando = false,
    this.probando = false,
    this.resultadoPrueba,
    this.mensajeExito,
  });

  bool get tieneCambios => original != editada;
  bool get cambioProveedor => original.proveedorActivo != editada.proveedorActivo;

  ConfiguracionFacturacionLoaded copyWith({
    ConfiguracionFacturacion? original,
    ConfiguracionFacturacion? editada,
    bool? guardando,
    bool? probando,
    ResultadoProbarConexion? resultadoPrueba,
    bool limpiarResultadoPrueba = false,
    String? mensajeExito,
    bool limpiarMensajeExito = false,
  }) {
    return ConfiguracionFacturacionLoaded(
      original: original ?? this.original,
      editada: editada ?? this.editada,
      guardando: guardando ?? this.guardando,
      probando: probando ?? this.probando,
      resultadoPrueba: limpiarResultadoPrueba
          ? null
          : (resultadoPrueba ?? this.resultadoPrueba),
      mensajeExito: limpiarMensajeExito
          ? null
          : (mensajeExito ?? this.mensajeExito),
    );
  }

  @override
  List<Object?> get props => [
        original,
        editada,
        guardando,
        probando,
        resultadoPrueba,
        mensajeExito,
      ];
}

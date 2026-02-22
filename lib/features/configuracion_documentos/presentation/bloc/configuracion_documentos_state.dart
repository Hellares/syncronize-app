import 'package:equatable/equatable.dart';
import '../../domain/entities/configuracion_documentos.dart';
import '../../domain/entities/plantilla_documento.dart';
import '../../domain/entities/configuracion_documento_completa.dart';

abstract class ConfiguracionDocumentosState extends Equatable {
  const ConfiguracionDocumentosState();

  @override
  List<Object?> get props => [];
}

class ConfiguracionDocumentosInitial extends ConfiguracionDocumentosState {
  const ConfiguracionDocumentosInitial();
}

class ConfiguracionDocumentosLoading extends ConfiguracionDocumentosState {
  const ConfiguracionDocumentosLoading();
}

class ConfiguracionDocumentosLoaded extends ConfiguracionDocumentosState {
  final ConfiguracionDocumentos configuracion;
  final List<PlantillaDocumento> plantillas;

  const ConfiguracionDocumentosLoaded({
    required this.configuracion,
    required this.plantillas,
  });

  @override
  List<Object?> get props => [configuracion, plantillas];
}

class ConfiguracionDocumentosCompletaLoaded
    extends ConfiguracionDocumentosState {
  final ConfiguracionDocumentoCompleta completa;

  const ConfiguracionDocumentosCompletaLoaded({required this.completa});

  @override
  List<Object?> get props => [completa];
}

class ConfiguracionDocumentosError extends ConfiguracionDocumentosState {
  final String message;

  const ConfiguracionDocumentosError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConfiguracionDocumentosUpdated extends ConfiguracionDocumentosState {
  final ConfiguracionDocumentos configuracion;

  const ConfiguracionDocumentosUpdated({required this.configuracion});

  @override
  List<Object?> get props => [configuracion];
}

class PlantillaDocumentoUpdated extends ConfiguracionDocumentosState {
  final PlantillaDocumento plantilla;

  const PlantillaDocumentoUpdated({required this.plantilla});

  @override
  List<Object?> get props => [plantilla];
}

class PlantillaCargada extends ConfiguracionDocumentosState {
  final PlantillaDocumento plantilla;

  const PlantillaCargada({required this.plantilla});

  @override
  List<Object?> get props => [plantilla];
}

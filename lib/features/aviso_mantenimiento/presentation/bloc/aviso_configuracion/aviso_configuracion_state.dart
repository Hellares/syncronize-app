import 'package:equatable/equatable.dart';
import '../../../domain/entities/aviso_mantenimiento.dart';

abstract class AvisoConfiguracionState extends Equatable {
  const AvisoConfiguracionState();
  @override
  List<Object?> get props => [];
}

class AvisoConfiguracionInitial extends AvisoConfiguracionState {
  const AvisoConfiguracionInitial();
}

class AvisoConfiguracionLoading extends AvisoConfiguracionState {
  const AvisoConfiguracionLoading();
}

class AvisoConfiguracionLoaded extends AvisoConfiguracionState {
  final ConfiguracionAvisoMantenimiento configuracion;

  const AvisoConfiguracionLoaded(this.configuracion);

  @override
  List<Object?> get props => [configuracion];
}

class AvisoConfiguracionSaving extends AvisoConfiguracionState {
  const AvisoConfiguracionSaving();
}

class AvisoConfiguracionSaved extends AvisoConfiguracionState {
  final ConfiguracionAvisoMantenimiento configuracion;

  const AvisoConfiguracionSaved(this.configuracion);

  @override
  List<Object?> get props => [configuracion];
}

class AvisoConfiguracionError extends AvisoConfiguracionState {
  final String message;
  const AvisoConfiguracionError(this.message);
  @override
  List<Object?> get props => [message];
}

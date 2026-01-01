import 'package:equatable/equatable.dart';

abstract class AjusteMasivoState extends Equatable {
  const AjusteMasivoState();

  @override
  List<Object?> get props => [];
}

class AjusteMasivoInitial extends AjusteMasivoState {
  const AjusteMasivoInitial();
}

class AjusteMasivoLoading extends AjusteMasivoState {
  const AjusteMasivoLoading();
}

class AjusteMasivoPreviewLoaded extends AjusteMasivoState {
  final Map<String, dynamic> previewData;

  const AjusteMasivoPreviewLoaded(this.previewData);

  @override
  List<Object?> get props => [previewData];
}

class AjusteMasivoSuccess extends AjusteMasivoState {
  final Map<String, dynamic> resultado;

  const AjusteMasivoSuccess(this.resultado);

  @override
  List<Object?> get props => [resultado];
}

class AjusteMasivoError extends AjusteMasivoState {
  final String message;
  final String? errorCode;

  const AjusteMasivoError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

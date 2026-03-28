import 'package:equatable/equatable.dart';
import '../../domain/entities/archivo_empresa.dart';

abstract class MultimediaState extends Equatable {
  const MultimediaState();
  @override
  List<Object?> get props => [];
}

class MultimediaInitial extends MultimediaState {}

class MultimediaLoading extends MultimediaState {}

class MultimediaLoaded extends MultimediaState {
  final List<ArchivoEmpresa> archivos;
  final GaleriaStats? stats;
  final int total;
  final int page;
  final int totalPages;
  final String? filtroTipo;
  final String orderBy;

  const MultimediaLoaded({
    required this.archivos,
    this.stats,
    required this.total,
    required this.page,
    required this.totalPages,
    this.filtroTipo,
    this.orderBy = 'recientes',
  });

  @override
  List<Object?> get props => [archivos, stats, total, page, filtroTipo, orderBy];
}

class MultimediaError extends MultimediaState {
  final String message;
  const MultimediaError(this.message);
  @override
  List<Object?> get props => [message];
}

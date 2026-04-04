import 'package:equatable/equatable.dart';
import '../../domain/entities/comprobante_item.dart';

abstract class MonitorFacturacionState extends Equatable {
  const MonitorFacturacionState();
  @override
  List<Object?> get props => [];
}

class MonitorFacturacionInitial extends MonitorFacturacionState {}

class MonitorFacturacionLoading extends MonitorFacturacionState {}

class MonitorFacturacionLoaded extends MonitorFacturacionState {
  final List<ComprobanteItem> comprobantes;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? filtroTipo;
  final String? filtroSunatStatus;

  const MonitorFacturacionLoaded({
    required this.comprobantes,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    this.filtroTipo,
    this.filtroSunatStatus,
  });

  int get totalAceptados => comprobantes.where((c) => c.esAceptado).length;
  int get totalPendientes => comprobantes.where((c) => c.esPendiente).length;
  int get totalRechazados => comprobantes.where((c) => c.esRechazado).length;

  @override
  List<Object?> get props => [comprobantes, total, currentPage, filtroTipo, filtroSunatStatus];
}

class MonitorFacturacionError extends MonitorFacturacionState {
  final String message;
  const MonitorFacturacionError(this.message);
  @override
  List<Object?> get props => [message];
}

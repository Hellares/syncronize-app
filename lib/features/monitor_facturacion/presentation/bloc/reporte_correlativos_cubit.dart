import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/serie_correlativo.dart';
import '../../domain/repositories/monitor_facturacion_repository.dart';

// ── State ──

abstract class ReporteCorrelativosState extends Equatable {
  const ReporteCorrelativosState();
  @override
  List<Object?> get props => [];
}

class ReporteCorrelativosInitial extends ReporteCorrelativosState {}

class ReporteCorrelativosLoading extends ReporteCorrelativosState {}

class ReporteCorrelativosLoaded extends ReporteCorrelativosState {
  final ReporteCorrelativos reporte;
  final String? filtroSedeId;

  const ReporteCorrelativosLoaded({required this.reporte, this.filtroSedeId});

  @override
  List<Object?> get props => [reporte, filtroSedeId];
}

class ReporteCorrelativosError extends ReporteCorrelativosState {
  final String message;
  const ReporteCorrelativosError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──

class ReporteCorrelativosCubit extends Cubit<ReporteCorrelativosState> {
  final MonitorFacturacionRepository _repository;
  String? _sedeId;
  String? _fechaDesde;
  String? _fechaHasta;

  ReporteCorrelativosCubit(this._repository) : super(ReporteCorrelativosInitial());

  String? get fechaDesde => _fechaDesde;
  String? get fechaHasta => _fechaHasta;

  Future<void> cargar() async {
    emit(ReporteCorrelativosLoading());
    final result = await _repository.reporteCorrelativos(
      sedeId: _sedeId,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
    );
    if (result is Success<ReporteCorrelativos>) {
      emit(ReporteCorrelativosLoaded(reporte: result.data, filtroSedeId: _sedeId));
    } else {
      emit(ReporteCorrelativosError((result as Error).message));
    }
  }

  void setSedeId(String? sedeId) {
    _sedeId = sedeId;
    cargar();
  }

  void setFechas(String? desde, String? hasta) {
    _fechaDesde = desde;
    _fechaHasta = hasta;
    cargar();
  }

  void limpiarFiltros() {
    _sedeId = null;
    _fechaDesde = null;
    _fechaHasta = null;
    cargar();
  }
}

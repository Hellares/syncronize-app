import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/sincronizacion_series.dart';
import '../../domain/usecases/aplicar_sincronizacion_usecase.dart';
import '../../domain/usecases/preview_sincronizacion_usecase.dart';

// ── State ──

abstract class SincronizarSeriesState extends Equatable {
  const SincronizarSeriesState();
  @override
  List<Object?> get props => [];
}

class SincronizarSeriesInitial extends SincronizarSeriesState {
  const SincronizarSeriesInitial();
}

class SincronizarSeriesLoadingPreview extends SincronizarSeriesState {
  const SincronizarSeriesLoadingPreview();
}

class SincronizarSeriesPreviewReady extends SincronizarSeriesState {
  final SincronizacionPreview preview;

  /// key: tipoDocumento → aplicar?
  final Map<String, bool> seleccionadas;

  /// branch elegido (por defecto el actual, o el primero)
  final dynamic branchIdProveedorElegido;

  const SincronizarSeriesPreviewReady({
    required this.preview,
    required this.seleccionadas,
    required this.branchIdProveedorElegido,
  });

  BranchPreviewInfo? get branchElegido {
    if (preview.branches.isEmpty) return null;
    return preview.branches.firstWhere(
      (b) => _eq(b.branchIdProveedor, branchIdProveedorElegido),
      orElse: () => preview.branches.first,
    );
  }

  int get cantidadSeleccionadas =>
      seleccionadas.values.where((v) => v).length;

  int get cantidadAplicables =>
      (branchElegido?.diffs ?? const [])
          .where((d) => d.accion.esAplicable)
          .length;

  bool get hayConflicto =>
      (branchElegido?.diffs ?? const []).any((d) => d.accion == AccionDiff.conflicto);

  SincronizarSeriesPreviewReady copyWith({
    Map<String, bool>? seleccionadas,
    dynamic branchIdProveedorElegido,
  }) {
    return SincronizarSeriesPreviewReady(
      preview: preview,
      seleccionadas: seleccionadas ?? this.seleccionadas,
      branchIdProveedorElegido:
          branchIdProveedorElegido ?? this.branchIdProveedorElegido,
    );
  }

  @override
  List<Object?> get props => [preview, seleccionadas, branchIdProveedorElegido];
}

class SincronizarSeriesApplying extends SincronizarSeriesState {
  const SincronizarSeriesApplying();
}

class SincronizarSeriesSuccess extends SincronizarSeriesState {
  final ResultadoSincronizacion resultado;
  const SincronizarSeriesSuccess(this.resultado);

  @override
  List<Object?> get props => [resultado];
}

class SincronizarSeriesError extends SincronizarSeriesState {
  final String mensaje;
  const SincronizarSeriesError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

bool _eq(dynamic a, dynamic b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.toString() == b.toString();
}

// ── Cubit ──

class SincronizarSeriesCubit extends Cubit<SincronizarSeriesState> {
  final PreviewSincronizacionUseCase _previewUseCase;
  final AplicarSincronizacionUseCase _aplicarUseCase;
  final String sedeId;

  SincronizarSeriesCubit(
    this._previewUseCase,
    this._aplicarUseCase, {
    required this.sedeId,
  }) : super(const SincronizarSeriesInitial());

  Future<void> cargarPreview() async {
    emit(const SincronizarSeriesLoadingPreview());
    final result = await _previewUseCase(sedeId);
    if (result is Success<SincronizacionPreview>) {
      final preview = result.data;
      if (preview.branches.isEmpty) {
        emit(const SincronizarSeriesError('El proveedor no devolvió series para esta sede.'));
        return;
      }
      final branchActual = preview.branches.firstWhere(
        (b) => b.esActualDeLaSede,
        orElse: () => preview.branches.first,
      );
      emit(SincronizarSeriesPreviewReady(
        preview: preview,
        seleccionadas: _seleccionInicial(branchActual),
        branchIdProveedorElegido: branchActual.branchIdProveedor,
      ));
    } else {
      emit(SincronizarSeriesError((result as Error).message));
    }
  }

  /// Key del map de selecciones. Usamos `tipoDocumentoNombre` porque
  /// `tipoDocumento` SUNAT no es único: NC (07) y ND (08) tienen 2 slots
  /// cada una (sobre Factura / sobre Boleta) que comparten tipoDocumento.
  Map<String, bool> _seleccionInicial(BranchPreviewInfo branch) {
    final map = <String, bool>{};
    for (final d in branch.diffs) {
      map[d.tipoDocumentoNombre] = d.accion.esAplicable;
    }
    return map;
  }

  void toggleSeleccion(String tipoDocumentoNombre) {
    final s = state;
    if (s is! SincronizarSeriesPreviewReady) return;
    final branch = s.branchElegido;
    if (branch == null) return;
    DiffSerie? diff;
    for (final d in branch.diffs) {
      if (d.tipoDocumentoNombre == tipoDocumentoNombre) { diff = d; break; }
    }
    if (diff == null || !diff.accion.esAplicable) return;
    final nuevo = Map<String, bool>.from(s.seleccionadas);
    nuevo[tipoDocumentoNombre] = !(nuevo[tipoDocumentoNombre] ?? false);
    emit(s.copyWith(seleccionadas: nuevo));
  }

  void toggleTodas(bool valor) {
    final s = state;
    if (s is! SincronizarSeriesPreviewReady) return;
    final nuevo = <String, bool>{};
    for (final d in s.branchElegido?.diffs ?? const <DiffSerie>[]) {
      nuevo[d.tipoDocumentoNombre] = valor && d.accion.esAplicable;
    }
    emit(s.copyWith(seleccionadas: nuevo));
  }

  void cambiarBranch(dynamic branchId) {
    final s = state;
    if (s is! SincronizarSeriesPreviewReady) return;
    final branch = s.preview.branches.firstWhere(
      (b) => _eq(b.branchIdProveedor, branchId),
      orElse: () => s.preview.branches.first,
    );
    emit(SincronizarSeriesPreviewReady(
      preview: s.preview,
      seleccionadas: _seleccionInicial(branch),
      branchIdProveedorElegido: branch.branchIdProveedor,
    ));
  }

  Future<void> aplicar() async {
    final s = state;
    if (s is! SincronizarSeriesPreviewReady) return;
    final branch = s.branchElegido;
    if (branch == null) return;

    final selecciones = branch.diffs
        .where((d) =>
            d.accion.esAplicable &&
            d.serieProveedor != null &&
            (s.seleccionadas[d.tipoDocumentoNombre] ?? false))
        .map((d) => SeleccionSerie(
              tipoDocumento: d.tipoDocumento,
              serieProveedor: d.serieProveedor!,
              correlativoProveedor: d.correlativoProveedor ?? 0,
              aplicar: true,
            ))
        .toList();

    if (selecciones.isEmpty) {
      emit(const SincronizarSeriesError('Debe seleccionar al menos una serie.'));
      // Volver al preview anterior
      emit(s);
      return;
    }

    emit(const SincronizarSeriesApplying());
    final result = await _aplicarUseCase(
      sedeId: sedeId,
      selecciones: selecciones,
      branchIdProveedor: branch.esActualDeLaSede ? null : branch.branchIdProveedor,
    );
    if (result is Success<ResultadoSincronizacion>) {
      emit(SincronizarSeriesSuccess(result.data));
    } else {
      emit(SincronizarSeriesError((result as Error).message));
      // tras error, volver al preview para que el usuario pueda reintentar
      emit(s);
    }
  }

  Future<void> reintentar() => cargarPreview();
}

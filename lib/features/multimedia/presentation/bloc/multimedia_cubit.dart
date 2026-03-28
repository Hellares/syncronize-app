import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/archivo_empresa.dart';
import '../../domain/repositories/multimedia_repository.dart';
import 'multimedia_state.dart';

class MultimediaCubit extends Cubit<MultimediaState> {
  final MultimediaRepository _repository;
  final String empresaId;

  MultimediaCubit({
    required MultimediaRepository repository,
    required this.empresaId,
  })  : _repository = repository,
        super(MultimediaInitial());

  String? _filtroTipo;
  String _orderBy = 'recientes';

  Future<void> loadArchivos({int page = 1}) async {
    if (page == 1) emit(MultimediaLoading());

    final results = await Future.wait([
      _repository.getArchivos(
        empresaId: empresaId,
        tipoArchivo: _filtroTipo,
        page: page,
        orderBy: _orderBy,
      ),
      if (page == 1) _repository.getStats(empresaId),
    ]);

    final archivosResult = results[0] as Resource<({List<ArchivoEmpresa> data, int total, int totalPages})>;

    GaleriaStats? stats;
    if (page == 1 && results.length > 1) {
      final statsResult = results[1] as Resource<GaleriaStats>;
      if (statsResult is Success<GaleriaStats>) {
        stats = statsResult.data;
      }
    }

    if (archivosResult is Success) {
      final data = (archivosResult as Success).data;
      final currentState = state;

      List<ArchivoEmpresa> allArchivos;
      if (page > 1 && currentState is MultimediaLoaded) {
        allArchivos = [...currentState.archivos, ...data.data];
        stats = currentState.stats;
      } else {
        allArchivos = data.data;
      }

      emit(MultimediaLoaded(
        archivos: allArchivos,
        stats: stats,
        total: data.total,
        page: page,
        totalPages: data.totalPages,
        filtroTipo: _filtroTipo,
        orderBy: _orderBy,
      ));
    } else if (archivosResult is Error) {
      emit(MultimediaError((archivosResult as Error).message));
    }
  }

  void cambiarFiltro(String? tipo) {
    _filtroTipo = tipo;
    loadArchivos();
  }

  void cambiarOrden(String orden) {
    _orderBy = orden;
    loadArchivos();
  }

  Future<void> deleteArchivo(String archivoId) async {
    final result = await _repository.deleteArchivo(archivoId, empresaId);
    if (result is Success) {
      // Recargar todo
      loadArchivos();
    }
  }
}

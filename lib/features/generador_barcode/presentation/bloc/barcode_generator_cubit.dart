import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/barcode_item.dart';
import '../../domain/usecases/get_productos_sin_barcode_usecase.dart';
import '../../domain/usecases/generar_codigos_usecase.dart';
import 'barcode_generator_state.dart';

@injectable
class BarcodeGeneratorCubit extends Cubit<BarcodeGeneratorState> {
  final GetProductosSinBarcodeUseCase _getProductosSinBarcodeUseCase;
  final GenerarCodigosUseCase _generarCodigosUseCase;

  String? _lastSedeId;

  BarcodeGeneratorCubit(
    this._getProductosSinBarcodeUseCase,
    this._generarCodigosUseCase,
  ) : super(const BarcodeGeneratorInitial());

  Future<void> loadProductosSinBarcode({String? sedeId}) async {
    _lastSedeId = sedeId;
    emit(const BarcodeGeneratorLoading());

    final result = await _getProductosSinBarcodeUseCase(sedeId: sedeId);
    if (isClosed) return;

    if (result is Success<List<BarcodeItem>>) {
      emit(BarcodeGeneratorLoaded(result.data));
    } else if (result is Error<List<BarcodeItem>>) {
      emit(BarcodeGeneratorError(result.message));
    }
  }

  Future<void> generarCodigos(List<String> productoIds, String formato) async {
    emit(const BarcodeGeneratorGenerating());

    final result = await _generarCodigosUseCase(
      productoIds: productoIds,
      formato: formato,
    );
    if (isClosed) return;

    if (result is Success<GenerarCodigosResult>) {
      emit(BarcodeGeneratorGenerated(result.data));
    } else if (result is Error<GenerarCodigosResult>) {
      emit(BarcodeGeneratorError(result.message));
    }
  }

  Future<void> reload() async {
    await loadProductosSinBarcode(sedeId: _lastSedeId);
  }
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/barcode_item.dart';

abstract class BarcodeGeneratorState extends Equatable {
  const BarcodeGeneratorState();
  @override
  List<Object?> get props => [];
}

class BarcodeGeneratorInitial extends BarcodeGeneratorState {
  const BarcodeGeneratorInitial();
}

class BarcodeGeneratorLoading extends BarcodeGeneratorState {
  const BarcodeGeneratorLoading();
}

class BarcodeGeneratorLoaded extends BarcodeGeneratorState {
  final List<BarcodeItem> productosSinBarcode;

  const BarcodeGeneratorLoaded(this.productosSinBarcode);

  @override
  List<Object?> get props => [productosSinBarcode];
}

class BarcodeGeneratorGenerating extends BarcodeGeneratorState {
  const BarcodeGeneratorGenerating();
}

class BarcodeGeneratorGenerated extends BarcodeGeneratorState {
  final GenerarCodigosResult result;

  const BarcodeGeneratorGenerated(this.result);

  @override
  List<Object?> get props => [result];
}

class BarcodeGeneratorError extends BarcodeGeneratorState {
  final String message;
  const BarcodeGeneratorError(this.message);
  @override
  List<Object?> get props => [message];
}

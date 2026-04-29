import 'package:equatable/equatable.dart';
import 'crear_nota_item.dart';

/// Request para emitir una nota de crédito o débito.
/// Si [items] es null o vacío, el backend copia los items del comprobante origen.
class CrearNotaRequest extends Equatable {
  final String sedeId;
  final int tipoNota;
  final String motivo;
  final List<CrearNotaItem>? items;

  const CrearNotaRequest({
    required this.sedeId,
    required this.tipoNota,
    required this.motivo,
    this.items,
  });

  bool get esItemsParciales => items != null && items!.isNotEmpty;

  @override
  List<Object?> get props => [sedeId, tipoNota, motivo, items];
}

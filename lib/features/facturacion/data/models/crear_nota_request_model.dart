import '../../domain/entities/crear_nota_item.dart';
import '../../domain/entities/crear_nota_request.dart';

class CrearNotaRequestModel {
  static Map<String, dynamic> toJson(CrearNotaRequest request) {
    final body = <String, dynamic>{
      'sedeId': request.sedeId,
      'tipoNota': request.tipoNota,
      'motivo': request.motivo,
    };
    if (request.esItemsParciales) {
      body['items'] = request.items!.map(_itemToJson).toList();
    }
    return body;
  }

  static Map<String, dynamic> _itemToJson(CrearNotaItem item) {
    final json = <String, dynamic>{
      'descripcion': item.descripcion,
      'cantidad': item.cantidad,
      'valorUnitario': item.valorUnitario,
      'precioUnitario': item.precioUnitario,
    };
    if (item.tipoAfectacion != null) json['tipoAfectacion'] = item.tipoAfectacion;
    if (item.igv != null) json['igv'] = item.igv;
    if (item.icbper != null) json['icbper'] = item.icbper;
    if (item.subtotal != null) json['subtotal'] = item.subtotal;
    if (item.total != null) json['total'] = item.total;
    return json;
  }
}

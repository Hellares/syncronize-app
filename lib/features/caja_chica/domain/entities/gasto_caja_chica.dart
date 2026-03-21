import 'package:equatable/equatable.dart';

class GastoCajaChica extends Equatable {
  final String id;
  final String cajaChicaId;
  final double monto;
  final String descripcion;
  final String categoriaGastoId;
  final String categoriaGastoNombre;
  final String? categoriaGastoIcono;
  final String? categoriaGastoColor;
  final String? comprobanteUrl;
  final String? rendicionId;
  final String registradoPorNombre;
  final DateTime fechaGasto;

  const GastoCajaChica({
    required this.id,
    required this.cajaChicaId,
    required this.monto,
    required this.descripcion,
    required this.categoriaGastoId,
    required this.categoriaGastoNombre,
    this.categoriaGastoIcono,
    this.categoriaGastoColor,
    this.comprobanteUrl,
    this.rendicionId,
    required this.registradoPorNombre,
    required this.fechaGasto,
  });

  bool get pendiente => rendicionId == null;

  @override
  List<Object?> get props => [
        id,
        cajaChicaId,
        monto,
        descripcion,
        categoriaGastoId,
        comprobanteUrl,
        rendicionId,
        fechaGasto,
      ];
}

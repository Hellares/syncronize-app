import '../../domain/entities/combo.dart';
import 'combo_model.dart';

/// DTO para crear un combo directamente
class CreateComboDto {
  final String empresaId;
  final String nombre;
  final TipoPrecioCombo tipoPrecioCombo;

  // Campos opcionales
  final String? sedeId;
  final String? empresaCategoriaId;
  final String? empresaMarcaId;
  final String? descripcion;
  final double? precioFijo; // Requerido si tipoPrecioCombo = 'FIJO'
  final double? descuentoPorcentaje; // Requerido si tipoPrecioCombo = 'CALCULADO_CON_DESCUENTO'
  final String? sku;
  final String? codigoBarras;
  final Map<String, dynamic>? detalles;
  final int? stockMinimo;
  final String? videoUrl;
  final double? impuestoPorcentaje;
  final bool? visibleMarketplace;
  final bool? destacado;
  final List<String>? imagenesIds;

  CreateComboDto({
    required this.empresaId,
    required this.nombre,
    required this.tipoPrecioCombo,
    this.sedeId,
    this.empresaCategoriaId,
    this.empresaMarcaId,
    this.descripcion,
    this.precioFijo,
    this.descuentoPorcentaje,
    this.sku,
    this.codigoBarras,
    this.detalles,
    this.stockMinimo,
    this.videoUrl,
    this.impuestoPorcentaje,
    this.visibleMarketplace,
    this.destacado,
    this.imagenesIds,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'empresaId': empresaId,
      'nombre': nombre,
      'tipoPrecioCombo': ComboModel.tipoPrecioComboToString(tipoPrecioCombo),
    };

    // Solo agregar campos opcionales si tienen valor
    if (sedeId != null) map['sedeId'] = sedeId;
    if (empresaCategoriaId != null) map['empresaCategoriaId'] = empresaCategoriaId;
    if (empresaMarcaId != null) map['empresaMarcaId'] = empresaMarcaId;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (precioFijo != null) map['precioFijo'] = precioFijo;
    if (descuentoPorcentaje != null) map['descuentoPorcentaje'] = descuentoPorcentaje;
    if (sku != null) map['sku'] = sku;
    if (codigoBarras != null) map['codigoBarras'] = codigoBarras;
    if (detalles != null) map['detalles'] = detalles;
    if (stockMinimo != null) map['stockMinimo'] = stockMinimo;
    if (videoUrl != null) map['videoUrl'] = videoUrl;
    if (impuestoPorcentaje != null) map['impuestoPorcentaje'] = impuestoPorcentaje;
    if (visibleMarketplace != null) map['visibleMarketplace'] = visibleMarketplace;
    if (destacado != null) map['destacado'] = destacado;
    if (imagenesIds != null) map['imagenesIds'] = imagenesIds;

    return map;
  }
}

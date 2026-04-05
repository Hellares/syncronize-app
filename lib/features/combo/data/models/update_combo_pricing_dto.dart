import '../../domain/entities/combo.dart';
import 'combo_model.dart';

class UpdateComboPricingDto {
  final TipoPrecioCombo? tipoPrecioCombo;
  final double? descuentoPorcentaje;
  final double? precioFijo;
  final String? razon;

  UpdateComboPricingDto({
    this.tipoPrecioCombo,
    this.descuentoPorcentaje,
    this.precioFijo,
    this.razon,
  });

  Map<String, dynamic> toJson() {
    return {
      if (tipoPrecioCombo != null)
        'tipoPrecioCombo': ComboModel.tipoPrecioComboToString(tipoPrecioCombo!),
      if (descuentoPorcentaje != null)
        'descuentoPorcentaje': descuentoPorcentaje,
      if (precioFijo != null) 'precioFijo': precioFijo,
      if (razon != null) 'razon': razon,
    };
  }
}

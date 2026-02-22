class UpdateComboOfertaDto {
  final double precioOferta;
  final bool enOferta;
  final String? fechaInicioOferta;
  final String? fechaFinOferta;
  final String? razon;

  UpdateComboOfertaDto({
    required this.precioOferta,
    required this.enOferta,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    this.razon,
  });

  Map<String, dynamic> toJson() {
    return {
      'precioOferta': precioOferta,
      'enOferta': enOferta,
      if (fechaInicioOferta != null) 'fechaInicioOferta': fechaInicioOferta,
      if (fechaFinOferta != null) 'fechaFinOferta': fechaFinOferta,
      if (razon != null) 'razon': razon,
    };
  }
}

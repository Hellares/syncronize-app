/// DTO para enviar un atributo estructurado
/// Corresponde con backend: VarianteAtributoDto
class VarianteAtributoDto {
  final String atributoId; // ID del ProductoAtributo
  final String valor; // Valor del atributo

  const VarianteAtributoDto({
    required this.atributoId,
    required this.valor,
  });

  Map<String, dynamic> toJson() {
    return {
      'atributoId': atributoId,
      'valor': valor,
    };
  }

  factory VarianteAtributoDto.fromJson(Map<String, dynamic> json) {
    return VarianteAtributoDto(
      atributoId: json['atributoId'] as String,
      valor: json['valor'] as String,
    );
  }
}

/// DTO para asignar múltiples atributos a un producto o variante
/// Corresponde con backend: SetProductoAtributosDto
class SetProductoAtributosDto {
  final List<VarianteAtributoDto> atributos;

  const SetProductoAtributosDto({
    required this.atributos,
  });

  Map<String, dynamic> toJson() {
    return {
      'atributos': atributos.map((e) => e.toJson()).toList(),
    };
  }

  factory SetProductoAtributosDto.fromJson(Map<String, dynamic> json) {
    return SetProductoAtributosDto(
      atributos: (json['atributos'] as List)
          .map((e) => VarianteAtributoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

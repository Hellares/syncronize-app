import '../../domain/entities/proveedor_banco.dart';

/// Model que representa una cuenta bancaria del proveedor
class ProveedorBancoModel extends ProveedorBanco {
  const ProveedorBancoModel({
    required super.id,
    required super.proveedorId,
    required super.nombreBanco,
    required super.tipoCuenta,
    required super.numeroCuenta,
    super.cci,
    super.swift,
    super.moneda,
    required super.esPrincipal,
    required super.creadoEn,
  });

  /// Crea una instancia desde JSON
  factory ProveedorBancoModel.fromJson(Map<String, dynamic> json) {
    return ProveedorBancoModel(
      id: json['id'] as String,
      proveedorId: json['proveedorId'] as String,
      nombreBanco: json['nombreBanco'] as String,
      tipoCuenta: _tipoCuentaFromString(json['tipoCuenta'] as String),
      numeroCuenta: json['numeroCuenta'] as String,
      cci: json['cci'] as String?,
      swift: json['swift'] as String?,
      moneda: json['moneda'] as String? ?? 'PEN',
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'nombreBanco': nombreBanco,
      'tipoCuenta': _tipoCuentaToString(tipoCuenta),
      'numeroCuenta': numeroCuenta,
      'cci': cci,
      'swift': swift,
      'moneda': moneda,
      'esPrincipal': esPrincipal,
    };
  }

  // Helper methods para conversión de enum
  static TipoCuenta _tipoCuentaFromString(String tipo) {
    return TipoCuenta.values.firstWhere(
      (e) => e.toString().split('.').last == tipo,
      orElse: () => TipoCuenta.AHORROS,
    );
  }

  static String _tipoCuentaToString(TipoCuenta tipo) {
    return tipo.toString().split('.').last;
  }
}

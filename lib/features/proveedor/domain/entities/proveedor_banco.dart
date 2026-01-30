import 'package:equatable/equatable.dart';

/// Enum para tipo de cuenta bancaria
/// Valores en MAYÚSCULAS para mantener consistencia con esquema Prisma
// ignore_for_file: constant_identifier_names
enum TipoCuenta {
  AHORROS,
  CORRIENTE,
  INTERBANCARIA,
}

/// Entity que representa una cuenta bancaria del proveedor
class ProveedorBanco extends Equatable {
  final String id;
  final String proveedorId;
  final String nombreBanco;
  final TipoCuenta tipoCuenta;
  final String numeroCuenta;
  final String? cci;
  final String? swift;
  final String moneda;
  final bool esPrincipal;
  final DateTime creadoEn;

  const ProveedorBanco({
    required this.id,
    required this.proveedorId,
    required this.nombreBanco,
    required this.tipoCuenta,
    required this.numeroCuenta,
    this.cci,
    this.swift,
    this.moneda = 'PEN',
    required this.esPrincipal,
    required this.creadoEn,
  });

  /// Obtiene el texto descriptivo del tipo de cuenta
  String get tipoCuentaTexto {
    switch (tipoCuenta) {
      case TipoCuenta.AHORROS:
        return 'Ahorros';
      case TipoCuenta.CORRIENTE:
        return 'Corriente';
      case TipoCuenta.INTERBANCARIA:
        return 'Interbancaria';
    }
  }

  /// Obtiene el símbolo de la moneda
  String get simboloMoneda {
    switch (moneda) {
      case 'PEN':
        return 'S/';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return moneda;
    }
  }

  /// Formatea el número de cuenta (oculta parte del número)
  String get numeroCuentaOculto {
    if (numeroCuenta.length <= 4) return numeroCuenta;
    final ultimos4 = numeroCuenta.substring(numeroCuenta.length - 4);
    return '**** $ultimos4';
  }

  /// Verifica si tiene datos completos para transferencias internacionales
  bool get aptoTransferenciasInternacionales {
    return swift != null && swift!.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        proveedorId,
        nombreBanco,
        tipoCuenta,
        numeroCuenta,
        cci,
        swift,
        moneda,
        esPrincipal,
        creadoEn,
      ];
}

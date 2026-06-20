import 'package:equatable/equatable.dart';

/// Banco asignado a un método de recaudación.
class BancoRecaudacion extends Equatable {
  final String id;
  final String nombreBanco;
  final String numeroCuenta;
  final String moneda;

  const BancoRecaudacion({
    required this.id,
    required this.nombreBanco,
    required this.numeroCuenta,
    this.moneda = 'PEN',
  });

  @override
  List<Object?> get props => [id, nombreBanco, numeroCuenta, moneda];
}

/// Una fila del mapeo método→cuenta de recaudación.
class RecaudacionMetodo extends Equatable {
  final String metodoPago; // YAPE | PLIN | TARJETA | TRANSFERENCIA
  final String? bancoId;
  final BancoRecaudacion? banco;

  const RecaudacionMetodo({
    required this.metodoPago,
    this.bancoId,
    this.banco,
  });

  String get metodoLabel {
    switch (metodoPago) {
      case 'YAPE':
        return 'Yape';
      case 'PLIN':
        return 'Plin';
      case 'TARJETA':
        return 'Tarjeta';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      default:
        return metodoPago;
    }
  }

  RecaudacionMetodo copyWith({String? bancoId, BancoRecaudacion? banco, bool limpiar = false}) {
    return RecaudacionMetodo(
      metodoPago: metodoPago,
      bancoId: limpiar ? null : (bancoId ?? this.bancoId),
      banco: limpiar ? null : (banco ?? this.banco),
    );
  }

  @override
  List<Object?> get props => [metodoPago, bancoId];
}

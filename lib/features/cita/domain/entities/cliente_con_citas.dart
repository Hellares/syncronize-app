import 'package:equatable/equatable.dart';

class ClienteConCitas extends Equatable {
  final String tipo; // 'persona' | 'empresa'
  final String? clienteId;
  final String? clienteEmpresaId;
  final String nombre;
  final String? telefono;
  final String? email;
  final int totalCitas;

  const ClienteConCitas({
    required this.tipo,
    this.clienteId,
    this.clienteEmpresaId,
    required this.nombre,
    this.telefono,
    this.email,
    required this.totalCitas,
  });

  bool get isPersona => tipo == 'persona';

  String get id => clienteId ?? clienteEmpresaId ?? '';

  factory ClienteConCitas.fromJson(Map<String, dynamic> json) {
    return ClienteConCitas(
      tipo: json['tipo'] as String? ?? 'persona',
      clienteId: json['clienteId'] as String?,
      clienteEmpresaId: json['clienteEmpresaId'] as String?,
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      totalCitas: (json['totalCitas'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [tipo, clienteId, clienteEmpresaId, totalCitas];
}

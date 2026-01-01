import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/registro_cliente_response.dart';
import '../repositories/cliente_repository.dart';

/// Use case para registrar o asociar un cliente
@injectable
class RegistrarClienteUseCase {
  final ClienteRepository _repository;

  RegistrarClienteUseCase(this._repository);

  /// Registra un nuevo cliente o asocia uno existente
  Future<Resource<RegistroClienteResponse>> call({
    required String empresaId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String telefono,
    String? email,
    String? direccion,
    String? distrito,
    String? provincia,
    String? departamento,
    String? notas,
  }) async {
    // Validaciones básicas
    if (dni.length != 8) {
      return Error('El DNI debe tener 8 dígitos');
    }

    if (telefono.length != 9) {
      return Error('El teléfono debe tener 9 dígitos');
    }

    if (nombres.trim().isEmpty) {
      return Error('Los nombres son obligatorios');
    }

    if (apellidos.trim().isEmpty) {
      return Error('Los apellidos son obligatorios');
    }

    // Construir data para enviar al backend
    final data = <String, dynamic>{
      'dni': dni.trim(),
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'telefono': telefono.trim(),
    };

    // Agregar campos opcionales solo si tienen valor
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (direccion != null && direccion.trim().isNotEmpty) {
      data['direccion'] = direccion.trim();
    }

    if (distrito != null && distrito.trim().isNotEmpty) {
      data['distrito'] = distrito.trim();
    }

    if (provincia != null && provincia.trim().isNotEmpty) {
      data['provincia'] = provincia.trim();
    }

    if (departamento != null && departamento.trim().isNotEmpty) {
      data['departamento'] = departamento.trim();
    }

    if (notas != null && notas.trim().isNotEmpty) {
      data['notas'] = notas.trim();
    }

    return await _repository.registrarCliente(
      empresaId: empresaId,
      data: data,
    );
  }
}

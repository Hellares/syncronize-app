import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/registro_usuario_response.dart';
import '../repositories/usuario_repository.dart';

/// Use case para registrar un nuevo usuario/empleado
@injectable
class RegistrarUsuarioUseCase {
  final UsuarioRepository _repository;

  RegistrarUsuarioUseCase(this._repository);

  /// Ejecuta el use case para registrar un usuario
  ///
  /// Valida los datos antes de enviarlos al repositorio
  Future<Resource<RegistroUsuarioResponse>> call({
    required String empresaId,
    required String dni,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String rol,
    String? email,
    List<String>? sedeIds,
    bool? puedeAbrirCaja,
    bool? puedeCerrarCaja,
    double? limiteCreditoVenta,
    List<String>? permisos,
    String? notas,
  }) async {
    // Validaciones
    if (dni.length != 8) {
      return Error('El DNI debe tener exactamente 8 dígitos');
    }

    if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
      return Error('El DNI debe contener solo números');
    }

    if (telefono.length != 9) {
      return Error('El teléfono debe tener exactamente 9 dígitos');
    }

    if (!RegExp(r'^9\d{8}$').hasMatch(telefono)) {
      return Error('El teléfono debe comenzar con 9 y tener 9 dígitos');
    }

    if (nombres.trim().isEmpty) {
      return Error('Los nombres son obligatorios');
    }

    if (apellidos.trim().isEmpty) {
      return Error('Los apellidos son obligatorios');
    }

    if (email != null && email.trim().isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(email.trim())) {
        return Error('El email no tiene un formato válido');
      }
    }

    // Validar rol
    final rolesValidos = [
      'VENDEDOR',
      'CAJERO',
      'TECNICO',
      'CONTADOR',
      'EMPRESA_ADMIN',
      'SEDE_ADMIN',
      'SUPER_ADMIN',
      'OPERADOR',
      'LECTURA',
    ];

    if (!rolesValidos.contains(rol)) {
      return Error('El rol especificado no es válido');
    }

    // Construir data
    final data = <String, dynamic>{
      'dni': dni.trim(),
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'telefono': telefono.trim(),
      'rol': rol,
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (sedeIds != null && sedeIds.isNotEmpty) {
      data['sedeIds'] = sedeIds;
    }

    if (puedeAbrirCaja != null) {
      data['puedeAbrirCaja'] = puedeAbrirCaja;
    }

    if (puedeCerrarCaja != null) {
      data['puedeCerrarCaja'] = puedeCerrarCaja;
    }

    if (limiteCreditoVenta != null && limiteCreditoVenta > 0) {
      data['limiteCreditoVenta'] = limiteCreditoVenta;
    }

    if (permisos != null && permisos.isNotEmpty) {
      data['permisos'] = permisos;
    }

    if (notas != null && notas.trim().isNotEmpty) {
      data['notas'] = notas.trim();
    }

    return await _repository.registrarUsuario(
      empresaId: empresaId,
      data: data,
    );
  }

  /// Ejecuta el use case con datos en formato Map
  ///
  /// Útil para conversiones de cliente a empleado donde ya tenemos
  /// los datos en formato de mapa
  Future<Resource<RegistroUsuarioResponse>> callWithData({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    // Validaciones básicas
    final dni = data['dni'] as String?;
    final nombres = data['nombres'] as String?;
    final apellidos = data['apellidos'] as String?;
    final rol = data['rol'] as String?;

    if (dni == null || dni.isEmpty) {
      return Error('El DNI es obligatorio');
    }

    if (nombres == null || nombres.isEmpty) {
      return Error('Los nombres son obligatorios');
    }

    if (apellidos == null || apellidos.isEmpty) {
      return Error('Los apellidos son obligatorios');
    }

    if (rol == null || rol.isEmpty) {
      return Error('El rol es obligatorio');
    }

    // Usar el repositorio directamente ya que los datos vienen validados
    return await _repository.registrarUsuario(
      empresaId: empresaId,
      data: data,
    );
  }
}

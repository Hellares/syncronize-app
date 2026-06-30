import '../../../../core/network/dio_client.dart';

/// Estado de activación (readiness) de una sede para operar como POS.
class SedeReadiness {
  final String sedeNombre;
  final bool esPrincipal;
  final int usuarios;
  final int productosConPrecio;
  final int productosConStock;
  final int totalProductos;
  final bool cajaCentral;
  final bool listaParaVender;

  SedeReadiness({
    required this.sedeNombre,
    required this.esPrincipal,
    required this.usuarios,
    required this.productosConPrecio,
    required this.productosConStock,
    required this.totalProductos,
    required this.cajaCentral,
    required this.listaParaVender,
  });

  factory SedeReadiness.fromJson(Map<String, dynamic> j) {
    final sede = (j['sede'] as Map<String, dynamic>?) ?? const {};
    return SedeReadiness(
      sedeNombre: sede['nombre']?.toString() ?? 'Sede',
      esPrincipal: sede['esPrincipal'] == true,
      usuarios: (j['usuarios'] as num?)?.toInt() ?? 0,
      productosConPrecio: (j['productosConPrecio'] as num?)?.toInt() ?? 0,
      productosConStock: (j['productosConStock'] as num?)?.toInt() ?? 0,
      totalProductos: (j['totalProductos'] as num?)?.toInt() ?? 0,
      cajaCentral: j['cajaCentral'] == true,
      listaParaVender: j['listaParaVender'] == true,
    );
  }
}

/// Usuario asignado a una sede (UsuarioSedeRol).
class SedeUsuario {
  final String usuarioSedeRolId;
  final String usuarioId;
  final String nombre;
  final String? email;
  final String rol;
  final bool puedeAbrirCaja;

  SedeUsuario({
    required this.usuarioSedeRolId,
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.puedeAbrirCaja,
  });

  factory SedeUsuario.fromJson(Map<String, dynamic> j) {
    final u = (j['usuario'] as Map<String, dynamic>?) ?? const {};
    final persona = (u['persona'] as Map<String, dynamic>?) ?? const {};
    final nombre =
        '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
    return SedeUsuario(
      usuarioSedeRolId: j['id']?.toString() ?? '',
      usuarioId: u['id']?.toString() ?? j['usuarioId']?.toString() ?? '',
      nombre: nombre.isNotEmpty ? nombre : (u['email']?.toString() ?? 'Usuario'),
      email: u['email']?.toString(),
      rol: j['rol']?.toString() ?? '',
      puedeAbrirCaja: j['puedeAbrirCaja'] == true,
    );
  }
}

/// Llamadas al backend para el onboarding de una sede. La empresa va por header
/// (x-tenant-id), pero las rutas la incluyen en el path.
class SedeOnboardingApi {
  final DioClient _dio;
  SedeOnboardingApi(this._dio);

  String _base(String empresaId, String sedeId) =>
      '/empresas/$empresaId/sedes/$sedeId';

  Future<SedeReadiness> getReadiness(String empresaId, String sedeId) async {
    final res = await _dio.get('${_base(empresaId, sedeId)}/readiness');
    return SedeReadiness.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SedeUsuario>> getUsuarios(String empresaId, String sedeId) async {
    final res = await _dio.get('${_base(empresaId, sedeId)}/usuarios');
    final list = res.data as List<dynamic>? ?? [];
    return list
        .map((e) => SedeUsuario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> asignarUsuario(
    String empresaId,
    String sedeId, {
    required String usuarioId,
    required String rol,
    bool puedeAbrirCaja = false,
    bool puedeCerrarCaja = false,
  }) async {
    await _dio.post('${_base(empresaId, sedeId)}/usuarios', data: {
      'usuarioId': usuarioId,
      'rol': rol,
      'puedeAbrirCaja': puedeAbrirCaja,
      'puedeCerrarCaja': puedeCerrarCaja,
    });
  }

  Future<void> removerUsuario(
    String empresaId,
    String sedeId,
    String usuarioSedeRolId,
  ) async {
    await _dio.delete('${_base(empresaId, sedeId)}/usuarios/$usuarioSedeRolId');
  }
}

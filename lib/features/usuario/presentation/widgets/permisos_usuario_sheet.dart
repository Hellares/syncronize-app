import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/usuario_remote_datasource.dart';

/// "Qué puede hacer este usuario, y por qué."
///
/// Los permisos NO se guardan: el backend los calcula desde los roles. Antes
/// de esta pantalla, para saber por qué un cajero veía el libro contable había
/// que mirar su rol, mirar sus permisos especiales y aplicar mentalmente una
/// función de 200 líneas.
///
/// Muestra tres bloques porque responden preguntas distintas:
///  - lo que PUEDE hacer, con el origen de cada permiso;
///  - lo que un admin le asignó a mano;
///  - lo que NO VE aunque pueda. Distinguirlo importa: "no aparece" puede ser
///    falta de permiso o puede ser que se lo ocultaron, y se arreglan en
///    lugares opuestos.
Future<void> mostrarPermisosDeUsuario(
  BuildContext context, {
  required String usuarioId,
  required String nombre,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _PermisosSheet(usuarioId: usuarioId, nombre: nombre),
  );
}

class _PermisosSheet extends StatefulWidget {
  final String usuarioId;
  final String nombre;

  const _PermisosSheet({required this.usuarioId, required this.nombre});

  @override
  State<_PermisosSheet> createState() => _PermisosSheetState();
}

class _PermisosSheetState extends State<_PermisosSheet> {
  Map<String, dynamic>? _datos;
  String? _error;

  /// Los negados arrancan colapsados: son la mayoría y no son la pregunta
  /// habitual. Quien abre esto quiere ver qué SÍ puede hacer.
  bool _verNegados = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await locator<UsuarioRemoteDataSource>()
          .getPermisosDeUsuario(usuarioId: widget.usuarioId);
      if (!mounted) return;
      setState(() => _datos = datos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar los permisos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 18, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCuerpo(scrollController)),
          ],
        );
      },
    );
  }

  Widget _buildCuerpo(ScrollController controller) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
        ),
      );
    }
    if (_datos == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final permisos = (_datos!['permisos'] as List).cast<Map<String, dynamic>>();
    final concedidos = permisos.where((p) => p['valor'] == true).toList();
    final negados = permisos.where((p) => p['valor'] != true).toList();
    final roles = (_datos!['roles'] as List).cast<String>();
    final asignado = _datos!['asignado'] as Map<String, dynamic>;
    final ocultos = _datos!['ocultos'] as Map<String, dynamic>;
    final especiales = (asignado['permisosEspeciales'] as List).cast<String>();
    final ocultosDash = (ocultos['dashboard'] as List).cast<String>();
    final ocultosMenu = (ocultos['menu'] as List).cast<String>();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Rol: ${roles.join(', ')}  ·  ${concedidos.length} de ${permisos.length} permisos',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        _titulo('Qué puede hacer'),
        ...concedidos.map(_filaPermiso),

        const SizedBox(height: 12),
        _titulo('Asignado a mano'),
        if (especiales.isEmpty)
          _vacio('Nada: todo le viene de su rol')
        else
          ...especiales.map((id) => _filaSimple(Icons.vpn_key, id)),

        const SizedBox(height: 12),
        _titulo('Qué NO ve (aunque pueda)'),
        if (ocultosDash.isEmpty && ocultosMenu.isEmpty)
          _vacio('Nada oculto: ve todo lo que su rol permite')
        else ...[
          if (ocultosDash.isNotEmpty)
            _filaSimple(Icons.dashboard_outlined,
                'Dashboard: ${ocultosDash.join(', ')}'),
          if (ocultosMenu.isNotEmpty)
            _filaSimple(Icons.menu_open, 'Menú: ${ocultosMenu.join(', ')}'),
        ],

        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _verNegados = !_verNegados),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(_verNegados ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Lo que NO puede hacer (${negados.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_verNegados) ...negados.map(_filaPermiso),
      ],
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.blue1.withValues(alpha: 0.75),
          ),
        ),
      );

  Widget _vacio(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(texto,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      );

  Widget _filaSimple(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(texto, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );

  /// El "por qué" es la mitad del valor de esta pantalla: sin él, un admin ve
  /// que el permiso está y no sabe si se lo quita cambiándole el rol o
  /// destildando un permiso especial.
  Widget _filaPermiso(Map<String, dynamic> p) {
    final tiene = p['valor'] == true;
    final origen = p['origen'] as String?;
    final detalle = p['detalle'] as String?;

    final explicacion = switch (origen) {
      'rol' => 'por su rol ${detalle ?? ''}'.trim(),
      'especial' => 'por el permiso especial "$detalle"',
      _ => 'ningún rol suyo lo otorga',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tiene ? Icons.check_circle : Icons.remove_circle_outline,
            size: 14,
            color: tiene ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['clave'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: tiene ? FontWeight.w600 : FontWeight.normal,
                    color: tiene ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  explicacion,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

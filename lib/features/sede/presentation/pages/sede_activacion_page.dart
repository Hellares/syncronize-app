import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../usuario/domain/entities/usuario.dart';
import '../../../usuario/presentation/bloc/usuario_list/usuario_list_cubit.dart';
import '../../../usuario/presentation/bloc/usuario_list/usuario_list_state.dart';
import '../../data/datasources/sede_onboarding_api.dart';
import '../bloc/sede_activacion/sede_activacion_cubit.dart';

/// Roles de sede ofrecidos al asignar (los relevantes para un POS).
const _rolesSede = <String, String>{
  'CAJERO': 'Cajero',
  'VENDEDOR': 'Vendedor',
  'GERENTE_SEDE': 'Gerente de sede',
  'ALMACENERO': 'Almacenero',
};

class SedeActivacionPage extends StatelessWidget {
  final String sedeId;
  const SedeActivacionPage({super.key, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      return const Scaffold(body: Center(child: Text('Falta contexto de empresa')));
    }
    final empresaId = empresaState.context.empresa.id;
    return BlocProvider(
      create: (_) => SedeActivacionCubit(
        SedeOnboardingApi(locator<DioClient>()),
        empresaId: empresaId,
        sedeId: sedeId,
      )..cargar(),
      child: _ActivacionView(empresaId: empresaId, sedeId: sedeId),
    );
  }
}

class _ActivacionView extends StatelessWidget {
  final String empresaId;
  final String sedeId;
  const _ActivacionView({required this.empresaId, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Activar sede',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SedeActivacionCubit, SedeActivacionState>(
        builder: (context, state) {
          if (state.cargando && state.readiness == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.readiness == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.error!, textAlign: TextAlign.center),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<SedeActivacionCubit>().cargar(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final r = state.readiness;
          if (r == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: () => context.read<SedeActivacionCubit>().cargar(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _header(r),
                const SizedBox(height: 12),
                _checklist(context, r),
                const SizedBox(height: 16),
                _seccionUsuarios(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(SedeReadiness r) {
    final lista = r.listaParaVender;
    return GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(lista ? Icons.check_circle : Icons.pending_actions,
              color: lista ? Colors.green : Colors.orange.shade700, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.sedeNombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  lista
                      ? 'Lista para vender'
                      : 'Faltan pasos para que pueda vender',
                  style: TextStyle(
                    fontSize: 12,
                    color: lista ? Colors.green.shade700 : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklist(BuildContext context, SedeReadiness r) {
    return Column(
      children: [
        _checkRow(
          ok: r.usuarios > 0,
          icon: Icons.people_alt_outlined,
          titulo: 'Usuarios asignados',
          detalle: '${r.usuarios} usuario(s) en esta sede',
          // La acción de usuarios está en la sección de abajo.
        ),
        _checkRow(
          ok: r.productosConPrecio > 0,
          icon: Icons.sell_outlined,
          titulo: 'Precios configurados',
          detalle: '${r.productosConPrecio}/${r.totalProductos} productos con precio',
          accionLabel: 'Configurar precios',
          onAccion: () => context.push('/empresa/inventario/verificacion-precios'),
        ),
        _checkRow(
          ok: r.productosConStock > 0,
          icon: Icons.inventory_2_outlined,
          titulo: 'Stock cargado',
          detalle: '${r.productosConStock} producto(s) con stock',
          accionLabel: 'Cargar stock',
          onAccion: () => _menuStock(context),
        ),
      ],
    );
  }

  Widget _checkRow({
    required bool ok,
    required IconData icon,
    required String titulo,
    required String detalle,
    String? accionLabel,
    VoidCallback? onAccion,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                color: ok ? Colors.green : Colors.grey.shade400, size: 20),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: AppColors.blue1),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(detalle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (accionLabel != null)
              TextButton(
                onPressed: onAccion,
                child: Text(accionLabel, style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  void _menuStock(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: AppColors.blue1),
              title: const Text('Registrar compra (recepción)'),
              subtitle: const Text('Cargar stock comprando a un proveedor'),
              onTap: () {
                Navigator.pop(context);
                context.push('/empresa/inventario/compras/nueva');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.blue1),
              title: const Text('Transferir desde otra sede'),
              subtitle: const Text('Mover stock de otra sede a esta'),
              onTap: () {
                Navigator.pop(context);
                context.push('/empresa/inventario/transferencias/crear');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionUsuarios(BuildContext context, SedeActivacionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Usuarios de la sede',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _abrirAsignar(context),
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('Asignar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (state.usuarios.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sin usuarios asignados. Asigná al menos un cajero o vendedor para que la sede pueda operar.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else
          ...state.usuarios.map((u) => _usuarioTile(context, u)),
      ],
    );
  }

  Widget _usuarioTile(BuildContext context, SedeUsuario u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.blue1.withValues(alpha: 0.12),
          child: const Icon(Icons.person, size: 16, color: AppColors.blue1),
        ),
        title: Text(u.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Text(_rolesSede[u.rol] ?? u.rol,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            if (u.puedeAbrirCaja) ...[
              const SizedBox(width: 6),
              Icon(Icons.point_of_sale, size: 12, color: Colors.green.shade600),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
          onPressed: () => _confirmarRemover(context, u),
        ),
      ),
    );
  }

  Future<void> _confirmarRemover(BuildContext context, SedeUsuario u) async {
    final cubit = context.read<SedeActivacionCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar de la sede'),
        content: Text('¿Quitar a ${u.nombre} de esta sede?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await cubit.remover(u.usuarioSedeRolId);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  void _abrirAsignar(BuildContext context) {
    final cubit = context.read<SedeActivacionCubit>();
    // Cargar usuarios de la empresa para el picker (si no están cargados).
    final usuarioCubit = context.read<UsuarioListCubit>();
    if (usuarioCubit.state is! UsuarioListLoaded) {
      usuarioCubit.loadUsuarios(empresaId: empresaId);
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AsignarSheet(cubit: cubit, usuarioCubit: usuarioCubit),
    );
  }
}

class _AsignarSheet extends StatefulWidget {
  final SedeActivacionCubit cubit;
  final UsuarioListCubit usuarioCubit;
  const _AsignarSheet({required this.cubit, required this.usuarioCubit});

  @override
  State<_AsignarSheet> createState() => _AsignarSheetState();
}

class _AsignarSheetState extends State<_AsignarSheet> {
  Usuario? _usuario;
  String _rol = 'CAJERO';
  bool _puedeAbrirCaja = true;
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asignar usuario a la sede',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Picker de usuario
          BlocBuilder<UsuarioListCubit, UsuarioListState>(
            bloc: widget.usuarioCubit,
            builder: (context, st) {
              if (st is UsuarioListLoading) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final usuarios = st is UsuarioListLoaded ? st.usuarios : <Usuario>[];
              return DropdownButtonFormField<Usuario>(
                initialValue: _usuario,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: usuarios
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _usuario = v),
              );
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _rol,
            decoration: const InputDecoration(
              labelText: 'Rol en la sede',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _rolesSede.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _rol = v ?? 'CAJERO'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Puede abrir/cerrar caja', style: TextStyle(fontSize: 13)),
            value: _puedeAbrirCaja,
            onChanged: (v) => setState(() => _puedeAbrirCaja = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_usuario == null || _guardando) ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Asignar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final err = await widget.cubit.asignar(
      usuarioId: _usuario!.id,
      rol: _rol,
      puedeAbrirCaja: _puedeAbrirCaja,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

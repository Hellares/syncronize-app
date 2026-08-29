import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/domain/usecases/get_sedes_usecase.dart';

/// Selector de sede para entrar a la pantalla de Tesorería.
///
/// Si la empresa tiene una sola sede, redirige directo. Si tiene varias,
/// muestra la lista para que el admin elija. Las tesorerias son
/// independientes por sede (acordado en diseño).
class TesoreriaSedeSelectorPage extends StatefulWidget {
  /// Puede venir vacío: la ruta lo lee del query string y no todos los
  /// accesos lo mandan. La tesorería es SIEMPRE la de la empresa en la que
  /// ya estás parado, así que el contexto es la fuente real y el parámetro
  /// queda como atajo para deep links.
  final String empresaId;

  const TesoreriaSedeSelectorPage({super.key, this.empresaId = ''});

  @override
  State<TesoreriaSedeSelectorPage> createState() =>
      _TesoreriaSedeSelectorPageState();
}

class _TesoreriaSedeSelectorPageState extends State<TesoreriaSedeSelectorPage> {
  late Future<List<Sede>?> _future;
  late String _empresaId;

  @override
  void initState() {
    super.initState();
    _empresaId = widget.empresaId.isNotEmpty
        ? widget.empresaId
        : _empresaIdDelContexto();
    _future = _loadSedes();
  }

  String _empresaIdDelContexto() {
    final estado = context.read<EmpresaContextCubit>().state;
    return estado is EmpresaContextLoaded ? estado.context.empresa.id : '';
  }

  Future<List<Sede>?> _loadSedes() async {
    if (_empresaId.isEmpty) return null;
    final res = await locator<GetSedesUseCase>().call(_empresaId);
    if (res is Success<List<Sede>>) {
      final sedes = res.data;
      // Auto-redirect si hay una sola sede.
      if (sedes.length == 1 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.pushReplacement('/empresa/tesoreria/${sedes.first.id}');
        });
      }
      return sedes;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: const SmartAppBar(
        title: 'Tesorería — Elegir sede',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: FutureBuilder<List<Sede>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sedes = snapshot.data;
          if (sedes == null) {
            // Se distinguen porque se arreglan distinto: sin empresa activa
            // hay que volver a entrar a la empresa; lo otro es la red o el
            // servidor.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _empresaId.isEmpty
                      ? 'No hay una empresa activa. Volvé a entrar a la '
                          'empresa e intentá de nuevo.'
                      : 'No se pudieron cargar las sedes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (sedes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay sedes registradas.'),
              ),
            );
          }
          return ListView.separated(
            itemCount: sedes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = sedes[i];
              return ListTile(
                leading: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.blue1,
                ),
                title: Text(
                  s.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(s.codigo),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/empresa/tesoreria/${s.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

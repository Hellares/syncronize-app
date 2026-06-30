import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sede_activa/sede_activa_cubit.dart';
import '../bloc/sede_activa/sede_activa_state.dart';

/// Chip que muestra la SEDE ACTIVA y permite cambiarla (si hay más de una
/// sede operable). Lee/escribe el `SedeActivaCubit` global.
class SedeSwitcher extends StatelessWidget {
  const SedeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SedeActivaCubit, SedeActivaState>(
      builder: (context, state) {
        final activa = state.activa;
        if (activa == null) return const SizedBox.shrink();
        final puedeElegir = state.puedeElegir;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: puedeElegir ? () => _abrirSelector(context, state) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    activa.nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue),
                  ),
                ),
                if (puedeElegir) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.unfold_more, size: 15, color: Colors.blue),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirSelector(BuildContext context, SedeActivaState state) {
    final cubit = context.read<SedeActivaCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sede activa',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            ...state.operables.map((s) {
              final esActiva = s.id == state.activa?.id;
              return ListTile(
                leading: Icon(
                  esActiva
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: esActiva ? Colors.blue : Colors.grey,
                ),
                title: Text(s.nombre),
                subtitle: Text(
                    '${s.codigo}${s.esPrincipal ? ' · Principal' : ''}'),
                onTap: () {
                  cubit.setSede(s);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

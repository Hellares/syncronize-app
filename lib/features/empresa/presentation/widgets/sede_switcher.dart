import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../bloc/sede_activa/sede_activa_cubit.dart';
import '../bloc/sede_activa/sede_activa_state.dart';

/// Selector de SEDE ACTIVA usando el `CustomDropdown` estándar de la app.
/// Si el usuario opera una sola sede, el dropdown queda deshabilitado (solo
/// muestra el nombre); con 2+ sedes permite cambiar la sede activa.
class SedeSwitcher extends StatelessWidget {
  const SedeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SedeActivaCubit, SedeActivaState>(
      builder: (context, state) {
        final activa = state.activa;
        final operables = state.operables;
        // Con una sola sede operable no hay nada que elegir → no se muestra.
        if (activa == null || operables.length <= 1) {
          return const SizedBox.shrink();
        }
        return CustomDropdown<String>(
          value: activa.id,
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.store_mall_directory_outlined,
              size: 16, color: AppColors.blue1),
          items: operables
              .map((s) => DropdownItem<String>(
                    value: s.id,
                    label: s.esPrincipal ? '${s.nombre}  ★' : s.nombre,
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null || id == activa.id) return;
            final sede = operables.firstWhere(
              (x) => x.id == id,
              orElse: () => activa,
            );
            context.read<SedeActivaCubit>().setSede(sede);
          },
        );
      },
    );
  }
}

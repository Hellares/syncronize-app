import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';

import '../../domain/entities/balanza_config.dart';
import '../bloc/balanzas_list_cubit.dart';
import '../bloc/balanzas_list_state.dart';
import 'balanza_form_page.dart';

/// Balanzas configuradas en este dispositivo.
///
/// Hermana de `ImpresorasListPage`: mismo problema —un periférico físico del
/// mostrador— y por eso se administra igual.
class BalanzasListPage extends StatelessWidget {
  const BalanzasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<BalanzasListCubit>()..cargar(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _abrirForm(BuildContext context, {BalanzaConfig? balanza}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BalanzaFormPage(balanza: balanza)),
    );
    if (ok == true && context.mounted) {
      context.read<BalanzasListCubit>().cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Balanzas',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: Builder(
        builder: (innerCtx) => FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () => _abrirForm(innerCtx),
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: GradientContainer(
        child: BlocConsumer<BalanzasListCubit, BalanzasListState>(
          listener: (context, state) {
            if (state is BalanzasListError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is BalanzasListLoading || state is BalanzasListInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BalanzasListLoaded) {
              if (state.balanzas.isEmpty) {
                return _VacioBalanzas(onAgregar: () => _abrirForm(context));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: state.balanzas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _BalanzaCard(
                  balanza: state.balanzas[i],
                  onEditar: () => _abrirForm(context, balanza: state.balanzas[i]),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _BalanzaCard extends StatelessWidget {
  final BalanzaConfig balanza;
  final VoidCallback onEditar;

  const _BalanzaCard({required this.balanza, required this.onEditar});

  Future<void> _confirmarBorrado(BuildContext context) async {
    final cubit = context.read<BalanzasListCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StyledDialog(
        accentColor: Colors.red.shade700,
        icon: Icons.delete_outline,
        titulo: 'Quitar balanza',
        subtitulo: balanza.nombre,
        content: [
          AppSubtitle(
            'Se borra la configuración de este dispositivo. No afecta ventas '
            'ya hechas.',
            fontSize: 12,
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              backgroundColor: AppColors.white,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              onPressed: () => Navigator.of(dialogCtx).pop(false),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Quitar',
              backgroundColor: Colors.red.shade700,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.eliminar(balanza.id);
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            balanza.esPrincipal ? Icons.scale : Icons.scale_outlined,
            size: 20,
            color: AppColors.blue1,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppSubtitle(
                        balanza.nombre,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (balanza.esPrincipal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.blue1,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'PRINCIPAL',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                AppSubtitle(
                  '${balanza.transporte.label} · ${balanza.perfil.nombre}',
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Que se vea desde la lista si esa balanza lee o no: entrar a
                // la ficha para descubrirlo es un paso de más justo cuando algo
                // no anda.
                if (!balanza.transporte.puedeConectar)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 11, color: Colors.orange.shade800),
                        const SizedBox(width: 3),
                        Flexible(
                          child: AppSubtitle(
                            'Esta conexión aún no lee el peso',
                            fontSize: 9,
                            color: Colors.orange.shade900,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (balanza.transporte.esSimulador)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AppSubtitle(
                      'Pesos simulados — no vender con esta',
                      fontSize: 9,
                      color: Colors.orange.shade900,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (balanza.direccion.isNotEmpty)
                  AppSubtitle(
                    balanza.direccion,
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!balanza.esPrincipal)
            _accion(
              Icons.star_outline,
              color: AppColors.blue1,
              tooltip: 'Usar como principal',
              onTap: () =>
                  context.read<BalanzasListCubit>().marcarPrincipal(balanza.id),
            ),
          _accion(Icons.edit, color: AppColors.blue1, onTap: onEditar),
          _accion(
            Icons.delete_outline,
            color: Colors.red,
            onTap: () => _confirmarBorrado(context),
          ),
        ],
      ),
    );
  }

  /// Botón de 30, como el de las filas de atributo: un `IconButton` de M3 no
  /// baja de 48 y sería él, y no el contenido, el que fija el alto de la card.
  Widget _accion(
    IconData icon, {
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final boton = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(child: Icon(icon, size: 15, color: color)),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip, child: boton);
  }
}

class _VacioBalanzas extends StatelessWidget {
  final VoidCallback onAgregar;
  const _VacioBalanzas({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.scale_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            AppSubtitle('No hay balanzas configuradas',
                fontSize: 13, color: Colors.grey.shade700),
            const SizedBox(height: 6),
            AppSubtitle(
              'Configurá una para pesar desde la venta en vez de teclear los '
              'kilos a mano.',
              fontSize: 11,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            CustomButton(
              width: 220,
              text: 'Agregar balanza',
              backgroundColor: AppColors.blue1,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              onPressed: onAgregar,
            ),
          ],
        ),
      ),
    );
  }
}

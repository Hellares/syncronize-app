import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/sincronizacion_series.dart';
import '../../domain/usecases/aplicar_sincronizacion_usecase.dart';
import '../../domain/usecases/preview_sincronizacion_usecase.dart';
import '../bloc/sincronizar_series_cubit.dart';

Future<bool?> showSincronizarSeriesDialog(
  BuildContext context, {
  required String sedeId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return BlocProvider(
        create: (_) => SincronizarSeriesCubit(
          locator<PreviewSincronizacionUseCase>(),
          locator<AplicarSincronizacionUseCase>(),
          sedeId: sedeId,
        )..cargarPreview(),
        child: const _SincronizarSeriesView(),
      );
    },
  );
}

class _SincronizarSeriesView extends StatelessWidget {
  const _SincronizarSeriesView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.88,
      child: BlocConsumer<SincronizarSeriesCubit, SincronizarSeriesState>(
        listener: (ctx, state) {
          if (state is SincronizarSeriesSuccess) {
            Navigator.of(ctx).pop(true);
            final r = state.resultado;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.green,
                content: Text(
                  'Series sincronizadas: ${r.aplicados} aplicadas, ${r.omitidos} omitidas'
                  '${r.rechazados > 0 ? ', ${r.rechazados} rechazadas' : ''}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
        builder: (ctx, state) {
          return Column(
            children: [
              _Header(),
              if (state is SincronizarSeriesLoadingPreview)
                const Expanded(child: _LoadingView())
              else if (state is SincronizarSeriesError)
                Expanded(child: _ErrorView(mensaje: state.mensaje))
              else if (state is SincronizarSeriesApplying)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Aplicando cambios…', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else if (state is SincronizarSeriesPreviewReady)
                Expanded(child: _PreviewContent(state: state)),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ──

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sync, color: AppColors.blue1, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sincronizar series',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('desde el proveedor de facturación',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Consultando series del proveedor…',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  const _ErrorView({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<SincronizarSeriesCubit>().reintentar(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview content ──

class _PreviewContent extends StatelessWidget {
  final SincronizarSeriesPreviewReady state;
  const _PreviewContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    final branch = state.branchElegido;
    final diffs = branch?.diffs ?? const <DiffSerie>[];

    return Column(
      children: [
        // Info sede + proveedor
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Icon(Icons.store_mall_directory, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(preview.sedeNombre,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(preview.proveedorActivo,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.blue1, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (preview.seriesSincronizadasEn != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(Icons.history, size: 11, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Última sincronización: ${_fmtFecha(preview.seriesSincronizadasEn!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        if (preview.branches.length > 1)
          _BranchSelector(state: state),
        if (state.hayConflicto)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hay series con conflicto. El correlativo local está por encima del proveedor. Resuelva manualmente antes de aplicar.',
                    style: TextStyle(
                        fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Selección masiva
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                '${state.cantidadSeleccionadas}/${state.cantidadAplicables} seleccionadas',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.read<SincronizarSeriesCubit>().toggleTodas(true),
                icon: const Icon(Icons.done_all, size: 14),
                label: const Text('Todas', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
              ),
              TextButton.icon(
                onPressed: () => context.read<SincronizarSeriesCubit>().toggleTodas(false),
                icon: const Icon(Icons.remove_done, size: 14),
                label: const Text('Ninguna', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista de diffs
        Expanded(
          child: diffs.isEmpty
              ? const Center(
                  child: Text('No hay series en este branch',
                      style: TextStyle(fontSize: 12, color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: diffs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) => _DiffRow(
                    diff: diffs[i],
                    seleccionada: state.seleccionadas[diffs[i].tipoDocumento] ?? false,
                  ),
                ),
        ),
        _Footer(state: state),
      ],
    );
  }

  String _fmtFecha(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$mi';
  }
}

class _BranchSelector extends StatelessWidget {
  final SincronizarSeriesPreviewReady state;
  const _BranchSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: state.branchIdProveedorElegido?.toString(),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            items: state.preview.branches
                .map((b) => DropdownMenuItem<String>(
                      value: b.branchIdProveedor.toString(),
                      child: Row(
                        children: [
                          Text('${b.codigo} - ${b.nombre}',
                              style: const TextStyle(fontSize: 12)),
                          if (b.esActualDeLaSede) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, size: 11, color: Colors.green),
                          ],
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              // Preserve type (number vs string)
              final match = state.preview.branches.firstWhere(
                (b) => b.branchIdProveedor.toString() == v,
                orElse: () => state.preview.branches.first,
              );
              context.read<SincronizarSeriesCubit>().cambiarBranch(match.branchIdProveedor);
            },
          ),
        ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final DiffSerie diff;
  final bool seleccionada;
  const _DiffRow({required this.diff, required this.seleccionada});

  @override
  Widget build(BuildContext context) {
    final color = _colorAccion(diff.accion);
    final label = _labelAccion(diff.accion);
    final aplicable = diff.accion.esAplicable;

    return InkWell(
      onTap: aplicable
          ? () => context.read<SincronizarSeriesCubit>().toggleSeleccion(diff.tipoDocumento)
          : null,
      onLongPress: () {
        final serie = diff.serieProveedor ?? diff.serieLocal;
        if (serie != null) {
          Clipboard.setData(ClipboardData(text: serie));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copiado: $serie'), duration: const Duration(seconds: 1)),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: seleccionada ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionada ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
            width: seleccionada ? 1.2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 22,
                  child: Switch(
                    value: seleccionada,
                    onChanged: aplicable
                        ? (_) => context
                            .read<SincronizarSeriesCubit>()
                            .toggleSeleccion(diff.tipoDocumento)
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(diff.tipoDocumentoNombre,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _SerieBlock(label: 'Local', serie: diff.serieLocal, correlativo: diff.correlativoLocal, color: Colors.grey.shade700)),
                Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade400),
                Expanded(child: _SerieBlock(label: 'Proveedor', serie: diff.serieProveedor, correlativo: diff.correlativoProveedor, color: color, alignEnd: true)),
              ],
            ),
            if (diff.mensaje != null) ...[
              const SizedBox(height: 6),
              Text(diff.mensaje!,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorAccion(AccionDiff a) {
    switch (a) {
      case AccionDiff.enSincronia:
        return Colors.green.shade700;
      case AccionDiff.actualizarCorrelativo:
        return Colors.blue.shade700;
      case AccionDiff.reemplazarSerie:
        return Colors.orange.shade800;
      case AccionDiff.crearNueva:
        return Colors.purple.shade600;
      case AccionDiff.conflicto:
        return Colors.red.shade700;
      case AccionDiff.noEmitible:
        return Colors.grey.shade600;
    }
  }

  String _labelAccion(AccionDiff a) {
    switch (a) {
      case AccionDiff.enSincronia: return 'EN SINCRONÍA';
      case AccionDiff.actualizarCorrelativo: return 'ACTUALIZAR';
      case AccionDiff.reemplazarSerie: return 'REEMPLAZAR';
      case AccionDiff.crearNueva: return 'NUEVA';
      case AccionDiff.conflicto: return 'CONFLICTO';
      case AccionDiff.noEmitible: return 'NO EMITIBLE';
    }
  }
}

class _SerieBlock extends StatelessWidget {
  final String label;
  final String? serie;
  final int? correlativo;
  final Color color;
  final bool alignEnd;

  const _SerieBlock({
    required this.label,
    required this.serie,
    required this.correlativo,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          serie ?? '—',
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800),
        ),
        if (correlativo != null)
          Text('Nº $correlativo',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final SincronizarSeriesPreviewReady state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    final puedeAplicar = state.cantidadSeleccionadas > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 10, 16, 10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Las series se actualizan sólo en esta sede. Los comprobantes ya emitidos se conservan intactos.',
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: puedeAplicar
                      ? () => context.read<SincronizarSeriesCubit>().aplicar()
                      : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Aplicar ${state.cantidadSeleccionadas} cambio${state.cantidadSeleccionadas == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

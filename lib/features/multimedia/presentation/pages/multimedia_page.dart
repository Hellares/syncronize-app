import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/multimedia_remote_datasource.dart';
import '../../data/repositories/multimedia_repository_impl.dart';
import '../../domain/entities/archivo_empresa.dart';
import '../bloc/multimedia_cubit.dart';
import '../bloc/multimedia_state.dart';

class MultimediaPage extends StatelessWidget {
  const MultimediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final empresaId = locator<LocalStorageService>().getString(StorageConstants.tenantId) ?? '';

    return BlocProvider(
      create: (_) => MultimediaCubit(
        repository: MultimediaRepositoryImpl(
          MultimediaRemoteDataSource(locator<DioClient>()),
          locator<NetworkInfo>(),
        ),
        empresaId: empresaId,
      )..loadArchivos(),
      child: const _MultimediaView(),
    );
  }
}

class _MultimediaView extends StatelessWidget {
  const _MultimediaView();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Multimedia'),
        body: BlocBuilder<MultimediaCubit, MultimediaState>(
          builder: (context, state) {
            if (state is MultimediaLoading) {
              return const Center(child: CustomLoading());
            }
            if (state is MultimediaError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(state.message, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<MultimediaCubit>().loadArchivos(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (state is MultimediaLoaded) {
              return _buildContent(context, state);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MultimediaLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<MultimediaCubit>().loadArchivos(),
      child: CustomScrollView(
        slivers: [
          // Stats header
          if (state.stats != null) SliverToBoxAdapter(child: _buildStatsHeader(state.stats!)),

          // Filtros
          SliverToBoxAdapter(child: _buildFiltros(context, state)),

          // Grid de archivos
          if (state.archivos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('No hay archivos', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < state.archivos.length) {
                      return _buildArchivoCard(context, state.archivos[index]);
                    }
                    return null;
                  },
                  childCount: state.archivos.length,
                ),
              ),
            ),

          // Load more
          if (state.page < state.totalPages)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.read<MultimediaCubit>().loadArchivos(page: state.page + 1),
                    child: const Text('Cargar mas'),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(GaleriaStats stats) {
    final porcentaje = stats.limiteMB != null && stats.limiteMB! > 0
        ? (stats.usadoMB / stats.limiteMB!).clamp(0.0, 1.0)
        : 0.0;
    final esCritico = porcentaje > 0.85;

    final usadoLabel = stats.usadoMB >= 1024
        ? '${(stats.usadoMB / 1024).toStringAsFixed(1)} GB'
        : '${stats.usadoMB} MB';
    final limiteLabel = stats.limiteMB != null
        ? (stats.limiteMB! >= 1024 ? '${(stats.limiteMB! / 1024).toStringAsFixed(0)} GB' : '${stats.limiteMB} MB')
        : 'Ilimitado';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 20, color: esCritico ? Colors.red : AppColors.blue1),
              const SizedBox(width: 8),
              Text(
                '$usadoLabel / $limiteLabel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: esCritico ? Colors.red : AppColors.blue1,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
              const Spacer(),
              Text(
                '${stats.totalArchivos} archivos',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porcentaje,
              backgroundColor: Colors.grey.shade200,
              color: esCritico ? Colors.red : AppColors.blue1,
              minHeight: 6,
            ),
          ),
          if (stats.porTipo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: stats.porTipo.map((t) {
                final icon = t.tipo == 'IMAGEN'
                    ? Icons.image_outlined
                    : t.tipo == 'VIDEO'
                        ? Icons.videocam_outlined
                        : Icons.insert_drive_file_outlined;
                return Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${t.cantidad}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${t.mb}MB)',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context, MultimediaLoaded state) {
    final filtros = [
      (null, 'Todos', Icons.apps),
      ('IMAGEN', 'Imagenes', Icons.image_outlined),
      ('VIDEO', 'Videos', Icons.videocam_outlined),
      ('PDF', 'PDF', Icons.picture_as_pdf_outlined),
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final (tipo, label, icon) = filtros[index];
          final isActive = state.filtroTipo == tipo;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              selected: isActive,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.white : Colors.grey.shade600)),
                ],
              ),
              onSelected: (_) => context.read<MultimediaCubit>().cambiarFiltro(tipo),
              selectedColor: AppColors.blue1,
              backgroundColor: Colors.white,
              side: BorderSide(color: isActive ? AppColors.blue1 : Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildArchivoCard(BuildContext context, ArchivoEmpresa archivo) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, archivo),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (archivo.esImagen)
                    CachedNetworkImage(
                      imageUrl: archivo.urlThumbnail ?? archivo.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.broken_image, color: Colors.grey.shade300),
                      ),
                    )
                  else if (archivo.esVideo)
                    Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Icon(
                          archivo.tipoArchivo == 'PDF' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          color: archivo.tipoArchivo == 'PDF' ? Colors.red.shade300 : Colors.grey.shade400,
                          size: 32,
                        ),
                      ),
                    ),
                  // Badge tamaño
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        archivo.tamanoFormateado,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archivo.entidadLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    archivo.tipoLabel,
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ArchivoEmpresa archivo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar archivo', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(archivo.nombreOriginal, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text('Tamaño: ${archivo.tamanoFormateado}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text('Pertenece a: ${archivo.entidadLabel}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(
              'Esta accion no se puede deshacer.',
              style: TextStyle(fontSize: 10, color: Colors.red.shade400),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MultimediaCubit>().deleteArchivo(archivo.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Archivo eliminado'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

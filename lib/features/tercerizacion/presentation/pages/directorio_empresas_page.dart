import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/resource.dart';
import '../../data/datasources/tercerizacion_remote_datasource.dart';
import '../../data/models/directorio_empresa_model.dart';
import '../../domain/entities/directorio_empresa.dart';
import '../../domain/usecases/buscar_empresas_usecase.dart';

class DirectorioEmpresasPage extends StatefulWidget {
  final String empresaId;
  final String? ordenOrigenId;
  final String? tipoServicioFiltro;

  const DirectorioEmpresasPage({
    super.key,
    required this.empresaId,
    this.ordenOrigenId,
    this.tipoServicioFiltro,
  });

  @override
  State<DirectorioEmpresasPage> createState() => _DirectorioEmpresasPageState();
}

class _DirectorioEmpresasPageState extends State<DirectorioEmpresasPage> {
  final _searchController = TextEditingController();
  List<DirectorioEmpresa> _empresas = [];
  List<DirectorioEmpresa> _vinculadas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });

    // Cargar vinculadas y directorio en paralelo
    await Future.wait([
      _loadVinculadas(),
      _buscar(),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadVinculadas() async {
    try {
      final ds = locator<TercerizacionRemoteDataSource>();
      final rawList = await ds.getEmpresasVinculadas();
      if (!mounted) return;
      _vinculadas = rawList
          .map((e) => DirectorioEmpresaModel.fromJson(e))
          .toList();
    } catch (_) {
      // Silently fail - vinculadas is optional
      _vinculadas = [];
    }
  }

  Future<void> _buscar({String? search}) async {
    if (!_isLoading) setState(() { _isLoading = true; _error = null; });

    final useCase = locator<BuscarEmpresasUseCase>();
    final result = await useCase(
      empresaId: widget.empresaId,
      search: search,
      tipoServicio: widget.tipoServicioFiltro,
    );

    if (!mounted) return;

    if (result is Success<DirectorioPaginado>) {
      _empresas = result.data.data;
    } else if (result is Error<DirectorioPaginado>) {
      _error = result.message;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Directorio de Empresas',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientContainer(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar empresa...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _buscar();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (v) => _buscar(search: v.trim().isNotEmpty ? v.trim() : null),
              ),
            ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CustomLoading())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: TextStyle(color: Colors.grey.shade500)),
                        )
                      : _vinculadas.isEmpty && _empresas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No se encontraron empresas',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'que acepten tercerización',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAll,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                children: [
                                  // ─── Sección vinculadas ───
                                  if (_vinculadas.isNotEmpty && _searchController.text.isEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.link, size: 16, color: Colors.teal.shade400),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Empresas Vinculadas',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.teal.shade700,
                                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ..._vinculadas.map((e) => _EmpresaDirectorioCard(
                                      empresa: e,
                                      ordenOrigenId: widget.ordenOrigenId,
                                      isVinculada: true,
                                    )),
                                    if (_empresas.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(child: Divider(color: Colors.grey.shade300)),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                'Directorio General',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                                ),
                                              ),
                                            ),
                                            Expanded(child: Divider(color: Colors.grey.shade300)),
                                          ],
                                        ),
                                      ),
                                  ],

                                  // ─── Directorio general ───
                                  ..._empresas.map((e) => _EmpresaDirectorioCard(
                                    empresa: e,
                                    ordenOrigenId: widget.ordenOrigenId,
                                  )),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmpresaDirectorioCard extends StatelessWidget {
  final DirectorioEmpresa empresa;
  final String? ordenOrigenId;
  final bool isVinculada;

  const _EmpresaDirectorioCard({
    required this.empresa,
    this.ordenOrigenId,
    this.isVinculada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isVinculada
            ? BorderSide(color: Colors.teal.shade200, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: logo + nombre + vinculada badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isVinculada ? Colors.teal : AppColors.blue1)
                      .withValues(alpha: 0.1),
                  backgroundImage:
                      empresa.logo != null ? NetworkImage(empresa.logo!) : null,
                  child: empresa.logo == null
                      ? Text(
                          empresa.nombre.isNotEmpty
                              ? empresa.nombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isVinculada ? Colors.teal : AppColors.blue1,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empresa.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (empresa.rubro != null)
                        Text(
                          empresa.rubro!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                if (isVinculada)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 10, color: Colors.teal.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'Vinculada',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Ubicación
            if (empresa.sedePrincipal != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      empresa.sedePrincipal!.ubicacionCompleta,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Contacto
            if (empresa.telefono != null) ...[
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    empresa.telefono!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Tipos de servicio
            if (empresa.tiposServicioTercerizacion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: empresa.tiposServicioTercerizacion
                    .map((tipo) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tipo.replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 9, color: AppColors.blue1),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Descripción
            if (empresa.descripcionTercerizacion != null) ...[
              const SizedBox(height: 6),
              Text(
                empresa.descripcionTercerizacion!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Botón de seleccionar
            if (ordenOrigenId != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(empresa),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(
                    isVinculada ? 'Tercerizar a empresa vinculada' : 'Seleccionar empresa',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVinculada ? Colors.teal : AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

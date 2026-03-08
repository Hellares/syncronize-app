import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/resource.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final useCase = locator<BuscarEmpresasUseCase>();
    final result = await useCase(
      empresaId: widget.empresaId,
      search: search,
      tipoServicio: widget.tipoServicioFiltro,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result is Success<DirectorioPaginado>) {
        _empresas = result.data.data;
      } else if (result is Error<DirectorioPaginado>) {
        _error = result.message;
      }
    });
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
                      : _empresas.isEmpty
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
                              onRefresh: () => _buscar(
                                  search: _searchController.text.trim().isNotEmpty
                                      ? _searchController.text.trim()
                                      : null),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _empresas.length,
                                itemBuilder: (context, index) =>
                                    _EmpresaDirectorioCard(
                                  empresa: _empresas[index],
                                  ordenOrigenId: widget.ordenOrigenId,
                                ),
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

  const _EmpresaDirectorioCard({
    required this.empresa,
    this.ordenOrigenId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: logo + nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                  backgroundImage:
                      empresa.logo != null ? NetworkImage(empresa.logo!) : null,
                  child: empresa.logo == null
                      ? Text(
                          empresa.nombre.isNotEmpty
                              ? empresa.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue1,
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

            // Botón de tercerizar
            if (ordenOrigenId != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(empresa),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Seleccionar empresa', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
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

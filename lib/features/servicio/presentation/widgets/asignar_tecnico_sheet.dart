import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../usuario/domain/entities/registro_usuario_response.dart';
import '../../../usuario/domain/entities/usuario.dart';
import '../../../usuario/domain/entities/usuario_filtros.dart';
import '../../../usuario/domain/repositories/usuario_repository.dart';

class AsignarTecnicoSheet extends StatefulWidget {
  final String empresaId;
  final String? tecnicoActualId;

  const AsignarTecnicoSheet({
    super.key,
    required this.empresaId,
    this.tecnicoActualId,
  });

  @override
  State<AsignarTecnicoSheet> createState() => _AsignarTecnicoSheetState();
}

class _AsignarTecnicoSheetState extends State<AsignarTecnicoSheet> {
  List<Usuario> _tecnicos = [];
  List<Usuario> _filteredTecnicos = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTecnicos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTecnicos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = locator<UsuarioRepository>();
    final result = await repo.getUsuarios(
      empresaId: widget.empresaId,
      filtros: const UsuarioFiltros(
        limit: 100,
        rol: RolUsuario.tecnico,
        isActive: true,
      ),
    );

    if (!mounted) return;

    if (result is Success<UsuariosPaginados>) {
      _tecnicos = result.data.data;
      _filteredTecnicos = _tecnicos;
    } else if (result is Error<UsuariosPaginados>) {
      _error = result.message;
    }

    setState(() => _isLoading = false);
  }

  void _filterTecnicos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTecnicos = _tecnicos;
      } else {
        final q = query.toLowerCase();
        _filteredTecnicos = _tecnicos
            .where((t) => t.nombreCompleto.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Row(
              children: [
                Icon(Icons.engineering, color: AppColors.blue1, size: 20),
                SizedBox(width: 8),
                Text(
                  'Asignar tecnico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tecnico...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.blue1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              onChanged: _filterTecnicos,
            ),
            const SizedBox(height: 12),

            // List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.blue1)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Text(_error!,
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _loadTecnicos,
                          child: const Text('Reintentar')),
                    ],
                  ),
                ),
              )
            else if (_filteredTecnicos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No hay tecnicos registrados'
                        : 'Sin resultados',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredTecnicos.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final tecnico = _filteredTecnicos[index];
                    final isSelected = tecnico.id == widget.tecnicoActualId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? AppColors.blue1 : AppColors.bluechip,
                        child: Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : AppColors.blue1,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        tecnico.nombreCompleto,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.blue1, size: 20)
                          : null,
                      onTap: () => Navigator.pop(context, tecnico),
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

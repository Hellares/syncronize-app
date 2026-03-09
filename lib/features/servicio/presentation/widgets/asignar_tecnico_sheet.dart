import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import '../../../../core/di/injection_container.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTecnicos();
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.engineering, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTitle('Asignar tecnico', fontSize: 15, color: AppColors.blue1),
                      AppLabelText(
                        '${_tecnicos.length} tecnicos disponibles',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search
            CustomSearchField(
              hintText: 'Buscar tecnico...',
              borderColor: AppColors.blue1,
              onChanged: _filterTecnicos,
            ),
            const SizedBox(height: 10),

            // Content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.blue1)),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_filteredTecnicos.isEmpty)
              _buildEmptyState()
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: _filteredTecnicos.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final tecnico = _filteredTecnicos[index];
                    final isSelected = tecnico.id == widget.tecnicoActualId;
                    return _buildTecnicoTile(tecnico, isSelected);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTecnicoTile(Usuario tecnico, bool isSelected) {
    return InkWell(
      onTap: () => Navigator.pop(context, tecnico),
      child: Container(
        color: isSelected ? AppColors.blue1.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.blue1
                    : AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getInitials(tecnico.nombreCompleto),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.blue1,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tecnico.nombreCompleto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.blue1 : Colors.grey.shade800,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  if (tecnico.email != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      tecnico.email!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.blue1, size: 16)
            else
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No hay tecnicos disponibles',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 36, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _loadTecnicos,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: AppColors.blue1),
                    SizedBox(width: 4),
                    Text('Reintentar',
                        style: TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}

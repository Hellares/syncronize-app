import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import '../theme/app_colors.dart';
import '../fonts/app_text_widgets.dart';
import '../widgets/custom_search_field.dart';
import '../utils/resource.dart';
import '../../features/proveedor/domain/entities/proveedor.dart';
import '../../features/proveedor/domain/usecases/get_proveedores_usecase.dart';

/// Resultado de la selección de un proveedor
class ProveedorSelectionResult {
  final String proveedorId;
  final String nombre;
  final String numeroDocumento;
  final String? telefono;
  final String? email;

  const ProveedorSelectionResult({
    required this.proveedorId,
    required this.nombre,
    required this.numeroDocumento,
    this.telefono,
    this.email,
  });
}

/// Widget reutilizable de campo selector de proveedor.
///
/// Muestra el proveedor seleccionado y al tocar abre un bottom sheet
/// con búsqueda para seleccionar uno.
///
/// Uso:
/// ```dart
/// CustomProveedorSelector(
///   empresaId: empresaId,
///   proveedorId: _proveedorId,
///   proveedorNombre: _proveedorNombre,
///   onSelected: (result) {
///     setState(() {
///       _proveedorId = result.proveedorId;
///       _proveedorNombre = result.nombre;
///     });
///   },
///   onCleared: () {
///     setState(() {
///       _proveedorId = null;
///       _proveedorNombre = null;
///     });
///   },
/// )
/// ```
class CustomProveedorSelector extends StatelessWidget {
  final String empresaId;
  final String? proveedorId;
  final String? proveedorNombre;
  final ValueChanged<ProveedorSelectionResult> onSelected;
  final VoidCallback? onCleared;
  final bool enabled;
  final String label;

  const CustomProveedorSelector({
    super.key,
    required this.empresaId,
    this.proveedorId,
    this.proveedorNombre,
    required this.onSelected,
    this.onCleared,
    this.enabled = true,
    this.label = 'Proveedor',
  });

  Future<void> _openSelector(BuildContext context) async {
    final result = await _ProveedorSearchBottomSheet.show(
      context: context,
      empresaId: empresaId,
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = proveedorId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? () => _openSelector(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: !enabled
                    ? Colors.grey.shade300
                    : hasValue
                        ? AppColors.blue1
                        : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(8),
              color: !enabled ? Colors.grey.shade100 : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: hasValue
                      ? (!enabled ? Colors.grey[500] : AppColors.blue1)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasValue
                      ? Text(
                          proveedorNombre ?? proveedorId!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: !enabled ? Colors.grey[600] : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'Seleccionar proveedor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                ),
                if (enabled)
                  hasValue && onCleared != null
                      ? GestureDetector(
                          onTap: onCleared,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                        )
                      : Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey[500],
                        ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Sheet interno ───

class _ProveedorSearchBottomSheet extends StatefulWidget {
  final String empresaId;

  const _ProveedorSearchBottomSheet({required this.empresaId});

  static Future<ProveedorSelectionResult?> show({
    required BuildContext context,
    required String empresaId,
  }) {
    return showModalBottomSheet<ProveedorSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProveedorSearchBottomSheet(empresaId: empresaId),
    );
  }

  @override
  State<_ProveedorSearchBottomSheet> createState() =>
      _ProveedorSearchBottomSheetState();
}

class _ProveedorSearchBottomSheetState
    extends State<_ProveedorSearchBottomSheet> {
  final _searchController = TextEditingController();
  final _getProveedoresUseCase = locator<GetProveedoresUseCase>();

  List<Proveedor> _proveedores = [];
  List<Proveedor> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProveedores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _getProveedoresUseCase(
      empresaId: widget.empresaId,
    );

    if (!mounted) return;

    if (result is Success<List<Proveedor>>) {
      setState(() {
        _proveedores = result.data.where((p) => p.isActive).toList();
        _filtered = _proveedores;
        _isLoading = false;
      });
    } else if (result is Error<List<Proveedor>>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _proveedores);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filtered = _proveedores.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.codigo.toLowerCase().contains(q) ||
            p.numeroDocumento.contains(q) ||
            (p.nombreComercial?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  ProveedorSelectionResult _resultFrom(Proveedor p) {
    return ProveedorSelectionResult(
      proveedorId: p.id,
      nombre: p.nombre,
      numeroDocumento: p.numeroDocumento,
      telefono: p.telefono,
      email: p.email,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          _buildHeader(),
          const Divider(height: 1),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Buscar por nombre, RUC o código...',
              onChanged: _onSearch,
            ),
          ),
          // Body
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.blue1,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const AppSubtitle(
            'SELECCIONAR PROVEEDOR',
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadProveedores,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No se encontraron proveedores',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Intenta con otro término de búsqueda'
                    : 'Registra proveedores desde el módulo de Proveedores',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final proveedor = _filtered[index];
        return _buildProveedorTile(proveedor);
      },
    );
  }

  Widget _buildProveedorTile(Proveedor proveedor) {
    return InkWell(
      onTap: () => Navigator.pop(context, _resultFrom(proveedor)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blueborder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Iniciales
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bluechip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  proveedor.iniciales,
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    proveedor.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${proveedor.tipoDocumento.name}: ${proveedor.numeroDocumento}  •  ${proveedor.codigo}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

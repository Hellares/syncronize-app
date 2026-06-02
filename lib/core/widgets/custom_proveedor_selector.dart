import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import '../theme/app_colors.dart';
import '../fonts/app_text_widgets.dart';
import '../widgets/custom_search_field.dart';
import '../../features/auth/presentation/widgets/custom_text.dart';
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
class CustomProveedorSelector extends StatefulWidget {
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

  @override
  State<CustomProveedorSelector> createState() =>
      _CustomProveedorSelectorState();
}

class _CustomProveedorSelectorState extends State<CustomProveedorSelector> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.proveedorNombre ?? '');
  }

  @override
  void didUpdateWidget(CustomProveedorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proveedorNombre != widget.proveedorNombre) {
      // didUpdateWidget corre durante el build del padre. Mutar el controller
      // aquí notifica al TextFormField interno, que llama setState en el Form
      // ancestro durante el build → "setState during build". Lo diferimos al
      // siguiente frame.
      final text = widget.proveedorNombre ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text != text) {
          _controller.text = text;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSelector() async {
    final result = await _ProveedorSearchBottomSheet.show(
      context: context,
      empresaId: widget.empresaId,
    );
    if (result != null) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.proveedorId != null;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // El campo se ve y se siente como un CustomText. AbsorbPointer evita
        // que tome foco/teclado; el tap lo captura el GestureDetector y abre
        // el bottom sheet.
        GestureDetector(
          onTap: widget.enabled ? _openSelector : null,
          child: AbsorbPointer(
            child: CustomText(
              controller: _controller,
              label: widget.label,
              hintText: 'Seleccionar proveedor',
              readOnly: true,
              enabled: widget.enabled,
              borderColor: AppColors.blue1,
              prefixIcon:
                  const Icon(Icons.local_shipping_outlined, size: 16),
              // Reserva espacio a la derecha: lupa si no hay valor, o hueco
              // para la X de limpiar (que va superpuesta y sí es tappable).
              suffixIcon: hasValue
                  ? const SizedBox(width: 18)
                  : const Icon(Icons.search, size: 18),
            ),
          ),
        ),
        if (hasValue && widget.enabled && widget.onCleared != null)
          Padding(
            // Alinea con el label de arriba (el CustomText añade ~11px de
            // label + gap, así que bajamos un poco la X para centrarla en
            // el campo).
            padding: const EdgeInsets.only(right: 8, top: 11),
            child: GestureDetector(
              onTap: widget.onCleared,
              child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
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
      // Altura fija al 70% de la pantalla.
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Expanded(child: _buildBody()),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final proveedor = _filtered[index];
        return _buildProveedorTile(proveedor);
      },
    );
  }

  Widget _buildProveedorTile(Proveedor proveedor) {
    return InkWell(
      onTap: () => Navigator.pop(context, _resultFrom(proveedor)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Iniciales
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bluechip,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Center(
                child: Text(
                  proveedor.iniciales,
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${proveedor.tipoDocumento.name}: ${proveedor.numeroDocumento}  •  ${proveedor.codigo}',
                    style: TextStyle(
                      fontSize: 9,
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

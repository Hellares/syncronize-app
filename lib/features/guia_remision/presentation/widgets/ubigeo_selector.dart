import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../data/datasources/guia_remision_remote_datasource.dart';

/// Widget selector cascada: Departamento → Provincia → Distrito → ubigeo automático
class UbigeoSelector extends StatefulWidget {
  final String? initialUbigeo;
  final TextEditingController ubigeoController;
  final ValueChanged<String>? onUbigeoSelected;
  final String label;

  const UbigeoSelector({
    super.key,
    this.initialUbigeo,
    required this.ubigeoController,
    this.onUbigeoSelected,
    this.label = 'Ubicación',
  });

  @override
  State<UbigeoSelector> createState() => _UbigeoSelectorState();
}

class _UbigeoSelectorState extends State<UbigeoSelector> {
  static List<Map<String, dynamic>>? _cachedUbigeos;

  List<Map<String, dynamic>> _ubigeos = [];
  bool _loading = true;

  String? _selectedDepto;
  String? _selectedProv;
  String? _selectedDist;

  List<String> _departamentos = [];
  List<String> _provincias = [];
  List<String> _distritos = [];

  @override
  void initState() {
    super.initState();
    _loadUbigeos();
  }

  Future<void> _loadUbigeos() async {
    if (_cachedUbigeos != null) {
      _ubigeos = _cachedUbigeos!;
      _initFromData();
      return;
    }

    try {
      final ds = locator<GuiaRemisionRemoteDatasource>();
      final data = await ds.getUbigeos();
      _cachedUbigeos = data;
      _ubigeos = data;
      if (mounted) _initFromData();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initFromData() {
    _departamentos = _ubigeos
        .map((u) => u['departamento'] as String)
        .toSet()
        .toList()
      ..sort();

    if (widget.initialUbigeo != null && widget.initialUbigeo!.length == 6) {
      final match = _ubigeos.where((u) => u['ubigeo'] == widget.initialUbigeo).toList();
      if (match.isNotEmpty) {
        _selectedDepto = match.first['departamento'] as String;
        _updateProvincias();
        _selectedProv = match.first['provincia'] as String;
        _updateDistritos();
        _selectedDist = match.first['distrito'] as String;
      }
    }

    setState(() => _loading = false);
  }

  void _updateProvincias() {
    _provincias = _ubigeos
        .where((u) => u['departamento'] == _selectedDepto)
        .map((u) => u['provincia'] as String)
        .toSet()
        .toList()
      ..sort();
    _selectedProv = null;
    _selectedDist = null;
    _distritos = [];
  }

  void _updateDistritos() {
    _distritos = _ubigeos
        .where((u) =>
            u['departamento'] == _selectedDepto &&
            u['provincia'] == _selectedProv)
        .map((u) => u['distrito'] as String)
        .toSet()
        .toList()
      ..sort();
    _selectedDist = null;
  }

  void _onDistritoSelected(String? distrito) {
    _selectedDist = distrito;
    final match = _ubigeos.where((u) =>
        u['departamento'] == _selectedDepto &&
        u['provincia'] == _selectedProv &&
        u['distrito'] == distrito).toList();

    if (match.isNotEmpty) {
      final ubigeo = match.first['ubigeo'] as String;
      widget.ubigeoController.text = ubigeo;
      widget.onUbigeoSelected?.call(ubigeo);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown<String>(
          label: 'Departamento',
          hintText: 'Seleccione departamento',
          value: _selectedDepto,
          borderColor: AppColors.blue1,
          dropdownStyle: DropdownStyle.searchable,
          items: _departamentos.map((d) => DropdownItem(value: d, label: d)).toList(),
          onChanged: (v) {
            setState(() {
              _selectedDepto = v;
              _updateProvincias();
              widget.ubigeoController.clear();
            });
          },
        ),
        const SizedBox(height: 8),

        CustomDropdown<String>(
          label: 'Provincia',
          hintText: 'Seleccione provincia',
          value: _selectedProv,
          borderColor: AppColors.blue1,
          dropdownStyle: DropdownStyle.searchable,
          enabled: _selectedDepto != null,
          items: _provincias.map((p) => DropdownItem(value: p, label: p)).toList(),
          onChanged: (v) {
            setState(() {
              _selectedProv = v;
              _updateDistritos();
              widget.ubigeoController.clear();
            });
          },
        ),
        const SizedBox(height: 8),

        CustomDropdown<String>(
          label: 'Distrito',
          hintText: 'Seleccione distrito',
          value: _selectedDist,
          borderColor: AppColors.blue1,
          dropdownStyle: DropdownStyle.searchable,
          enabled: _selectedProv != null,
          items: _distritos.map((d) => DropdownItem(value: d, label: d)).toList(),
          onChanged: _onDistritoSelected,
        ),

        if (widget.ubigeoController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.blue1),
                const SizedBox(width: 4),
                AppText(
                  'Ubigeo: ${widget.ubigeoController.text}',
                  size: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

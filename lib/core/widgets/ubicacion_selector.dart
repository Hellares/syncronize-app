import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';

/// Widget selector de ubicación que carga ubicaciones registradas
/// y permite seleccionar una existente o escribir texto libre.
class UbicacionSelector extends StatefulWidget {
  final String sedeId;
  final TextEditingController controller;
  final Color? borderColor;

  const UbicacionSelector({
    super.key,
    required this.sedeId,
    required this.controller,
    this.borderColor,
  });

  @override
  State<UbicacionSelector> createState() => _UbicacionSelectorState();
}

class _UbicacionSelectorState extends State<UbicacionSelector> {
  List<Map<String, dynamic>> _ubicaciones = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  @override
  void didUpdateWidget(covariant UbicacionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sedeId != widget.sedeId) {
      _cargarUbicaciones();
    }
  }

  Future<void> _cargarUbicaciones() async {
    if (widget.sedeId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/ubicaciones-almacen/sede/${widget.sedeId}');
      if (mounted) {
        setState(() {
          _ubicaciones = (response.data as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warehouse, size: 20),
                  const SizedBox(width: 8),
                  const Text('Seleccionar ubicación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.controller.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _ubicaciones.length,
                itemBuilder: (ctx, index) {
                  final ub = _ubicaciones[index];
                  final codigo = ub['codigo'] as String;
                  final nombre = ub['nombre'] as String;
                  final tipo = ub['tipo'] as String? ?? '';
                  final isSelected = widget.controller.text == codigo;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.blue1.withValues(alpha: 0.08),
                    leading: Icon(
                      tipo == 'ZONA' ? Icons.grid_view :
                      tipo == 'PASILLO' ? Icons.swap_horiz :
                      tipo == 'ESTANTE' ? Icons.shelves :
                      tipo == 'NIVEL' ? Icons.layers :
                      Icons.inventory_2,
                      size: 20,
                      color: isSelected ? AppColors.blue1 : Colors.grey,
                    ),
                    title: Text(codigo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('$nombre${tipo.isNotEmpty ? ' • $tipo' : ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppColors.blue1, size: 20)
                        : null,
                    onTap: () {
                      widget.controller.text = codigo;
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ?? AppColors.blue1;

    if (_loading) {
      return TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Ubicación física (opcional)',
          hintText: 'Cargando ubicaciones...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 0.5),
          ),
          suffixIcon: const SizedBox(
            width: 20, height: 20,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_ubicaciones.isEmpty) {
      // No registered locations — free text
      return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: 'Ubicación física (opcional)',
          hintText: 'Ej: Pasillo 3, Estante B',
          helperText: 'No hay ubicaciones registradas',
          helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
        ),
      );
    }

    // Has registered locations — tap to open picker
    return GestureDetector(
      onTap: _showPicker,
      child: AbsorbPointer(
        child: TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Ubicación física',
            hintText: 'Toca para seleccionar...',
            helperText: '${_ubicaciones.length} ubicaciones disponibles',
            helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 0.5),
            ),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

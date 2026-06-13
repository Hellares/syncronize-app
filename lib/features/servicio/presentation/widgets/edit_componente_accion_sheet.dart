import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/orden_servicio.dart';
import '../../domain/repositories/orden_servicio_repository.dart';

/// Edita los campos de la acción de un componente ya asociado a la orden
/// (acción, costos, tiempo, resultado, observaciones, garantía, prueba). No
/// cambia el componente vinculado (para eso se quita y se agrega otro).
class EditComponenteAccionSheet extends StatefulWidget {
  final String ordenId;
  final OrdenComponente componente;
  final void Function(OrdenComponente actualizado) onUpdated;

  const EditComponenteAccionSheet({
    super.key,
    required this.ordenId,
    required this.componente,
    required this.onUpdated,
  });

  @override
  State<EditComponenteAccionSheet> createState() =>
      _EditComponenteAccionSheetState();
}

class _EditComponenteAccionSheetState extends State<EditComponenteAccionSheet> {
  bool _isSubmitting = false;
  late String _tipoAccion;
  late bool _pruebaRealizada;

  late final TextEditingController _descripcionController;
  late final TextEditingController _costoAccionController;
  late final TextEditingController _tiempoAccionController;
  late final TextEditingController _costoRepuestosController;
  late final TextEditingController _resultadoAccionController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _garantiaMesesController;

  static const _tiposAccion = [
    'DIAGNOSTICAR',
    'REPARAR',
    'REEMPLAZAR',
    'COMPRAR',
    'LIMPIAR',
    'ACTUALIZAR',
    'INSTALAR',
    'DESMONTAR',
    'PROBAR',
    'CALIBRAR',
  ];

  static const _tipoAccionLabels = {
    'DIAGNOSTICAR': 'Diagnosticar',
    'REPARAR': 'Reparar',
    'REEMPLAZAR': 'Reemplazar',
    'COMPRAR': 'Comprar (repuesto)',
    'LIMPIAR': 'Limpiar',
    'ACTUALIZAR': 'Actualizar',
    'INSTALAR': 'Instalar',
    'DESMONTAR': 'Desmontar',
    'PROBAR': 'Probar',
    'CALIBRAR': 'Calibrar',
  };

  static const _tipoAccionIcons = {
    'DIAGNOSTICAR': Icons.search,
    'REPARAR': Icons.build,
    'REEMPLAZAR': Icons.swap_horiz,
    'COMPRAR': Icons.shopping_cart_outlined,
    'LIMPIAR': Icons.cleaning_services,
    'ACTUALIZAR': Icons.system_update,
    'INSTALAR': Icons.install_desktop,
    'DESMONTAR': Icons.handyman,
    'PROBAR': Icons.science,
    'CALIBRAR': Icons.tune,
  };

  @override
  void initState() {
    super.initState();
    final c = widget.componente;
    _tipoAccion = _tiposAccion.contains(c.tipoAccion)
        ? c.tipoAccion
        : 'DIAGNOSTICAR';
    _pruebaRealizada = c.pruebaRealizada;
    _descripcionController =
        TextEditingController(text: c.descripcionAccion ?? '');
    _costoAccionController = TextEditingController(
        text: c.costoAccion != null ? _fmt(c.costoAccion!) : '');
    _tiempoAccionController =
        TextEditingController(text: c.tiempoAccion?.toString() ?? '');
    _costoRepuestosController = TextEditingController(
        text: c.costoRepuestos != null ? _fmt(c.costoRepuestos!) : '');
    _resultadoAccionController =
        TextEditingController(text: c.resultadoAccion ?? '');
    _observacionesController =
        TextEditingController(text: c.observaciones ?? '');
    _garantiaMesesController =
        TextEditingController(text: c.garantiaMeses?.toString() ?? '');
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _descripcionController.dispose();
    _costoAccionController.dispose();
    _tiempoAccionController.dispose();
    _costoRepuestosController.dispose();
    _resultadoAccionController.dispose();
    _observacionesController.dispose();
    _garantiaMesesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    // Se envían todos los campos (null para limpiar) — el DTO backend es parcial.
    final data = <String, dynamic>{
      'tipoAccion': _tipoAccion,
      'descripcionAccion': _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      'costoAccion': double.tryParse(_costoAccionController.text.trim()),
      'tiempoAccion': int.tryParse(_tiempoAccionController.text.trim()),
      'costoRepuestos': double.tryParse(_costoRepuestosController.text.trim()),
      'resultadoAccion': _resultadoAccionController.text.trim().isEmpty
          ? null
          : _resultadoAccionController.text.trim(),
      'pruebaRealizada': _pruebaRealizada,
      'observaciones': _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      'garantiaMeses': int.tryParse(_garantiaMesesController.text.trim()),
    };

    final repo = locator<OrdenServicioRepository>();
    final result = await repo.updateComponente(
      ordenId: widget.ordenId,
      componenteId: widget.componente.id,
      data: data,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<OrdenComponente>) {
      widget.onUpdated(result.data);
      Navigator.of(context).pop();
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre =
        widget.componente.componente?.displayName ?? widget.componente.componenteId;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: AppColors.blue1, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppTitle('Editar acción',
                                  fontSize: 15, color: AppColors.blue1),
                              AppLabelText(nombre,
                                  fontSize: 10,
                                  color: Colors.grey,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                size: 20, color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    CustomDropdown<String>(
                      label: 'Acción a realizar',
                      hintText: 'Selecciona una acción',
                      value: _tipoAccion,
                      items: _tiposAccion
                          .map((a) => DropdownItem<String>(
                                value: a,
                                label: _tipoAccionLabels[a] ?? a,
                                leading: Icon(
                                  _tipoAccionIcons[a] ?? Icons.build,
                                  size: 16,
                                  color: AppColors.blue1,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tipoAccion = v);
                      },
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      controller: _descripcionController,
                      label: 'Descripción (opcional)',
                      hintText: 'Detalle de lo que se debe hacer...',
                      maxLines: 2,
                      height: null,
                      prefixIcon:
                          const Icon(Icons.description_outlined, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            controller: _costoAccionController,
                            label: 'Costo acción',
                            hintText: '0.00',
                            prefixText: 'S/ ',
                            keyboardType: TextInputType.number,
                            prefixIcon:
                                const Icon(Icons.payments_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomText(
                            controller: _tiempoAccionController,
                            label: 'Tiempo (min)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            prefixIcon:
                                const Icon(Icons.timer_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            controller: _costoRepuestosController,
                            label: 'Repuestos / compra',
                            hintText: '0.00',
                            prefixText: 'S/ ',
                            keyboardType: TextInputType.number,
                            prefixIcon:
                                const Icon(Icons.build_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomText(
                            controller: _garantiaMesesController,
                            label: 'Garantía (meses)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            prefixIcon:
                                const Icon(Icons.shield_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      controller: _resultadoAccionController,
                      label: 'Resultado (opcional)',
                      hintText: 'Detalle del resultado...',
                      maxLines: 2,
                      height: null,
                      prefixIcon:
                          const Icon(Icons.check_circle_outline, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      controller: _observacionesController,
                      label: 'Observaciones (opcional)',
                      hintText: 'Notas adicionales...',
                      maxLines: 2,
                      height: null,
                      prefixIcon: const Icon(Icons.notes, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),
                    const SizedBox(height: 10),
                    CustomSwitchTile(
                      title: 'Prueba realizada',
                      subtitle: 'Se realizó prueba del componente',
                      value: _pruebaRealizada,
                      onChanged: (v) => setState(() => _pruebaRealizada = v),
                      activeTrackColor: AppColors.blue1,
                    ),
                  ],
                ),
              ),
              // Footer fijo: botón guardar, sube con el teclado.
              AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                            color: Colors.grey.shade200, width: 0.8),
                      ),
                    ),
                    child: CustomButton(
                      text: _isSubmitting ? 'Guardando...' : 'Guardar cambios',
                      onPressed: _isSubmitting ? null : _submit,
                      backgroundColor: AppColors.blue1,
                      borderColor: AppColors.blue1,
                      textColor: Colors.white,
                      width: double.infinity,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

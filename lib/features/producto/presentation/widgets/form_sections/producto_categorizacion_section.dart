import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/custom_dropdown.dart';
import '../../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import '../../../../catalogo/presentation/bloc/marcas_empresa/marcas_empresa_state.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../../empresa/presentation/widgets/unidad_medida_dropdown.dart';

/// Sección de categorización del producto
/// Contiene: categoría, marca, sede y unidad de medida
class ProductoCategorizacionSection extends StatelessWidget {
  final String? selectedCategoriaId;
  final String? selectedMarcaId;
  final List<String> selectedSedesIds;
  final String? selectedUnidadMedidaId;
  final bool isEditing;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onMarcaChanged;
  final ValueChanged<List<String>> onSedesChanged;
  final ValueChanged<String?> onUnidadMedidaChanged;

  const ProductoCategorizacionSection({
    super.key,
    this.selectedCategoriaId,
    this.selectedMarcaId,
    required this.selectedSedesIds,
    this.selectedUnidadMedidaId,
    required this.isEditing,
    required this.onCategoriaChanged,
    required this.onMarcaChanged,
    required this.onSedesChanged,
    required this.onUnidadMedidaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('CATEGORIZACIÓN'),
          const SizedBox(height: 12),
          _buildCategoriaDropdown(),
          const SizedBox(height: 16),
          _buildMarcaDropdown(),
          const SizedBox(height: 16),
          _buildSedeDropdown(),
          const SizedBox(height: 16),
          _buildUnidadMedidaDropdown(),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        if (state is CategoriasEmpresaLoaded) {
          return CustomDropdown<String>(
            label: 'Categoría',
            hintText: 'Selecciona una categoría',
            borderColor: AppColors.blue1,
            value: selectedCategoriaId,
            prefixIcon: const Icon(
              Icons.category_outlined,
              size: 16,
              color: AppColors.blue1,
            ),
            items: state.categorias.map((cat) {
              return DropdownItem(
                value: cat.id,
                label: cat.nombreDisplay,
              );
            }).toList(),
            onChanged: onCategoriaChanged,
          );
        }
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildMarcaDropdown() {
    return BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
      builder: (context, state) {
        if (state is MarcasEmpresaLoaded) {
          return CustomDropdown<String>(
            label: 'Marca',
            hintText: 'Selecciona una marca',
            borderColor: AppColors.blue1,
            value: selectedMarcaId,
            prefixIcon: const Icon(
              Icons.local_offer_outlined,
              size: 16,
              color: AppColors.blue1,
            ),
            items: state.marcas.map((marca) {
              return DropdownItem(
                value: marca.id,
                label: marca.nombreDisplay,
              );
            }).toList(),
            onChanged: onMarcaChanged,
          );
        }
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildSedeDropdown() {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, state) {
        if (state is EmpresaContextLoaded) {
          final sedesActivas = state.context.sedes
              .where((sede) => sede.isActive)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomDropdown<String>(
                label: 'Sede(s) *',
                hintText: isEditing
                    ? 'Sedes donde existe el producto'
                    : 'Selecciona una o más sedes donde se creará el producto',
                borderColor: AppColors.blue1,
                dropdownStyle: DropdownStyle.multiSelect,
                selectedValues: selectedSedesIds,
                enabled: !isEditing, // Deshabilitar en modo edición
                prefixIcon: Icon(
                  isEditing ? Icons.info_outline : Icons.business,
                  size: 16,
                  color: AppColors.blue1,
                ),
                items: sedesActivas.map((sede) {
                  return DropdownItem(
                    value: sede.id,
                    label: sede.nombre + (sede.esPrincipal ? ' (Principal)' : ''),
                  );
                }).toList(),
                onMultiChanged: onSedesChanged,
                validator: (value) {
                  if (value == null || (value is List && value.isEmpty)) {
                    return 'Debe seleccionar al menos una sede';
                  }
                  return null;
                },
              ),
              if (isEditing && selectedSedesIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppSubtitle(
                          'Este producto existe en ${selectedSedesIds.length} sede(s). Los cambios en datos generales se aplicarán a todas. Para cambiar precios o stock, usa la gestión de inventario.',
                          fontSize: 10,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildUnidadMedidaDropdown() {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, state) {
        if (state is EmpresaContextLoaded) {
          return UnidadMedidaDropdown(
            empresaId: state.context.empresa.id,
            selectedUnidadId: selectedUnidadMedidaId,
            onChanged: onUnidadMedidaChanged,
            labelText: 'Unidad de medida',
            hintText: 'Selecciona la unidad',
            autoSelectDefault: !isEditing,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 35,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
      ),
    );
  }
}

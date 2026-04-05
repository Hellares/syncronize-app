import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import '../../domain/entities/regla_compatibilidad.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../bloc/compatibilidad/compatibilidad_cubit.dart';

class ReglaCompatibilidadDialog extends StatefulWidget {
  final ReglaCompatibilidad? regla;

  const ReglaCompatibilidadDialog({super.key, this.regla});

  @override
  State<ReglaCompatibilidadDialog> createState() =>
      _ReglaCompatibilidadDialogState();
}

class _ReglaCompatibilidadDialogState extends State<ReglaCompatibilidadDialog> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  int _currentStep = 0;

  String? _categoriaOrigenId;
  String? _categoriaDestinoId;
  String? _atributoOrigenClave;
  String _tipoValidacion = 'IGUAL';

  bool _nombreAutoGenerado = true;

  bool get _isEditing => widget.regla != null;

  bool get _canAdvance => switch (_currentStep) {
    0 => _categoriaOrigenId != null && _categoriaDestinoId != null,
    1 => _atributoOrigenClave != null,
    2 => _nombreController.text.trim().isNotEmpty,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final regla = widget.regla!;
      _nombreController.text = regla.nombre;
      _descripcionController.text = regla.descripcion ?? '';
      _categoriaOrigenId = regla.categoriaOrigenId;
      _categoriaDestinoId = regla.categoriaDestinoId;
      _atributoOrigenClave = regla.atributoOrigenClave;
      _tipoValidacion = regla.tipoValidacion;
      _nombreAutoGenerado = false;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.link, color: AppColors.blue1, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Editar Regla de Compatibilidad'
                          : 'Nueva Regla de Compatibilidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily:
                            AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Categorias', Icons.category),
                  _buildStepConnector(0),
                  _buildStepIndicator(1, 'Atributo', Icons.tune),
                  _buildStepConnector(1),
                  _buildStepIndicator(2, 'Confirmar', Icons.check_circle),
                ],
              ),
            ),

            const Divider(height: 1),

            // Step content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_currentStep) {
                    0 => _buildPaso1(),
                    1 => _buildPaso2(),
                    2 => _buildPaso3(),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),

            const Divider(height: 1),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.blue1),
                        ),
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _currentStep < 2
                        ? ElevatedButton(
                            onPressed: _canAdvance
                                ? () => setState(() => _currentStep++)
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.blue1,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Siguiente'),
                          )
                        : ElevatedButton(
                            onPressed: _canAdvance ? _guardar : null,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.blue1,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                                _isEditing ? 'Actualizar regla' : 'Crear regla'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step indicator widgets
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                      ? AppColors.blue1
                      : Colors.grey[300],
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.blue1 : Colors.grey[600],
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? Colors.green : Colors.grey[300],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 1: Seleccionar categorias
  // ---------------------------------------------------------------------------

  Widget _buildPaso1() {
    return Column(
      key: const ValueKey('paso1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona las categorias',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige las dos categorias de productos que deben ser compatibles entre si',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        const Text('Primera categoria',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        _buildCategoriaDropdown(
          value: _categoriaOrigenId,
          onChanged: (v) => setState(() => _categoriaOrigenId = v),
        ),
        const SizedBox(height: 16),

        const Text('Segunda categoria',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        _buildCategoriaDropdown(
          value: _categoriaDestinoId,
          onChanged: (v) => setState(() => _categoriaDestinoId = v),
        ),

        // Vista previa visual
        if (_categoriaOrigenId != null && _categoriaDestinoId != null) ...[
          const SizedBox(height: 20),
          _buildPreviewCategorias(),
        ],
      ],
    );
  }

  Widget _buildPreviewCategorias() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        final categorias =
            state is CategoriasEmpresaLoaded ? state.categorias : [];
        final nombreOrigen = categorias
            .where((c) => c.id == _categoriaOrigenId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';
        final nombreDestino = categorias
            .where((c) => c.id == _categoriaDestinoId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.blue1.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryChip(nombreOrigen),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '\u2194',
                  style: TextStyle(
                      fontSize: 20, color: AppColors.blue1),
                ),
              ),
              _buildCategoryChip(nombreDestino),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.blue1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 2: Seleccionar atributo
  // ---------------------------------------------------------------------------

  Widget _buildPaso2() {
    return Column(
      key: const ValueKey('paso2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el atributo a comparar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige el atributo que ambas categorias deben tener en comun para validar compatibilidad',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        const Text('Atributo',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        _buildAtributoDropdown(),
        const SizedBox(height: 20),

        // Tipo de validacion
        const Text('Tipo de validacion',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        _buildTipoValidacionSelector(),

        // Preview del atributo seleccionado
        if (_atributoOrigenClave != null) ...[
          const SizedBox(height: 20),
          _buildPreviewAtributo(),
        ],
      ],
    );
  }

  Widget _buildTipoValidacionSelector() {
    return Column(
      children: [
        _buildTipoOption(
          value: 'IGUAL',
          icon: Icons.compare_arrows,
          title: 'Igual',
          description:
              'Los valores deben ser exactamente iguales (ej: AM5 = AM5)',
        ),
        const SizedBox(height: 8),
        _buildTipoOption(
          value: 'INCLUYE_EN',
          icon: Icons.list,
          title: 'Incluye en',
          description:
              'Definir manualmente que valores son compatibles',
        ),
      ],
    );
  }

  Widget _buildTipoOption({
    required String value,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _tipoValidacion == value;
    return InkWell(
      onTap: () => setState(() => _tipoValidacion = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.blue1 : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.blue1.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? AppColors.blue1 : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? AppColors.blue1 : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.blue1, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAtributo() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, catState) {
        final categorias =
            catState is CategoriasEmpresaLoaded ? catState.categorias : [];
        final nombreOrigen = categorias
            .where((c) => c.id == _categoriaOrigenId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';
        final nombreDestino = categorias
            .where((c) => c.id == _categoriaDestinoId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontFamily:
                    AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
              children: [
                const TextSpan(text: 'El valor de '),
                TextSpan(
                  text: _atributoOrigenClave,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' en $nombreOrigen debe coincidir con '),
                TextSpan(
                  text: _atributoOrigenClave,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' en $nombreDestino'),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 3: Confirmar
  // ---------------------------------------------------------------------------

  Widget _buildPaso3() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, catState) {
        final categorias =
            catState is CategoriasEmpresaLoaded ? catState.categorias : [];
        final nombreOrigen = categorias
            .where((c) => c.id == _categoriaOrigenId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';
        final nombreDestino = categorias
            .where((c) => c.id == _categoriaDestinoId)
            .map((c) => c.nombreDisplay)
            .firstOrNull ?? '';

        return Column(
          key: const ValueKey('paso3'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirma la regla',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Revisa los datos y crea la regla de compatibilidad',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Nombre
            const Text('Nombre de la regla *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: Socket CPU compatible',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) {
                _nombreAutoGenerado = false;
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // Descripcion
            const Text('Descripcion (opcional)',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Resumen visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Resumen',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$nombreOrigen ($_atributoOrigenClave)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tipoValidacion == 'IGUAL'
                              ? '\u2195 debe ser IGUAL'
                              : '\u2195 INCLUYE EN',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$nombreDestino ($_atributoOrigenClave)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Shared dropdown builders
  // ---------------------------------------------------------------------------

  Widget _buildCategoriaDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        final categorias =
            state is CategoriasEmpresaLoaded ? state.categorias : [];

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione una categoria',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: categorias.map((cat) {
            return DropdownMenuItem<String>(
              value: cat.id,
              child: Text(
                cat.nombreDisplay,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildAtributoDropdown() {
    return BlocBuilder<ProductoAtributoCubit, ProductoAtributoState>(
      builder: (context, state) {
        final todosAtributos =
            state is ProductoAtributoLoaded ? state.atributos : <ProductoAtributo>[];

        // Filtrar atributos que apliquen a AMBAS categorias seleccionadas, o sean globales
        final atributosFiltrados = todosAtributos.where((attr) {
          if (attr.categoriaIds.isEmpty) return true; // global
          if (_categoriaOrigenId == null || _categoriaDestinoId == null) return true;
          return attr.categoriaIds.contains(_categoriaOrigenId) &&
              attr.categoriaIds.contains(_categoriaDestinoId);
        }).toList();

        // Eliminar duplicados por clave (mostrar uno por clave)
        final clavesVistas = <String>{};
        final atributosUnicos = <ProductoAtributo>[];
        for (final attr in atributosFiltrados) {
          if (clavesVistas.add(attr.clave)) {
            atributosUnicos.add(attr);
          }
        }
        atributosUnicos.sort((a, b) => a.nombre.compareTo(b.nombre));

        final valorActual =
            atributosUnicos.any((a) => a.clave == _atributoOrigenClave)
                ? _atributoOrigenClave
                : null;

        return DropdownButtonFormField<String>(
          value: valorActual,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione un atributo',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: atributosUnicos.map((attr) {
            return DropdownMenuItem<String>(
              value: attr.clave,
              child: Text(
                '${attr.nombre} (${attr.clave})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _atributoOrigenClave = v;
              // Auto-generar nombre
              if (_nombreAutoGenerado || _nombreController.text.isEmpty) {
                final attr = atributosUnicos
                    .where((a) => a.clave == v)
                    .firstOrNull;
                if (attr != null) {
                  _nombreController.text = '${attr.nombre} compatible';
                  _nombreAutoGenerado = true;
                }
              }
            });
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Guardar
  // ---------------------------------------------------------------------------

  void _guardar() {
    if (_nombreController.text.trim().isEmpty) return;

    final data = <String, dynamic>{
      'nombre': _nombreController.text.trim(),
      if (_descripcionController.text.isNotEmpty)
        'descripcion': _descripcionController.text.trim(),
      'atributoOrigenClave': _atributoOrigenClave,
      'categoriaOrigenId': _categoriaOrigenId,
      'atributoDestinoClave': _atributoOrigenClave,
      'categoriaDestinoId': _categoriaDestinoId,
      'tipoValidacion': _tipoValidacion,
    };

    final cubit = context.read<CompatibilidadCubit>();

    if (_isEditing) {
      cubit.actualizarRegla(widget.regla!.id, data);
    } else {
      cubit.crearRegla(data);
    }

    Navigator.of(context).pop();
  }
}

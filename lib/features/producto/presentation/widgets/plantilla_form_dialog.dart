import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/storage/secure_storage_service.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Diálogo para crear o editar una plantilla de atributos.
/// Estilo unificado con el lenguaje del app (mismo que ConfigurarPreciosDialog).
class PlantillaFormDialog extends StatefulWidget {
  final AtributoPlantilla? plantilla; // null = crear, no-null = editar
  final String empresaId;

  const PlantillaFormDialog({
    super.key,
    this.plantilla,
    required this.empresaId,
  });

  @override
  State<PlantillaFormDialog> createState() => _PlantillaFormDialogState();
}

class _PlantillaFormDialogState extends State<PlantillaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _icono;
  String? _categoriaId;
  List<_AtributoSeleccionado> _atributosSeleccionados = [];
  String? _currentEmpresaId;

  bool get _esEdicion => widget.plantilla != null;

  @override
  void initState() {
    super.initState();
    _currentEmpresaId = widget.empresaId;

    if (_esEdicion) {
      _nombreController.text = widget.plantilla!.nombre;
      _descripcionController.text = widget.plantilla!.descripcion ?? '';
      _icono = widget.plantilla!.icono;
      _categoriaId = widget.plantilla!.categoriaId;
      _atributosSeleccionados = widget.plantilla!.atributos
          .map((pa) => _AtributoSeleccionado(
                atributoId: pa.atributoId,
                nombre: pa.atributo.nombre,
                clave: pa.atributo.clave,
                tipo: pa.atributo.tipo,
                orden: pa.orden,
                requeridoOverride: pa.requeridoOverride,
                valoresOverride: pa.valoresOverride,
                valoresDisponibles: pa.atributo.valores,
              ))
          .toList();
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
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null &&
              _currentEmpresaId != newEmpresaId) {
            context
                .read<ProductoAtributoCubit>()
                .loadAtributos(newEmpresaId);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Diálogo cerrado: cambiaste a ${empresaState.context.empresa.nombre}'),
                backgroundColor: AppColors.blue1,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: BlocProvider(
        create: (_) => locator<ProductoAtributoCubit>()
          ..loadAtributos(widget.empresaId),
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: GradientContainer(
            gradient: AppGradients.blueWhiteDialog(),
            padding:
                const EdgeInsets.only(left: 15, right: 15, top: 10),
            borderRadius: BorderRadius.circular(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNombreField(),
                          const SizedBox(height: 12),
                          _buildDescripcionField(),
                          const SizedBox(height: 12),
                          _buildIconoPicker(),
                          const SizedBox(height: 8),
                          const Divider(),
                          _buildAtributosSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActions(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _esEdicion
                ? Icons.edit_note_outlined
                : Icons.dashboard_customize_outlined,
            color: AppColors.blue1,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTitle(_esEdicion ? 'Editar Plantilla' : 'Nueva Plantilla'),
              AppSubtitle(
                _esEdicion
                    ? widget.plantilla!.nombre
                    : 'Reutiliza un set de atributos en tus productos',
                fontSize: 10,
                color: AppColors.blue1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // CAMPOS DE FORMULARIO
  // ============================================

  Widget _buildNombreField() {
    return CustomText(
      controller: _nombreController,
      label: 'Nombre *',
      hintText: 'Ej: Motherboard, Procesador, RAM',
      borderColor: AppColors.blue1,
      prefixIcon: Icon(Icons.label_outline,
          size: 16, color: AppColors.blue1),
      autovalidateMode: AutovalidateModeX.disabled,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa un nombre';
        }
        return null;
      },
    );
  }

  Widget _buildDescripcionField() {
    return CustomText(
      controller: _descripcionController,
      label: 'Descripción',
      hintText: 'Describe para qué se usa esta plantilla',
      borderColor: AppColors.blue1,
      maxLines: 2,
    );
  }

  Widget _buildIconoPicker() {
    return InkWell(
      onTap: () => _seleccionarIcono(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.blue1.withValues(alpha: 0.25),
              width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.blue1.withValues(alpha: 0.3),
                    width: 0.6),
              ),
              child: _icono != null && _icono!.isNotEmpty
                  ? Text(_icono!, style: const TextStyle(fontSize: 18))
                  : Icon(Icons.emoji_emotions_outlined,
                      color: AppColors.blue1, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSubtitle(
                    'Ícono',
                    fontSize: 10,
                    color: AppColors.blue1,
                  ),
                  Text(
                    _icono != null && _icono!.isNotEmpty
                        ? 'Seleccionado'
                        : 'Sin ícono — toca para elegir',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SECCIÓN ATRIBUTOS
  // ============================================

  Widget _buildAtributosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_outlined,
                size: 14, color: AppColors.blue1),
            const SizedBox(width: 4),
            AppSubtitle(
              'Atributos',
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            const Spacer(),
            if (_atributosSeleccionados.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColors.blue1.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Text(
                  '${_atributosSeleccionados.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_atributosSeleccionados.isEmpty)
          _buildAtributosEmptyCard()
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reordenarAtributos,
            children: _atributosSeleccionados
                .asMap()
                .entries
                .map(
                    (entry) => _buildAtributoItem(entry.key, entry.value))
                .toList(),
          ),
        const SizedBox(height: 10),
        BlocBuilder<ProductoAtributoCubit, ProductoAtributoState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state is ProductoAtributoLoaded
                    ? () => _mostrarSelectorAtributos(
                        context, state.atributos)
                    : null,
                icon: const Icon(Icons.add, size: 16),
                label: AppSubtitle(
                  'Agregar atributo',
                  fontSize: 11,
                  color: AppColors.blue1,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 34),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                      color: AppColors.blue1.withValues(alpha: 0.4)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAtributosEmptyCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 18, color: Colors.blueGrey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aún no hay atributos. Agrega los que esta plantilla expondrá '
              'al crear productos.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtributoItem(int index, _AtributoSeleccionado atributo) {
    final tieneValores = atributo.valoresDisponibles.isNotEmpty;
    final cantidadOverride =
        atributo.valoresOverride?.length ?? atributo.valoresDisponibles.length;

    return Padding(
      key: ValueKey(atributo.atributoId),
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_indicator,
                  size: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 4),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    atributo.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          atributo.tipo,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      if (tieneValores) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$cantidadOverride/${atributo.valoresDisponibles.length} val.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (tieneValores)
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: Icon(Icons.tune,
                      size: 15, color: AppColors.blue1),
                  padding: EdgeInsets.zero,
                  tooltip: 'Configurar valores',
                  onPressed: () =>
                      _editarValoresOverride(context, index, atributo),
                ),
              ),
            InkWell(
              onTap: () {
                setState(() {
                  _atributosSeleccionados[index] = atributo.copyWith(
                    requeridoOverride:
                        !(atributo.requeridoOverride ?? false),
                  );
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: atributo.requeridoOverride ?? false,
                        onChanged: (value) {
                          setState(() {
                            _atributosSeleccionados[index] = atributo
                                .copyWith(requeridoOverride: value);
                          });
                        },
                        activeColor: AppColors.blue1,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Req.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                icon: Icon(Icons.close,
                    size: 15, color: Colors.red.shade400),
                padding: EdgeInsets.zero,
                tooltip: 'Eliminar',
                onPressed: () {
                  setState(() {
                    _atributosSeleccionados.removeAt(index);
                    _actualizarOrdenes();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACCIONES (footer)
  // ============================================

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: AppSubtitle(
            'Cancelar',
            fontSize: 12,
            color: AppColors.blue1,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue1,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: AppSubtitle(
            _esEdicion ? 'Actualizar' : 'Crear',
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================
  // LÓGICA
  // ============================================

  void _reordenarAtributos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _atributosSeleccionados.removeAt(oldIndex);
      _atributosSeleccionados.insert(newIndex, item);
      _actualizarOrdenes();
    });
  }

  void _actualizarOrdenes() {
    for (var i = 0; i < _atributosSeleccionados.length; i++) {
      _atributosSeleccionados[i] =
          _atributosSeleccionados[i].copyWith(orden: i);
    }
  }

  void _seleccionarIcono(BuildContext context) {
    final emojis = [
      '📱',
      '💻',
      '🖥️',
      '⌨️',
      '🖱️',
      '🎮',
      '🎧',
      '📷',
      '💾',
      '🔌',
      '⚡',
      '🔋',
      '📦',
      '🛠️',
      '🏷️',
    ];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: GradientContainer(
          gradient: AppGradients.blueWhiteDialog(),
          padding: const EdgeInsets.all(15),
          borderRadius: BorderRadius.circular(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.emoji_emotions_outlined,
                        color: AppColors.blue1, size: 16),
                  ),
                  const SizedBox(width: 10),
                  AppTitle('Seleccionar ícono'),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis
                    .map((emoji) => InkWell(
                          onTap: () {
                            setState(() => _icono = emoji);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.blue1
                                  .withValues(alpha: 0.05),
                              border: Border.all(
                                  color: AppColors.blue1
                                      .withValues(alpha: 0.3),
                                  width: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _icono = null);
                      Navigator.pop(context);
                    },
                    child: AppSubtitle(
                      'Sin ícono',
                      fontSize: 12,
                      color: AppColors.blue1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppSubtitle(
                      'Cancelar',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editarValoresOverride(
    BuildContext context,
    int index,
    _AtributoSeleccionado atributo,
  ) {
    final valoresActuales =
        atributo.valoresOverride ?? atributo.valoresDisponibles;
    final valoresSeleccionados = Set<String>.from(valoresActuales);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: GradientContainer(
            gradient: AppGradients.blueWhiteDialog(),
            padding: const EdgeInsets.only(
                left: 15, right: 15, top: 10),
            borderRadius: BorderRadius.circular(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune,
                          color: AppColors.blue1, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitle('Configurar valores'),
                          AppSubtitle(
                            atributo.nombre,
                            fontSize: 10,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: atributo.valoresDisponibles.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Este atributo no tiene valores predefinidos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => setDialogState(() {
                                      valoresSeleccionados.clear();
                                      valoresSeleccionados.addAll(
                                          atributo.valoresDisponibles);
                                    }),
                                    icon: const Icon(Icons.select_all,
                                        size: 14),
                                    label: AppSubtitle(
                                      'Todos',
                                      fontSize: 11,
                                      color: AppColors.blue1,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => setDialogState(() {
                                      valoresSeleccionados.clear();
                                    }),
                                    icon: const Icon(Icons.deselect,
                                        size: 14),
                                    label: AppSubtitle(
                                      'Ninguno',
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...atributo.valoresDisponibles.map((valor) {
                                final isSelected =
                                    valoresSeleccionados.contains(valor);
                                return InkWell(
                                  onTap: () => setDialogState(() {
                                    if (isSelected) {
                                      valoresSeleccionados.remove(valor);
                                    } else {
                                      valoresSeleccionados.add(valor);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (checked) =>
                                                setDialogState(() {
                                              if (checked == true) {
                                                valoresSeleccionados
                                                    .add(valor);
                                              } else {
                                                valoresSeleccionados
                                                    .remove(valor);
                                              }
                                            }),
                                            activeColor: AppColors.blue1,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            valor,
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _atributosSeleccionados[index] =
                              atributo.copyWith(valoresOverride: null);
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: AppSubtitle(
                        'Usar todos',
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: AppSubtitle(
                        'Cancelar',
                        fontSize: 12,
                        color: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (valoresSeleccionados.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Debes seleccionar al menos un valor'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          final todosSeleccionados =
                              valoresSeleccionados.length ==
                                  atributo.valoresDisponibles.length;
                          _atributosSeleccionados[index] =
                              atributo.copyWith(
                            valoresOverride: todosSeleccionados
                                ? null
                                : (valoresSeleccionados.toList()..sort()),
                          );
                        });
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      child: AppSubtitle(
                        'Aplicar',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarSelectorAtributos(
    BuildContext context,
    List<ProductoAtributo> atributosDisponibles,
  ) {
    final atributosNoSeleccionados = atributosDisponibles
        .where((a) =>
            !_atributosSeleccionados.any((s) => s.atributoId == a.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: GradientContainer(
          gradient: AppGradients.blueWhiteDialog(),
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 10),
          borderRadius: BorderRadius.circular(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_circle_outline,
                        color: AppColors.blue1, size: 16),
                  ),
                  const SizedBox(width: 10),
                  AppTitle('Seleccionar atributos'),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: atributosNoSeleccionados.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No hay más atributos disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: atributosNoSeleccionados
                              .map((atributo) => InkWell(
                                    onTap: () {
                                      setState(() {
                                        _atributosSeleccionados.add(
                                          _AtributoSeleccionado(
                                            atributoId: atributo.id,
                                            nombre: atributo.nombre,
                                            clave: atributo.clave,
                                            tipo: atributo.tipo.value,
                                            orden:
                                                _atributosSeleccionados
                                                    .length,
                                            requeridoOverride:
                                                atributo.requerido,
                                            valoresDisponibles:
                                                atributo.valores,
                                          ),
                                        );
                                      });
                                      Navigator.pop(context);
                                    },
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.blue1
                                              .withValues(alpha: 0.2),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.blue1
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.label_outline,
                                              size: 14,
                                              color: AppColors.blue1,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  atributo.nombre,
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${atributo.clave} · ${atributo.tipo.value}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey
                                                        .shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right,
                                              size: 16,
                                              color: Colors.grey.shade400),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppSubtitle(
                      'Cerrar',
                      fontSize: 12,
                      color: AppColors.blue1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final localStorage = locator<LocalStorageService>();
    final secureStorage = locator<SecureStorageService>();

    final tenantId = localStorage.getString(StorageConstants.tenantId);
    final accessToken =
        await secureStorage.read(key: StorageConstants.accessToken);

    if (!mounted) return;

    if (tenantId == null || tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Error: No hay empresa seleccionada. Por favor, selecciona una empresa primero.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Error: No estás autenticado. Por favor, inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_atributosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un atributo a la plantilla'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final atributos = _atributosSeleccionados
        .map((a) => PlantillaAtributoCreate(
              atributoId: a.atributoId,
              orden: a.orden,
              requeridoOverride: a.requeridoOverride,
              valoresOverride: a.valoresOverride,
            ))
        .toList();

    if (_esEdicion) {
      context.read<AtributoPlantillaCubit>().actualizarPlantilla(
            plantillaId: widget.plantilla!.id,
            nombre: _nombreController.text,
            descripcion: _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text,
            icono: _icono,
            categoriaId: _categoriaId,
            atributos: atributos,
          );
    } else {
      context.read<AtributoPlantillaCubit>().crearPlantilla(
            nombre: _nombreController.text,
            descripcion: _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text,
            icono: _icono,
            categoriaId: _categoriaId,
            atributos: atributos,
          );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }
}

/// Clase auxiliar para manejar atributos seleccionados.
class _AtributoSeleccionado {
  final String atributoId;
  final String nombre;
  final String clave;
  final String tipo;
  final int orden;
  final bool? requeridoOverride;
  final List<String>? valoresOverride;
  final List<String> valoresDisponibles;

  _AtributoSeleccionado({
    required this.atributoId,
    required this.nombre,
    required this.clave,
    required this.tipo,
    required this.orden,
    this.requeridoOverride,
    this.valoresOverride,
    required this.valoresDisponibles,
  });

  _AtributoSeleccionado copyWith({
    String? atributoId,
    String? nombre,
    String? clave,
    String? tipo,
    int? orden,
    bool? requeridoOverride,
    List<String>? valoresOverride,
    List<String>? valoresDisponibles,
  }) {
    return _AtributoSeleccionado(
      atributoId: atributoId ?? this.atributoId,
      nombre: nombre ?? this.nombre,
      clave: clave ?? this.clave,
      tipo: tipo ?? this.tipo,
      orden: orden ?? this.orden,
      requeridoOverride: requeridoOverride ?? this.requeridoOverride,
      valoresOverride: valoresOverride ?? this.valoresOverride,
      valoresDisponibles:
          valoresDisponibles ?? this.valoresDisponibles,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/monto_selector_slider.dart';
import 'package:syncronize/core/widgets/custom_checkbox_tile.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import '../../../../core/utils/granular_permissions_catalog.dart';
import '../../../../core/utils/rol_presets.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../../../empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;

/// Dialog para asignar rol y permisos a un usuario
class AsignarRolDialog extends StatefulWidget {
  final Usuario usuario;
  final List<SedeOption>? sedesDisponibles;
  final Future<void> Function(Map<String, dynamic>) onGuardar;
  final bool esConversion;

  const AsignarRolDialog({
    super.key,
    required this.usuario,
    this.sedesDisponibles,
    required this.onGuardar,
    this.esConversion = false,
  });

  @override
  State<AsignarRolDialog> createState() => _AsignarRolDialogState();
}

class _AsignarRolDialogState extends State<AsignarRolDialog> {
  late RolUsuario _rolSeleccionado;
  final List<String> _sedesSeleccionadas = [];
  bool _puedeAbrirCaja = false;
  bool _puedeCerrarCaja = false;
  double? _limiteCreditoVenta;
  final _limiteCreditoController = TextEditingController();
  bool _isLoading = false;
  /// IDs de accesos rápidos del dashboard ocultos para este usuario.
  final Set<String> _accesosRapidosOcultos = {};
  /// IDs de permisos granulares activos para este usuario (catálogo
  /// `granular_permissions_catalog.dart`). Persiste en
  /// `UsuarioSedeRol.permisos`.
  final Set<String> _permisosEspeciales = {};

  @override
  void initState() {
    super.initState();
    // Inicializar con el rol actual del usuario
    _rolSeleccionado = _getRolFromString(widget.usuario.rolEnEmpresa);

    // Inicializar sedes seleccionadas con las actuales del usuario
    _sedesSeleccionadas.addAll(
      widget.usuario.sedes.map((s) => s.sedeId),
    );

    // Inicializar permisos de caja si el usuario ya tiene
    if (widget.usuario.sedes.isNotEmpty) {
      _puedeAbrirCaja = widget.usuario.puedeAbrirCaja;
      _puedeCerrarCaja = widget.usuario.puedeCerrarCaja;
      // Cargar accesos ocultos del usuario (consolidados entre todas
      // las sedes — si está oculto en una, se considera oculto).
      _accesosRapidosOcultos.addAll(
        widget.usuario.sedes.expand((s) => s.accesosRapidosOcultos),
      );
      // Cargar permisos granulares (consolidados entre sedes).
      _permisosEspeciales.addAll(
        widget.usuario.sedes.expand((s) => s.permisos),
      );

      // Tomar el límite de la primera sede (asumiendo que es el mismo)
      final sedeConLimite = widget.usuario.sedes
          .where((s) => s.limiteCreditoVenta != null)
          .firstOrNull;

      final primeraSedeConLimite = sedeConLimite ?? widget.usuario.sedes.first;

      if (primeraSedeConLimite.limiteCreditoVenta != null) {
        _limiteCreditoVenta = primeraSedeConLimite.limiteCreditoVenta;
        _limiteCreditoController.text =
            primeraSedeConLimite.limiteCreditoVenta!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _limiteCreditoController.dispose();
    super.dispose();
  }

  RolUsuario _getRolFromString(String rol) {
    return RolUsuario.values.firstWhere(
      (r) => r.value == rol,
      orElse: () => RolUsuario.operador,
    );
  }

  /// Sección de accesos rápidos visibles. El admin desmarca los que NO
  /// quiere que el usuario vea en su dashboard. Por default todos están
  /// marcados (= ningún oculto). Si el usuario tenía configurado algo
  /// previo, se precarga desde `widget.usuario.sedes`.
  Widget _buildAccesosRapidosSeleccion() {
    return GradientContainer(
      borderWidth: 0.6,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      gradient: AppGradients.blueWhiteBlue(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppSubtitle('Accesos rápidos visibles', fontSize: 12),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _accesosRapidosOcultos.clear()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Marcar todos',
                    style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _accesosRapidosOcultos
                    ..clear()
                    ..addAll(AccesosRapidosCatalogo.items.map((e) => e.$1));
                }),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Desmarcar todos',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Text(
            'Marcá los accesos del dashboard que verá. Los desmarcados se '
            'ocultarán solo a este usuario, sin afectar permisos del rol.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: AccesosRapidosCatalogo.items.map((entry) {
              final id = entry.$1;
              final label = entry.$2;
              final visible = !_accesosRapidosOcultos.contains(id);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 88) / 2,
                child: CustomCheckboxTile(
                  title: label,
                  value: visible,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _accesosRapidosOcultos.remove(id);
                      } else {
                        _accesosRapidosOcultos.add(id);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Botón compacto "Aplicar configuración estándar de [rol]". Resetea
  /// flags de caja, accesos ocultos y permisos especiales según el
  /// preset definido en `rol_presets.dart`. El admin puede después
  /// ajustar puntualmente.
  Widget _buildAplicarPresetButton() {
    final preset = presetParaRol(_rolSeleccionado.value);
    final tieneAlgo = preset.puedeAbrirCaja ||
        preset.puedeCerrarCaja ||
        preset.accesosRapidosOcultos.isNotEmpty ||
        preset.permisosEspeciales.isNotEmpty;
    if (!tieneAlgo) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _confirmarYAplicarPreset,
        icon: const Icon(Icons.auto_fix_high, size: 16),
        label: Text(
          'Aplicar configuración estándar de ${_rolSeleccionado.label}',
          style: const TextStyle(fontSize: 11),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue1,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _confirmarYAplicarPreset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Aplicar configuración estándar?'),
        content: Text(
          'Se sobrescribirán los flags de caja, accesos rápidos visibles '
          'y permisos especiales con la configuración predefinida para '
          '${_rolSeleccionado.label}. Después podés ajustar manualmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final preset = presetParaRol(_rolSeleccionado.value);
    setState(() {
      _puedeAbrirCaja = preset.puedeAbrirCaja;
      _puedeCerrarCaja = preset.puedeCerrarCaja;
      _accesosRapidosOcultos
        ..clear()
        ..addAll(preset.accesosRapidosOcultos);
      _permisosEspeciales
        ..clear()
        ..addAll(preset.permisosEspeciales);
    });
  }

  /// Sección de permisos granulares (catálogo extensible).
  /// Se renderiza agrupada por categoría — cada permiso es un checkbox
  /// con label corto + tooltip de description. Se persiste en
  /// `UsuarioSedeRol.permisos: String[]`.
  Widget _buildPermisosEspeciales() {
    final grupos = groupedGranularPermissions();
    return GradientContainer(
      borderWidth: 0.6,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      gradient: AppGradients.blueWhiteBlue(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppSubtitle('Permisos especiales', fontSize: 12),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => _permisosEspeciales.clear()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Quitar todos',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Text(
            'Capacidades adicionales por usuario que no dependen del rol. '
            'Útil para autorizar puntualmente (descuentos, anular ventas, '
            'ver costos, etc.).',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          for (final entry in grupos.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1.withValues(alpha: 0.7),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...entry.value.map((perm) {
              final activo = _permisosEspeciales.contains(perm.id);
              return Tooltip(
                message: perm.description,
                child: CustomCheckboxTile(
                  title: perm.label,
                  value: activo,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _permisosEspeciales.add(perm.id);
                      } else {
                        _permisosEspeciales.remove(perm.id);
                      }
                    });
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () {
          // Cerrar el teclado al tocar fuera de los campos de texto
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 900,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(right: 10,left: 10,top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.blueborder,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    child: AppSubtitle(widget.usuario.iniciales),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.usuario.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'DNI: ${widget.usuario.dni}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20,),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner de conversión
                    if (widget.esConversion) ...[
                      GradientContainer(
                        gradient: AppGradients.blueWhitegreen(),
                        borderColor: AppColors.green.withValues(alpha: 0.5),
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.green, size: 20,),
                            SizedBox(width: 12),
                            Expanded(
                              child: AppSubtitle(
                                'Este cliente será convertido a empleado con los permisos que asigne a continuación.',
                                color: Colors.green.shade800,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Selector de Rol
                    CustomDropdown<RolUsuario>(
                      label: 'Rol en la Empresa',
                      borderColor: AppColors.blueborder,
                      value: _rolSeleccionado,
                      items: RolUsuario.values.map((rol) {
                        return DropdownItem<RolUsuario>(
                          value: rol,
                          label: rol.label,
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _rolSeleccionado = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                    _buildAplicarPresetButton(),

                    const SizedBox(height: 16),

                    // Sedes Asignadas
                    if (widget.sedesDisponibles != null &&
                        widget.sedesDisponibles!.isNotEmpty) ...[
                      const AppSubtitle('Sedes Asignadas', fontSize: 12,),
                      const SizedBox(height: 4),
                      GradientContainer(
                        borderWidth: 0.6,
                        borderColor: AppColors.blueborder,
                        gradient: AppGradients.blueWhiteBlue(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Column(
                          children: widget.sedesDisponibles!.map((sede) {
                            final isSelected = _sedesSeleccionadas.contains(sede.id);
                            return CustomCheckboxTile(
                              title: sede.nombre,
                              subtitle: sede.direccion,
                              value: isSelected,
                              activeColor: AppColors.blueborder,
                              borderColor: AppColors.blueborder.withValues(alpha: 0.6),
                              onChanged: (value) {
                                setState(() {
                                  if (value) {
                                    _sedesSeleccionadas.add(sede.id);
                                  } else {
                                    _sedesSeleccionadas.remove(sede.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Permisos de Caja
                    const AppSubtitle('Permisos de Caja', fontSize: 12,),
                    const SizedBox(height: 4),
                    GradientContainer(
                      borderWidth: 0.6,
                      borderColor: AppColors.blueborder,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      gradient: AppGradients.blueWhiteBlue(),
                      child: Column(
                        children: [
                          CustomSwitchTile(
                            title: 'Pude Abrir Caja', 
                            subtitle: 'Permite al usuario abrir cajas',
                            value: _puedeAbrirCaja, 
                            onChanged: (value){
                            setState(() {
                              _puedeAbrirCaja =  value;
                            });
                          },),
                          const Divider(height: 1),
                          CustomSwitchTile(
                            title: 'Puede Cerrar Caja',
                            subtitle: 'Permite al usuario cerrar cajas',
                            value: _puedeCerrarCaja,
                            onChanged: (value){
                              setState(() {
                                _puedeCerrarCaja = value;
                              });
                            },
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Límite de Crédito
                    MontoSelectorSlider(
                      title: 'Límite de Crédito en Ventas',
                      icon: Icons.credit_card_outlined,
                      controller: _limiteCreditoController,
                      selectedMonto: _limiteCreditoVenta,
                      onMontoChanged: (value) {
                        setState(() {
                          _limiteCreditoVenta = value;
                        });
                      },
                      minMonto: 0,
                      maxMonto: 20000,
                      step: 100,
                      marcasReferencia: const [5000, 10000, 15000, 20000],
                      showMarcasReferencia: false,
                      primaryColor: AppColors.blueborder,
                      borderColor: AppColors.blueborder,
                      sliderActiveColor: AppColors.green,
                    ),

                    const SizedBox(height: 24),

                    // Accesos rápidos del dashboard visibles al usuario
                    _buildAccesosRapidosSeleccion(),

                    const SizedBox(height: 24),

                    // Permisos especiales (catálogo granular extensible)
                    _buildPermisosEspeciales(),
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.white,
                      textColor: AppColors.blue1,
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      text: 'Cancelar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.blue1,
                      textColor: AppColors.white,
                      onPressed: _guardar,
                      text: 'Guardar',
                      isLoading: _isLoading,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      )
    );
  }

  Future<void> _guardar() async {
    // print('💾 _guardar ejecutado en AsignarRolDialog');
    // print('esConversion: ${widget.esConversion}');

    if (_sedesSeleccionadas.isEmpty &&
        widget.sedesDisponibles != null &&
        widget.sedesDisponibles!.isNotEmpty) {
      // print('⚠️ Validación falló: debe seleccionar al menos una sede');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos una sede'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Construir el map con los datos a enviar
    final data = <String, dynamic>{
      'rol': _rolSeleccionado.value,
      if (_sedesSeleccionadas.isNotEmpty)
        'sedeIds': _sedesSeleccionadas,
      'puedeAbrirCaja': _puedeAbrirCaja,
      'puedeCerrarCaja': _puedeCerrarCaja,
      if (_limiteCreditoVenta != null)
        'limiteCreditoVenta': _limiteCreditoVenta,
      'accesosRapidosOcultos': _accesosRapidosOcultos.toList(),
      'permisos': _permisosEspeciales.toList(),
    };

    // print('📦 Data construida: $data');
    // print('🚀 Llamando onGuardar callback...');

    try {
      await widget.onGuardar(data);
      // print('✅ onGuardar callback completado');

      // Cerrar el dialog solo si la operación fue exitosa
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // print('❌ Error en onGuardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Clase auxiliar para representar una opción de sede
class SedeOption {
  final String id;
  final String nombre;
  final String? direccion;

  const SedeOption({
    required this.id,
    required this.nombre,
    this.direccion,
  });
}

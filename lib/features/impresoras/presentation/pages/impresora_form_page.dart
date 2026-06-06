import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/impresora_config.dart';
import '../bloc/impresora_form_cubit.dart';
import '../bloc/impresora_form_state.dart';

class ImpresoraFormPage extends StatelessWidget {
  final String? impresoraId;

  const ImpresoraFormPage({super.key, this.impresoraId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = locator<ImpresoraFormCubit>();
        if (impresoraId != null) cubit.cargarParaEditar(impresoraId!);
        return cubit;
      },
      child: _FormView(isEdit: impresoraId != null),
    );
  }
}

class _FormView extends StatefulWidget {
  final bool isEdit;
  const _FormView({required this.isEdit});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  TipoConexionImpresora _tipo = TipoConexionImpresora.bluetooth;
  String? _direccion;
  String? _nombreDispositivo;
  AnchoPapel _ancho = AnchoPapel.mm80;
  int _tamanoFuente = 24;
  bool _autoImprimirVentaRapida = false;
  bool _esPrincipal = false;
  String? _editId;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _hidratar(ImpresoraConfig imp) {
    _editId = imp.id;
    _nombreCtrl.text = imp.nombre;
    _tipo = imp.tipoConexion;
    _direccion = imp.direccion;
    _ancho = imp.anchoPapel;
    _tamanoFuente = imp.tamanoFuentePx;
    _autoImprimirVentaRapida = imp.autoImprimirVentaRapida;
    _esPrincipal = imp.esPrincipal;
  }

  Future<void> _abrirSelectorDispositivo() async {
    final cubit = context.read<ImpresoraFormCubit>();
    await cubit.scanBluetooth();
    if (!mounted) return;

    final state = cubit.state;
    if (state is ImpresoraFormError) {
      SnackBarHelper.showError(context, state.message);
      return;
    }
    if (state is! ImpresoraFormDevicesFound) return;

    final BluetoothInfo? elegido = await showModalBottomSheet<BluetoothInfo>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _DevicesSheet(
        devices: state.devices,
        onRefresh: () async {
          Navigator.of(sheetCtx).pop();
          await _abrirSelectorDispositivo();
        },
      ),
    );
    if (elegido != null && mounted) {
      setState(() {
        _direccion = elegido.macAdress;
        _nombreDispositivo = elegido.name;
        if (_nombreCtrl.text.trim().isEmpty) {
          _nombreCtrl.text = elegido.name;
        }
      });
    }
  }

  void _imprimirPrueba() {
    if (_direccion == null || _direccion!.isEmpty) {
      SnackBarHelper.showError(context, 'Elige un dispositivo primero');
      return;
    }
    context.read<ImpresoraFormCubit>().imprimirPrueba(
          nombre: _nombreCtrl.text.trim().isEmpty
              ? 'Impresora'
              : _nombreCtrl.text.trim(),
          tipoConexion: _tipo,
          direccion: _direccion!,
          anchoPapel: _ancho,
        );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_direccion == null || _direccion!.isEmpty) {
      SnackBarHelper.showError(context, 'Elige un dispositivo');
      return;
    }
    final cubit = context.read<ImpresoraFormCubit>();
    await cubit.guardar(
      idExistente: _editId,
      nombre: _nombreCtrl.text.trim(),
      tipoConexion: _tipo,
      direccion: _direccion!,
      anchoPapel: _ancho,
      tamanoFuentePx: _tamanoFuente,
      autoImprimirVentaRapida: _autoImprimirVentaRapida,
      esPrincipal: _esPrincipal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: widget.isEdit ? 'Editar impresora' : 'Nueva impresora',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocConsumer<ImpresoraFormCubit, ImpresoraFormState>(
          listener: (context, state) {
            if (state is ImpresoraFormEditing) {
              _hidratar(state.original);
            } else if (state is ImpresoraFormSaved) {
              SnackBarHelper.showSuccess(
                context,
                widget.isEdit ? 'Impresora actualizada' : 'Impresora agregada',
              );
              Navigator.of(context).pop(true);
            } else if (state is ImpresoraFormError) {
              SnackBarHelper.showError(context, state.message);
            } else if (state is ImpresoraFormPrintResult) {
              if (state.ok) {
                SnackBarHelper.showSuccess(context, state.message);
              } else {
                SnackBarHelper.showError(context, state.message);
              }
            }
          },
          builder: (context, state) {
            if (state is ImpresoraFormLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final saving = state is ImpresoraFormSaving;
            final printing = state is ImpresoraFormPrinting;
            final scanning = state is ImpresoraFormScanning;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomText(
                      controller: _nombreCtrl,
                      label: 'Nombre',
                      hintText: 'Ej: Caja Principal',
                      borderColor: AppColors.blue1,
                      required: true,
                      maxLength: 60,
                      autovalidateMode: AutovalidateModeX.onUnfocus,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomDropdown<TipoConexionImpresora>(
                      label: 'Tipo de conexión',
                      borderColor: AppColors.blue1,
                      value: _tipo,
                      items: [
                        DropdownItem<TipoConexionImpresora>(
                          value: TipoConexionImpresora.bluetooth,
                          label: TipoConexionImpresora.bluetooth.label,
                          leading: const Icon(Icons.bluetooth,
                              size: 16, color: AppColors.blue1),
                        ),
                        // Ethernet preparado pero deshabilitado en V1
                        DropdownItem<TipoConexionImpresora>(
                          value: TipoConexionImpresora.ethernet,
                          label: '${TipoConexionImpresora.ethernet.label} (próximamente)',
                          leading: const Icon(Icons.lan,
                              size: 16, color: AppColors.textSecondary),
                          enabled: false,
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _tipo = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _selectorDispositivo(scanning),
                    const SizedBox(height: 14),
                    CustomDropdown<AnchoPapel>(
                      label: 'Ancho de papel',
                      borderColor: AppColors.blue1,
                      value: _ancho,
                      items: AnchoPapel.values
                          .map((a) => DropdownItem<AnchoPapel>(
                                value: a,
                                label: a.label,
                                leading: const Icon(Icons.straighten,
                                    size: 16, color: AppColors.blue1),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _ancho = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomDropdown<int>(
                      label: 'Tamaño de fuente',
                      borderColor: AppColors.blue1,
                      value: _tamanoFuente,
                      items: const [
                        DropdownItem<int>(value: 24, label: '24px (normal)'),
                        DropdownItem<int>(value: 28, label: '28px (grande)'),
                        DropdownItem<int>(value: 32, label: '32px (muy grande)'),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _tamanoFuente = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomSwitchTile(
                      title: 'Auto imprimir tickets de Venta Rápida', 
                      value: _autoImprimirVentaRapida, 
                      onChanged: (v) => setState(() => _autoImprimirVentaRapida = v),
                       subtitle: 'Al terminar un cobro, el ticket se imprime automáticamente'
                    ),
                    CustomSwitchTile(
                      title: 'Marcar como principal', 
                      value: _esPrincipal, 
                      onChanged: (v) => setState(() => _esPrincipal = v),
                       subtitle: 'La impresora a la que se envían las impresiones automáticas'
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: printing ? 'Imprimiendo prueba...' : 'IMPRIMIR PRUEBA',
                      onPressed: printing ? null : _imprimirPrueba,
                      isLoading: printing,
                      borderColor: AppColors.green,
                      textColor: AppColors.green
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: widget.isEdit ? 'Guardar cambios' : 'Agregar impresora',
                      onPressed: saving ? null : _guardar,
                      isLoading: saving,
                      borderColor: AppColors.blue1,
                      textColor: AppColors.blue1
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _selectorDispositivo(bool scanning) {
    final tieneSel = _direccion != null && _direccion!.isNotEmpty;
    final label = tieneSel
        ? '${_nombreDispositivo ?? "Dispositivo"} · $_direccion'
        : 'Elegir dispositivo';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: InkWell(
            onTap: scanning ? null : _abrirSelectorDispositivo,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.blue1.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  if (scanning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    const Icon(Icons.bluetooth_searching, size: 16, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scanning ? 'Buscando...' : label,
                      style: TextStyle(
                        fontSize: 11,
                        color: tieneSel ? AppColors.blue2 : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: AppColors.blue1,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: scanning ? null : _abrirSelectorDispositivo,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _DevicesSheet extends StatelessWidget {
  final List<BluetoothInfo> devices;
  final Future<void> Function() onRefresh;
  const _DevicesSheet({required this.devices, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Dispositivos Bluetooth emparejados',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay dispositivos emparejados.\n\n'
                  'Toca "Emparejar impresora" para abrir los ajustes Bluetooth '
                  'del celular y emparejar tu impresora térmica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: AppColors.blue1),
                      title: Text(d.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        d.macAdress,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      onTap: () => Navigator.of(context).pop(d),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                '¿No ves tu impresora? Empárejala primero desde los ajustes Bluetooth del celular.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AppSettings.openAppSettings(
                          type: AppSettingsType.bluetooth,
                        );
                      },
                      icon: const Icon(Icons.settings_bluetooth, size: 18),
                      label: const Text('Emparejar impresora'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue1,
                        side: const BorderSide(color: AppColors.blue1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Buscar de nuevo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue1,
                        side: const BorderSide(color: AppColors.blue1),
                      ),
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
}

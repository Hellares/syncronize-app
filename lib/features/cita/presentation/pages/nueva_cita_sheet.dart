import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../servicio/domain/entities/servicio.dart';
import '../../../servicio/domain/entities/servicio_filtros.dart';
import '../../../servicio/domain/repositories/servicio_repository.dart';
import '../../../usuario/domain/entities/usuario.dart';
import '../../../servicio/presentation/widgets/asignar_tecnico_sheet.dart';
import '../bloc/cita_form/cita_form_cubit.dart';
import '../bloc/cita_form/cita_form_state.dart';
import '../bloc/disponibilidad/disponibilidad_cubit.dart';
import '../bloc/disponibilidad/disponibilidad_state.dart';
import '../widgets/slot_selector_widget.dart';

class NuevaCitaSheet extends StatefulWidget {
  const NuevaCitaSheet({super.key});

  @override
  State<NuevaCitaSheet> createState() => _NuevaCitaSheetState();
}

class _NuevaCitaSheetState extends State<NuevaCitaSheet> {
  int _currentStep = 0;
  late final String _empresaId;
  static const _totalSteps = 5;

  // Step 0: Cliente
  String? _clienteId;
  String? _clienteEmpresaId;
  String? _clienteNombre;

  // Step 1: Servicio
  List<Servicio> _serviciosDisponibles = [];
  Servicio? _servicioSeleccionado;
  bool _cargandoServicios = false;

  // Step 2: Sede
  List<Sede> _sedes = [];
  Sede? _sedeSeleccionada;

  // Step 3: Técnico + Fecha + Hora
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _tecnicoId;
  String? _tecnicoNombre;
  String? _selectedSlotInicio;
  String? _selectedSlotFin;

  // Step 4: Notas
  final _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _sedes = empresaState.context.sedes;
      if (_sedes.length == 1) {
        _sedeSeleccionada = _sedes.first;
      }
    } else {
      _empresaId = '';
    }
    _loadServicios();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadServicios() async {
    setState(() => _cargandoServicios = true);
    final repo = locator<ServicioRepository>();
    final result = await repo.getServicios(
      empresaId: _empresaId,
      filtros: const ServicioFiltros(limit: 100),
    );
    if (!mounted) return;
    setState(() {
      _cargandoServicios = false;
      if (result is Success<ServiciosPaginados>) {
        _serviciosDisponibles = result.data.data
            .where((s) => s.requiereReserva)
            .toList();
      }
    });
  }

  // ─── Selectores ───

  Future<void> _openClienteSelector() async {
    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: _empresaId,
    );
    if (result != null && mounted) {
      setState(() {
        if (result.isPersona) {
          _clienteId = result.clienteId;
          _clienteEmpresaId = null;
        } else {
          _clienteId = null;
          _clienteEmpresaId = result.clienteEmpresaId;
        }
        _clienteNombre = result.displayName;
      });
    }
  }

  Future<void> _openTecnicoSelector() async {
    final result = await showModalBottomSheet<Usuario>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AsignarTecnicoSheet(
        empresaId: _empresaId,
        tecnicoActualId: _tecnicoId,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _tecnicoId = result.id;
        _tecnicoNombre = result.nombreCompleto;
        _selectedSlotInicio = null;
        _selectedSlotFin = null;
      });
      _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CitaFormCubit, CitaFormState>(
      listener: (context, state) {
        if (state is CitaFormSuccess) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje)),
          );
        } else if (state is CitaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Nueva Cita',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: GradientContainer(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.blue1,
                onPrimary: Colors.white,
              ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              margin: const EdgeInsets.only(left: 10, right: 8, bottom: 12),
              connectorColor: const WidgetStatePropertyAll(AppColors.blue1),
              onStepContinue: _onStepContinue,
              onStepCancel: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              onStepTapped: (step) {
                if (step < _currentStep) setState(() => _currentStep = step);
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_currentStep < _totalSteps - 1)
                        CustomButton(
                          text: 'Siguiente',
                          onPressed: _canContinue() ? details.onStepContinue : null,
                          backgroundColor: AppColors.blue1,
                        ),
                      if (_currentStep == _totalSteps - 1)
                        BlocBuilder<CitaFormCubit, CitaFormState>(
                          builder: (context, state) {
                            return CustomButton(
                              text: 'Agendar Cita',
                              onPressed: state is CitaFormLoading ? null : _crearCita,
                              backgroundColor: AppColors.green,
                            );
                          },
                        ),
                      const SizedBox(width: 4),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Anterior', style: TextStyle(fontSize: 10)),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // ── Step 0: Cliente ──
                Step(
                  title: const AppSubtitle('CLIENTE'),
                  subtitle: _clienteNombre != null
                      ? Text(_clienteNombre!)
                      : null,
                  isActive: _currentStep >= 0,
                  state: _clienteId != null || _clienteEmpresaId != null
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildClienteStep(),
                ),
                // ── Step 1: Servicio ──
                Step(
                  title: const AppSubtitle('SERVICIO'),
                  subtitle: _servicioSeleccionado != null
                      ? Text(_servicioSeleccionado!.nombre)
                      : null,
                  isActive: _currentStep >= 1,
                  state: _servicioSeleccionado != null
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildServicioStep(),
                ),
                // ── Step 2: Sede ──
                Step(
                  title: const AppSubtitle('SEDE'),
                  subtitle: _sedeSeleccionada != null
                      ? Text(_sedeSeleccionada!.nombre)
                      : null,
                  isActive: _currentStep >= 2,
                  state: _sedeSeleccionada != null
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildSedeStep(),
                ),
                // ── Step 3: Fecha + Hora + Técnico ──
                Step(
                  title: const AppSubtitle('FECHA Y HORA'),
                  subtitle: _selectedSlotInicio != null
                      ? Text('${DateFormatter.formatDate(_selectedDate)} $_selectedSlotInicio')
                      : null,
                  isActive: _currentStep >= 3,
                  state: _selectedSlotInicio != null
                      ? StepState.complete
                      : StepState.indexed,
                  content: _currentStep >= 3
                      ? _buildFechaHoraStep()
                      : const SizedBox.shrink(),
                ),
                // ── Step 4: Confirmar ──
                Step(
                  title: const AppSubtitle('CONFIRMAR'),
                  isActive: _currentStep >= 4,
                  state: StepState.indexed,
                  content: _buildConfirmarStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step builders ───

  Widget _buildClienteStep() {
    if (_clienteNombre != null) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _clienteEmpresaId != null ? Icons.business : Icons.person,
                  color: AppColors.blue1,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      _clienteNombre!,
                      fontSize: 12,
                      color: AppColors.blue2,
                    ),
                    AppLabelText(
                      _clienteId != null ? 'Persona natural' : 'Empresa',
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _openClienteSelector,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: AppColors.blue1),
                      SizedBox(width: 4),
                      Text('Cambiar', style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _openClienteSelector,
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 18, color: AppColors.blue1),
              const SizedBox(width: 8),
              const AppSubtitle('Seleccionar cliente', fontSize: 12, color: AppColors.blue1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicioStep() {
    if (_cargandoServicios) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.blue1, strokeWidth: 2),
        ),
      );
    }

    if (_serviciosDisponibles.isEmpty) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: Colors.orange.shade200,
        borderWidth: 0.6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No hay servicios con reserva habilitada.\nActive "Requiere reserva" en la configuración del servicio.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade800, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _serviciosDisponibles.map((servicio) {
        final isSelected = _servicioSeleccionado?.id == servicio.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _servicioSeleccionado = servicio;
                _selectedSlotInicio = null;
                _selectedSlotFin = null;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: GradientContainer(
              gradient: AppGradients.blueWhiteBlue(),
              borderColor: isSelected ? AppColors.blue1 : AppColors.blueborder,
              borderWidth: isSelected ? 1.2 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue1.withValues(alpha: 0.15)
                            : AppColors.blue1.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.room_service_outlined,
                        size: 16,
                        color: isSelected ? AppColors.blue1 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.nombre,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.blue1 : Colors.grey.shade800,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                          if (servicio.duracionMinutos != null)
                            Text(
                              '${servicio.duracionMinutos} minutos',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                    if (servicio.precio != null)
                      Text(
                        'S/ ${servicio.precio!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.blue1 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSedeStep() {
    if (_sedes.isEmpty) {
      return const Text('No hay sedes disponibles');
    }

    return Column(
      children: _sedes.map((sede) {
        final isSelected = _sedeSeleccionada?.id == sede.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _sedeSeleccionada = sede;
                _selectedSlotInicio = null;
                _selectedSlotFin = null;
                _tecnicoId = null;
                _tecnicoNombre = null;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: GradientContainer(
              gradient: AppGradients.blueWhiteBlue(),
              borderColor: isSelected ? AppColors.blue1 : AppColors.blueborder,
              borderWidth: isSelected ? 1.2 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue1.withValues(alpha: 0.15)
                            : AppColors.blue1.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.store_outlined,
                        size: 16,
                        color: isSelected ? AppColors.blue1 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sede.nombre,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.blue1 : Colors.grey.shade800,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                          Text(
                            sede.codigo,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    if (sede.esPrincipal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Principal',
                          style: TextStyle(fontSize: 9, color: Colors.amber.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFechaHoraStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Técnico selector
        InkWell(
          onTap: _openTecnicoSelector,
          borderRadius: BorderRadius.circular(8),
          child: GradientContainer(
            gradient: AppGradients.blueWhiteBlue(),
            borderColor: _tecnicoId != null ? AppColors.blue1 : AppColors.blueborder,
            borderWidth: _tecnicoId != null ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.engineering, size: 16, color: AppColors.blue1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tecnicoNombre ?? 'Asignar técnico',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _tecnicoId != null ? FontWeight.w600 : FontWeight.w400,
                            color: _tecnicoId != null ? AppColors.blue2 : Colors.grey.shade500,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                          ),
                        ),
                        if (_tecnicoId == null)
                          Text(
                            'Opcional: filtra horarios por técnico',
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _tecnicoId != null ? Icons.swap_horiz : Icons.chevron_right,
                    size: 16,
                    color: AppColors.blue1,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Date picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                _selectedSlotInicio = null;
                _selectedSlotFin = null;
              });
              _loadSlots();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: GradientContainer(
            gradient: AppGradients.blueWhiteBlue(),
            borderColor: AppColors.blueborder,
            borderWidth: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.calendar_today, size: 16, color: AppColors.blue1),
                  ),
                  const SizedBox(width: 10),
                  AppSubtitle(
                    DateFormatter.formatDate(_selectedDate),
                    fontSize: 12,
                    color: AppColors.blue2,
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 14, color: AppColors.blue1),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Slots
        const AppSubtitle('Horarios disponibles', fontSize: 11, color: AppColors.blue1),
        const SizedBox(height: 8),
        BlocBuilder<DisponibilidadCubit, DisponibilidadState>(
          builder: (context, state) {
            if (state is DisponibilidadLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.blue1, strokeWidth: 2),
                ),
              );
            }
            if (state is DisponibilidadError) {
              return GradientContainer(
                gradient: AppGradients.blueWhiteBlue(),
                borderColor: Colors.red.shade200,
                borderWidth: 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.message, style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is DisponibilidadLoaded) {
              if (state.disponibilidad.mensaje != null) {
                return GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  borderColor: Colors.orange.shade200,
                  borderWidth: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.disponibilidad.mensaje!, style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SlotSelectorWidget(
                slots: state.disponibilidad.slots,
                selectedSlot: _selectedSlotInicio,
                onSlotSelected: (slot) {
                  setState(() {
                    _selectedSlotInicio = slot.horaInicio;
                    _selectedSlotFin = slot.horaFin;
                  });
                },
              );
            }
            return Text(
              'Seleccione fecha para ver horarios',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notas
        TextField(
          controller: _notasController,
          decoration: InputDecoration(
            labelText: 'Notas (opcional)',
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blue1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 12),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Resumen
        const AppSubtitle('Resumen de la cita', fontSize: 12, color: AppColors.blue1),
        const SizedBox(height: 10),
        GradientContainer(
          gradient: AppGradients.blueWhiteBlue(),
          borderColor: AppColors.blueborder,
          borderWidth: 0.6,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (_clienteNombre != null)
                  _buildResumenRow(Icons.person, 'Cliente', _clienteNombre!),
                if (_servicioSeleccionado != null)
                  _buildResumenRow(Icons.room_service, 'Servicio', _servicioSeleccionado!.nombre),
                if (_sedeSeleccionada != null)
                  _buildResumenRow(Icons.store, 'Sede', _sedeSeleccionada!.nombre),
                _buildResumenRow(Icons.calendar_today, 'Fecha', DateFormatter.formatDate(_selectedDate)),
                if (_selectedSlotInicio != null)
                  _buildResumenRow(Icons.schedule, 'Hora', '$_selectedSlotInicio - $_selectedSlotFin'),
                if (_tecnicoNombre != null)
                  _buildResumenRow(Icons.engineering, 'Técnico', _tecnicoNombre!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.blue1),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lógica ───

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _clienteId != null || _clienteEmpresaId != null;
      case 1:
        return _servicioSeleccionado != null;
      case 2:
        return _sedeSeleccionada != null;
      case 3:
        return _selectedSlotInicio != null;
      default:
        return true;
    }
  }

  void _onStepContinue() {
    if (!_canContinue()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      if (_currentStep == 3 &&
          _sedeSeleccionada != null &&
          _servicioSeleccionado != null) {
        _loadSlots();
      }
    } else {
      _crearCita();
    }
  }

  void _loadSlots() {
    if (_sedeSeleccionada == null || _servicioSeleccionado == null) return;
    context.read<DisponibilidadCubit>().cargarSlots(
          fecha: DateFormat('yyyy-MM-dd').format(_selectedDate),
          sedeId: _sedeSeleccionada!.id,
          servicioId: _servicioSeleccionado!.id,
          tecnicoId: _tecnicoId,
        );
  }

  void _crearCita() {
    if (_selectedSlotInicio == null || _selectedSlotFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un horario')),
      );
      return;
    }
    if (_tecnicoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe asignar un técnico')),
      );
      return;
    }

    context.read<CitaFormCubit>().crearCita(
          sedeId: _sedeSeleccionada!.id,
          servicioId: _servicioSeleccionado!.id,
          tecnicoId: _tecnicoId!,
          fecha: DateFormat('yyyy-MM-dd').format(_selectedDate),
          horaInicio: _selectedSlotInicio!,
          horaFin: _selectedSlotFin!,
          clienteId: _clienteId,
          clienteEmpresaId: _clienteEmpresaId,
          notas: _notasController.text.isNotEmpty
              ? _notasController.text
              : null,
        );
  }
}

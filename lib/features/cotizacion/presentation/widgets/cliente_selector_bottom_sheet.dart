import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cliente/presentation/bloc/cliente_list/cliente_list_cubit.dart';
import '../../../cliente/presentation/bloc/cliente_list/cliente_list_state.dart';
import '../../../cliente/presentation/bloc/cliente_form/cliente_form_cubit.dart';
import '../../../cliente/presentation/bloc/cliente_form/cliente_form_state.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../../../core/widgets/floating_button_icon.dart';

/// Resultado de la selección/registro de un cliente
class ClienteSelectionResult {
  final String clienteId;
  final String nombreCompleto;
  final String? dni;
  final String? telefono;
  final String? email;
  final String? direccion;

  const ClienteSelectionResult({
    required this.clienteId,
    required this.nombreCompleto,
    this.dni,
    this.telefono,
    this.email,
    this.direccion,
  });
}

enum _SelectorMode { search, register }

/// Bottom sheet para buscar/seleccionar o registrar un cliente
class ClienteSelectorBottomSheet extends StatefulWidget {
  final String empresaId;

  const ClienteSelectorBottomSheet({
    super.key,
    required this.empresaId,
  });

  /// Abre el bottom sheet y retorna el cliente seleccionado/registrado
  static Future<ClienteSelectionResult?> show({
    required BuildContext context,
    required String empresaId,
  }) {
    return showModalBottomSheet<ClienteSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClienteSelectorBottomSheet(empresaId: empresaId),
    );
  }

  @override
  State<ClienteSelectorBottomSheet> createState() =>
      _ClienteSelectorBottomSheetState();
}

class _ClienteSelectorBottomSheetState
    extends State<ClienteSelectorBottomSheet> {
  _SelectorMode _mode = _SelectorMode.search;

  // Cubits
  late final ClienteListCubit _listCubit;
  late final ClienteFormCubit _formCubit;
  final _consultarDniUseCase = locator<ConsultarDniUseCase>();

  // Search mode controller
  final _searchController = TextEditingController();

  // Register mode controllers
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLookingUpDni = false;
  bool _dniFieldsFilled = false;
  String? _dniError;
  String? _origenDatos;

  @override
  void initState() {
    super.initState();
    _listCubit = locator<ClienteListCubit>();
    _formCubit = locator<ClienteFormCubit>();
    _listCubit.loadClientes(empresaId: widget.empresaId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _listCubit.close();
    _formCubit.close();
    super.dispose();
  }

  ClienteSelectionResult _resultFromCliente(Cliente cliente) {
    return ClienteSelectionResult(
      clienteId: cliente.id,
      nombreCompleto: cliente.nombreCompleto,
      dni: cliente.dni,
      telefono: cliente.telefono,
      email: cliente.email,
      direccion: cliente.direccion,
    );
  }

  // ─── DNI Lookup (register mode) ───

  Future<void> _lookupDni() async {
    final dni = _dniController.text.trim();
    if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      setState(() => _dniError = 'Ingresa un DNI válido de 8 dígitos');
      return;
    }

    setState(() {
      _isLookingUpDni = true;
      _dniError = null;
    });

    final result = await _consultarDniUseCase(dni);
    if (!mounted) return;

    if (result is Success<ConsultaDni>) {
      final data = result.data;
      setState(() {
        _nombresController.text = data.nombres;
        _apellidosController.text = data.apellidos;
        if (data.telefono != null && data.telefono!.isNotEmpty) {
          _telefonoController.text = data.telefono!;
        }
        if (data.email != null && data.email!.isNotEmpty) {
          _emailController.text = data.email!;
        }
        _direccionController.text = data.direccion;
        _dniFieldsFilled = true;
        _origenDatos = data.origen;
        _isLookingUpDni = false;
      });
    } else if (result is Error<ConsultaDni>) {
      setState(() {
        _dniError = result.message;
        _isLookingUpDni = false;
      });
    }
  }

  void _onDniChanged(String value) {
    if (_dniError != null) {
      setState(() => _dniError = null);
    }
    if (_dniFieldsFilled) {
      setState(() {
        _nombresController.clear();
        _apellidosController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _direccionController.clear();
        _dniFieldsFilled = false;
        _origenDatos = null;
      });
    }
    if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
      _lookupDni();
    }
  }

  bool _validateRegisterForm() {
    final dni = _dniController.text.trim();
    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (dni.isEmpty || dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      SnackBarHelper.showError(context, 'El DNI debe tener 8 dígitos');
      return false;
    }
    if (nombres.isEmpty) {
      SnackBarHelper.showError(context, 'Los nombres son obligatorios');
      return false;
    }
    if (apellidos.isEmpty) {
      SnackBarHelper.showError(context, 'Los apellidos son obligatorios');
      return false;
    }
    if (telefono.isEmpty || !RegExp(r'^\d{9}$').hasMatch(telefono)) {
      SnackBarHelper.showError(context, 'El teléfono debe tener 9 dígitos');
      return false;
    }
    return true;
  }

  void _submitRegister() {
    if (!_validateRegisterForm()) return;
    _formCubit.registrarCliente(
      empresaId: widget.empresaId,
      dni: _dniController.text.trim(),
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _listCubit),
        BlocProvider.value(value: _formCubit),
      ],
      child: BlocListener<ClienteFormCubit, ClienteFormState>(
        listener: (context, state) {
          if (state is ClienteFormSuccess) {
            final cliente = state.response.cliente;
            Navigator.pop(context, _resultFromCliente(cliente));
          } else if (state is ClienteFormError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Body
              Flexible(
                child: _mode == _SelectorMode.search
                    ? _buildSearchBody()
                    : _buildRegisterBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_mode == _SelectorMode.register)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _mode = _SelectorMode.search),
            ),
          if (_mode == _SelectorMode.register) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _mode == _SelectorMode.search
                  ? Icons.person_search
                  : Icons.person_add,
              color: AppColors.blue1,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          AppSubtitle(
            _mode == _SelectorMode.search
                ? 'SELECCIONAR CLIENTE'
                : 'REGISTRAR CLIENTE',
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  // ─── Search Mode ───

  Widget _buildSearchBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar por nombre, DNI o teléfono...',
            onChanged: (query) {
              if (query.isEmpty) {
                _listCubit.loadClientes(empresaId: widget.empresaId);
              } else {
                _listCubit.search(query);
              }
            },
          ),
        ),
        Flexible(
          child: BlocBuilder<ClienteListCubit, ClienteListState>(
            builder: (context, state) {
              if (state is ClienteListLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ClienteListError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (state is ClienteListLoaded) {
                if (state.clientes.isEmpty) {
                  return _buildEmptySearch();
                }
                return _buildClienteList(state.clientes);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        // Register new button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _mode = _SelectorMode.register),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Registrar nuevo cliente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue1,
                side: const BorderSide(color: AppColors.blue1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No se encontraron clientes',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Puedes registrar uno nuevo',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteList(List<Cliente> clientes) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteTile(cliente);
      },
    );
  }

  Widget _buildClienteTile(Cliente cliente) {
    return InkWell(
      onTap: () => Navigator.pop(context, _resultFromCliente(cliente)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blueborder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Iniciales
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bluechip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cliente.iniciales,
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    cliente.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DNI: ${cliente.dni ?? '-'}  •  ${cliente.telefono ?? '-'}',
                    style: TextStyle(
                      fontSize: 11,
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

  // ─── Register Mode ───

  Widget _buildRegisterBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DNI lookup section
          _buildDniSection(),
          const SizedBox(height: 14),
          // Nombre fields
          CustomText(
            controller: _nombresController,
            label: 'Nombres',
            hintText: 'Juan Carlos',
            prefixIcon: const Icon(Icons.person_outline),
            borderColor: AppColors.blue1,
            enabled: !_dniFieldsFilled,
          ),
          const SizedBox(height: 14),
          CustomText(
            controller: _apellidosController,
            label: 'Apellidos',
            hintText: 'Pérez García',
            prefixIcon: const Icon(Icons.person_outline),
            borderColor: AppColors.blue1,
            enabled: !_dniFieldsFilled,
          ),
          const SizedBox(height: 14),
          CustomText(
            controller: _telefonoController,
            label: 'Teléfono',
            hintText: '987654321',
            fieldType: FieldType.number,
            maxLength: 9,
            prefixIcon: const Icon(Icons.phone_outlined),
            borderColor: AppColors.blue1,
          ),
          const SizedBox(height: 14),
          CustomText(
            controller: _emailController,
            label: 'Email (opcional)',
            hintText: 'cliente@example.com',
            fieldType: FieldType.email,
            prefixIcon: const Icon(Icons.email_outlined),
            borderColor: AppColors.blue1,
          ),
          const SizedBox(height: 14),
          CustomText(
            controller: _direccionController,
            label: 'Dirección (opcional)',
            hintText: 'Av. Principal 123',
            prefixIcon: const Icon(Icons.home_outlined),
            borderColor: AppColors.blue1,
          ),
          const SizedBox(height: 20),
          // Submit button
          BlocBuilder<ClienteFormCubit, ClienteFormState>(
            builder: (context, state) {
              final isLoading = state is ClienteFormLoading;
              return CustomButton(
                text: 'Registrar Cliente',
                isLoading: isLoading,
                icon:
                    const Icon(Icons.person_add, color: Colors.white, size: 18),
                onPressed: isLoading ? null : _submitRegister,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDniSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa el DNI para autocompletar los datos.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomText(
                controller: _dniController,
                label: 'DNI',
                hintText: '12345678',
                fieldType: FieldType.number,
                maxLength: 8,
                prefixIcon: const Icon(Icons.badge_outlined),
                borderColor: AppColors.blue1,
                enabled: !_isLookingUpDni,
                externalError: _dniError,
                onChanged: _onDniChanged,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _isLookingUpDni
                  ? const SizedBox(
                      width: 35,
                      height: 35,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            color: AppColors.blue2,
                          ),
                        ),
                      ),
                    )
                  : FloatingButtonIcon(
                      size: 35,
                      icon: Icons.search,
                      backgroundColor: AppColors.blue2,
                      onPressed: _dniController.text.length != 8
                          ? () {}
                          : _lookupDni,
                    ),
            ),
          ],
        ),
        if (_dniFieldsFilled) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _origenDatos == 'INTERNO'
                        ? 'Persona encontrada en el sistema'
                        : 'Datos autocompletados desde RENIEC',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

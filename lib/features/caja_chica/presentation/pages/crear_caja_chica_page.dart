import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../usuario/domain/entities/registro_usuario_response.dart';
import '../../../usuario/domain/entities/usuario.dart';
import '../../../usuario/domain/entities/usuario_filtros.dart';
import '../../../usuario/domain/usecases/get_usuarios_usecase.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja_chica.dart';
import '../../domain/usecases/crear_caja_chica_usecase.dart';

class CrearCajaChicaPage extends StatefulWidget {
  const CrearCajaChicaPage({super.key});

  @override
  State<CrearCajaChicaPage> createState() => _CrearCajaChicaPageState();
}

class _CrearCajaChicaPageState extends State<CrearCajaChicaPage> {
  final _nombreController = TextEditingController();
  final _fondoFijoController = TextEditingController();
  final _umbralAlertaController = TextEditingController();
  String? _selectedSedeId;
  String? _selectedResponsableId;
  bool _isSubmitting = false;

  List<Usuario> _usuarios = [];
  bool _isLoadingUsuarios = true;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      setState(() => _isLoadingUsuarios = false);
      return;
    }

    final empresaId = empresaState.context.empresa.id;
    final useCase = locator<GetUsuariosUseCase>();
    final result = await useCase(
      empresaId: empresaId,
      filtros: const UsuarioFiltros(limit: 100, isActive: true),
    );

    if (!mounted) return;

    if (result is Success<UsuariosPaginados>) {
      setState(() {
        _usuarios = result.data.data;
        _isLoadingUsuarios = false;
      });
    } else {
      setState(() => _isLoadingUsuarios = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _fondoFijoController.dispose();
    _umbralAlertaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return Scaffold(
      appBar: SmartAppBar(
        title: 'Nueva Caja Chica',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sede selector
              const AppSubtitle(
                'Sede',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSedeId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.store_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: sedes
                    .map((sede) => DropdownMenuItem<String>(
                          value: sede.id,
                          child: Text(
                            sede.nombre,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSedeId = value);
                },
              ),
              const SizedBox(height: 24),

              // Nombre
              const AppSubtitle(
                'Nombre',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej: Caja Chica Oficina',
                  prefixIcon: const Icon(Icons.label_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Fondo Fijo
              const AppSubtitle(
                'Fondo Fijo',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fondoFijoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  prefixText: 'S/ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Umbral de Alerta (opcional)
              const AppSubtitle(
                'Umbral de Alerta (opcional)',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _umbralAlertaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.warning_amber_rounded),
                  prefixText: 'S/ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  helperText:
                      'Se alertara cuando el saldo sea menor a este monto',
                ),
              ),
              const SizedBox(height: 24),

              // Responsable
              const AppSubtitle(
                'Responsable',
                fontSize: 14,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              if (_isLoadingUsuarios)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedResponsableId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text(
                    'Seleccionar responsable',
                    style: TextStyle(fontSize: 14),
                  ),
                  items: _usuarios
                      .map((usuario) => DropdownMenuItem<String>(
                            value: usuario.id,
                            child: Text(
                              usuario.nombreCompleto,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedResponsableId = value);
                  },
                ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Crear Caja Chica',
                  backgroundColor: AppColors.green,
                  height: 48,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _crearCajaChica,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _crearCajaChica() async {
    if (_selectedSedeId == null) {
      SnackBarHelper.showError(context, 'Selecciona una sede');
      return;
    }

    if (_nombreController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Ingresa un nombre');
      return;
    }

    final fondoFijo =
        double.tryParse(_fondoFijoController.text.replaceAll(',', '.'));
    if (fondoFijo == null || fondoFijo <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un fondo fijo valido');
      return;
    }

    if (_selectedResponsableId == null) {
      SnackBarHelper.showError(context, 'Selecciona un responsable');
      return;
    }

    double? umbralAlerta;
    if (_umbralAlertaController.text.isNotEmpty) {
      umbralAlerta =
          double.tryParse(_umbralAlertaController.text.replaceAll(',', '.'));
    }

    setState(() => _isSubmitting = true);

    final useCase = locator<CrearCajaChicaUseCase>();
    final result = await useCase(
      sedeId: _selectedSedeId!,
      nombre: _nombreController.text.trim(),
      fondoFijo: fondoFijo,
      umbralAlerta: umbralAlerta,
      responsableId: _selectedResponsableId!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<CajaChica>) {
      SnackBarHelper.showSuccess(context, 'Caja chica creada exitosamente');
      Navigator.of(context).pop(true);
    } else if (result is Error<CajaChica>) {
      SnackBarHelper.showError(context, result.message);
    }
  }
}

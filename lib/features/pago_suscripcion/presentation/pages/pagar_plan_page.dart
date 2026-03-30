import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sistema_config_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/pago_suscripcion/pago_suscripcion_cubit.dart';

class PagarPlanPage extends StatefulWidget {
  final String? planId;
  final String? planNombre;
  final double? planPrecio;
  final double? planPrecioSemestral;
  final double? planPrecioAnual;

  const PagarPlanPage({
    super.key,
    this.planId,
    this.planNombre,
    this.planPrecio,
    this.planPrecioSemestral,
    this.planPrecioAnual,
  });

  @override
  State<PagarPlanPage> createState() => _PagarPlanPageState();
}

class _PagarPlanPageState extends State<PagarPlanPage> {
  int _currentStep = 0;
  String _selectedPeriodo = 'MENSUAL';
  String _selectedMetodoPago = 'YAPE';
  File? _selectedImage;
  String? _createdPagoId;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await locator<SistemaConfigService>().getConfig();
    if (mounted) {
      setState(() => _config = config);
    }
  }

  double get _montoAPagar {
    switch (_selectedPeriodo) {
      case 'SEMESTRAL':
        return widget.planPrecioSemestral ?? (widget.planPrecio ?? 0) * 6;
      case 'ANUAL':
        return widget.planPrecioAnual ?? (widget.planPrecio ?? 0) * 12;
      default:
        return widget.planPrecio ?? 0;
    }
  }

  String get _periodoLabel {
    switch (_selectedPeriodo) {
      case 'SEMESTRAL':
        return 'Semestral';
      case 'ANUAL':
        return 'Anual';
      default:
        return 'Mensual';
    }
  }

  String get _metodoPagoInstrucciones {
    final yapeNumero = _config?['yapeNumero'] ?? '942857613';
    final yapeTitular = _config?['yapeTitular'] ?? 'Syncronize SAC';
    final plinNumero = _config?['plinNumero'] ?? '942857613';
    final plinTitular = _config?['plinTitular'] ?? 'Syncronize SAC';
    final bancoNombre = _config?['bancoNombre'] ?? 'BCP';
    final bancoCuenta = _config?['bancoCuenta'] ?? '191-12345678-0-12';
    final bancoCci = _config?['bancoCci'] ?? '002-191-12345678012-34';
    final bancoTitular = _config?['bancoTitular'] ?? 'Syncronize SAC';

    switch (_selectedMetodoPago) {
      case 'YAPE':
        return 'Realiza tu pago al siguiente numero Yape:\n\n$yapeNumero\nTitular: $yapeTitular\n\nMonto: S/ ${_montoAPagar.toStringAsFixed(2)}';
      case 'PLIN':
        return 'Realiza tu pago al siguiente numero Plin:\n\n$plinNumero\nTitular: $plinTitular\n\nMonto: S/ ${_montoAPagar.toStringAsFixed(2)}';
      case 'TRANSFERENCIA':
        return 'Realiza tu transferencia a:\n\nBanco: $bancoNombre\nCuenta: $bancoCuenta\nCCI: $bancoCci\nTitular: $bancoTitular\n\nMonto: S/ ${_montoAPagar.toStringAsFixed(2)}';
      default:
        return '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSubtitle('Seleccionar imagen', fontSize: 16),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.camera_alt, color: AppColors.blue1),
                ),
                title: const AppText('Camara',
                    size: 14, fontWeight: FontWeight.w500),
                subtitle: const AppText('Tomar foto del comprobante',
                    size: 12, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.blue1),
                ),
                title: const AppText('Galeria',
                    size: 14, fontWeight: FontWeight.w500),
                subtitle: const AppText('Seleccionar de la galeria',
                    size: 12, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PagoSuscripcionCubit>(),
      child: BlocConsumer<PagoSuscripcionCubit, PagoSuscripcionState>(
        listener: (context, state) {
          if (state is PagoSuscripcionCreated) {
            _createdPagoId = state.pago.id;
            // Si ya tenemos imagen, subimos el comprobante
            if (_selectedImage != null && _createdPagoId != null) {
              context.read<PagoSuscripcionCubit>().subirComprobante(
                    pagoId: _createdPagoId!,
                    file: _selectedImage!,
                  );
            } else {
              // Avanzar al paso de confirmacion
              setState(() => _currentStep = 4);
            }
          } else if (state is PagoSuscripcionComprobanteUploaded) {
            setState(() => _currentStep = 4);
          } else if (state is PagoSuscripcionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PagoSuscripcionLoading ||
              state is PagoSuscripcionUploadingComprobante;

          return Scaffold(
            appBar: AppBar(
              title: const AppTitle('Pagar Suscripcion', fontSize: 16),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.blue1,
                ),
              ),
              child: Stepper(
              currentStep: _currentStep,
              type: StepperType.vertical,
              physics: const ClampingScrollPhysics(),
              controlsBuilder: (context, details) {
                if (_currentStep == 4) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_currentStep < 3)
                        Expanded(
                          child: CustomButton(
                            borderColor: AppColors.blue1,
                            textColor: AppColors.blue1,
                            text: 'Continuar',
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(
                                        () => _currentStep = _currentStep + 1);
                                  },
                          ),
                        ),
                      if (_currentStep == 3)
                        Expanded(
                          child: CustomButton(
                            borderColor: AppColors.blue1,
                            textColor: AppColors.blue1,
                            text: 'Enviar Pago',
                            isLoading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () => _enviarPago(context),
                            icon: const Icon(Icons.send_outlined,
                                color: AppColors.white, size: 18),
                          ),
                        ),
                      if (_currentStep > 0 && _currentStep < 4) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(
                                      () => _currentStep = _currentStep - 1);
                                },
                          child: const Text('Atras'),
                        ),
                      ],
                    ],
                  ),
                );
              },
              onStepTapped: (step) {
                if (step < _currentStep && _currentStep < 4 && !isLoading) {
                  setState(() => _currentStep = step);
                }
              },
              steps: [
                // Step 1: Plan info
                Step(
                  title: const Text('Plan seleccionado'),
                  subtitle: Text(widget.planNombre ?? 'Plan'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildPlanInfoStep(),
                ),
                // Step 2: Periodo
                Step(
                  title: const Text('Periodo de pago'),
                  subtitle: _currentStep > 1 ? Text(_periodoLabel) : null,
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildPeriodoStep(),
                ),
                // Step 3: Metodo de pago
                Step(
                  title: const Text('Metodo de pago'),
                  subtitle: _currentStep > 2
                      ? Text(_selectedMetodoPago)
                      : null,
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildMetodoPagoStep(),
                ),
                // Step 4: Comprobante
                Step(
                  title: const Text('Comprobante de pago'),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildComprobanteStep(isLoading),
                ),
                // Step 5: Confirmacion
                Step(
                  title: const Text('Confirmacion'),
                  isActive: _currentStep >= 4,
                  state: _currentStep == 4
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildConfirmacionStep(context),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanInfoStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.blue1.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: AppColors.blue1, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                          widget.planNombre ?? 'Plan Suscripcion',
                          fontSize: 12),
                      const SizedBox(height: 4),
                      AppText(
                        'S/ ${(widget.planPrecio ?? 0).toStringAsFixed(2)} / mes',
                        size: 10,
                        color: AppColors.blue1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.planPrecioSemestral != null ||
                widget.planPrecioAnual != null) ...[
              const Divider(height: 24),
              if (widget.planPrecioSemestral != null)
                _buildPrecioRow(
                    'Semestral',
                    'S/ ${widget.planPrecioSemestral!.toStringAsFixed(2)}'),
              if (widget.planPrecioAnual != null)
                _buildPrecioRow(
                    'Anual',
                    'S/ ${widget.planPrecioAnual!.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrecioRow(String label, String precio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, size: 13, color: AppColors.textSecondary),
          AppText(precio,
              size: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.blue1),
        ],
      ),
    );
  }

  Widget _buildPeriodoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Selecciona el periodo de facturacion:',
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            _buildPeriodoChip(
                'MENSUAL', 'Mensual', widget.planPrecio ?? 0),
            if (widget.planPrecioSemestral != null)
              _buildPeriodoChip('SEMESTRAL', 'Semestral',
                  widget.planPrecioSemestral!),
            if (widget.planPrecioAnual != null)
              _buildPeriodoChip(
                  'ANUAL', 'Anual', widget.planPrecioAnual!),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blue1.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.blue1, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  'Total a pagar: S/ ${_montoAPagar.toStringAsFixed(2)}',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodoChip(String value, String label, double precio) {
    final isSelected = _selectedPeriodo == value;
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.blue1,
          )),
          Text(
            'S/ ${precio.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? AppColors.white.withOpacity(0.9)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.blue1,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.blue1 : AppColors.greyLight,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriodo = value);
        }
      },
    );
  }

  Widget _buildMetodoPagoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Selecciona tu metodo de pago:',
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildMetodoPagoOption(
          'YAPE',
          'Yape',
          Icons.phone_android,
          Colors.purple,
        ),
        const SizedBox(height: 8),
        _buildMetodoPagoOption(
          'PLIN',
          'Plin',
          Icons.phone_android,
          Colors.teal,
        ),
        const SizedBox(height: 8),
        _buildMetodoPagoOption(
          'TRANSFERENCIA',
          'Transferencia Bancaria',
          Icons.account_balance,
          AppColors.blue1,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSubtitle('Instrucciones de pago', fontSize: 13),
              const SizedBox(height: 8),
              AppText(
                _metodoPagoInstrucciones,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoPagoOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMetodoPago == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetodoPago = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.greyLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildComprobanteStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText(
          'Sube la captura o foto de tu comprobante de pago:',
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),

        // Boton para seleccionar imagen
        if (_selectedImage == null)
          GestureDetector(
            onTap: isLoading ? null : _showImageSourceDialog,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blue1.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: AppColors.blue1.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Toca para seleccionar imagen',
                    size: 13,
                    color: AppColors.blue1,
                  ),
                  const SizedBox(height: 4),
                  const AppText(
                    'Camara o galeria',
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

        // Vista previa de imagen seleccionada
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              // Boton para cambiar imagen
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: isLoading ? null : _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit,
                        size: 18, color: AppColors.blue1),
                  ),
                ),
              ),
              // Boton para eliminar
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () => setState(() => _selectedImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmacionStep(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.greenContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greenBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.green, size: 56),
              const SizedBox(height: 16),
              const AppSubtitle('Pago enviado', fontSize: 18),
              const SizedBox(height: 8),
              const AppText(
                'Tu pago esta siendo verificado. Te notificaremos cuando sea aprobado.',
                size: 13,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Ver mis pagos',
                onPressed: () {
                  context.go('/empresa/mis-pagos');
                },
                height: 42,
                borderRadius: 12,
                icon: const Icon(Icons.receipt_long,
                    color: AppColors.white, size: 18),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _enviarPago(BuildContext context) {
    if (widget.planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el plan seleccionado'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    context.read<PagoSuscripcionCubit>().solicitarPago(
          planSuscripcionId: widget.planId!,
          periodo: _selectedPeriodo,
          metodoPago: _selectedMetodoPago,
        );
  }
}

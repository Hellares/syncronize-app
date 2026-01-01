import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/ajuste_masivo/ajuste_masivo_cubit.dart';
import '../bloc/ajuste_masivo/ajuste_masivo_state.dart';
import '../widgets/ajuste_masivo/paso_1_seleccion_productos.dart';
import '../widgets/ajuste_masivo/paso_2_configuracion_ajuste.dart';
import '../widgets/ajuste_masivo/paso_3_preview_cambios.dart';

class AjusteMasivoPreciosPage extends StatelessWidget {
  const AjusteMasivoPreciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locator<AjusteMasivoCubit>(),
      child: const _AjusteMasivoPreciosPageContent(),
    );
  }
}

class _AjusteMasivoPreciosPageContent extends StatefulWidget {
  const _AjusteMasivoPreciosPageContent();

  @override
  State<_AjusteMasivoPreciosPageContent> createState() => _AjusteMasivoPreciosPageContentState();
}

class _AjusteMasivoPreciosPageContentState extends State<_AjusteMasivoPreciosPageContent> {
  int _currentStep = 0;

  // Estado del ajuste
  String _alcance = 'TODOS';
  List<String> _productosSeleccionadosIds = [];
  String _operacion = 'INCREMENTO';
  double _porcentaje = 5.0;
  bool _incluirVariantes = true;
  String _razon = '';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AjusteMasivoCubit, AjusteMasivoState>(
      listener: (context, state) {
        if (state is AjusteMasivoSuccess) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ajuste aplicado: ${state.resultado['resumen']['totalProductosAfectados']} productos actualizados',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Volver a la lista
          Navigator.pop(context, true);
        } else if (state is AjusteMasivoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: SmartAppBar(
          title: 'Ajuste Masivo de Precios',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildStepperHeader(),
            Expanded(child: _buildStepContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Selección', Icons.checklist),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Configurar', Icons.tune),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Preview', Icons.preview),
        ],
      ),
    );
  }

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
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Paso1SeleccionProductos(
          alcance: _alcance,
          productosSeleccionadosIds: _productosSeleccionadosIds,
          onAlcanceChanged: (value) => setState(() => _alcance = value),
          onProductosSeleccionadosChanged: (ids) => setState(() => _productosSeleccionadosIds = ids),
        );
      case 1:
        return Paso2ConfiguracionAjuste(
          operacion: _operacion,
          porcentaje: _porcentaje,
          incluirVariantes: _incluirVariantes,
          razon: _razon,
          onOperacionChanged: (value) => setState(() => _operacion = value),
          onPorcentajeChanged: (value) => setState(() => _porcentaje = value),
          onIncluirVariantesChanged: (value) => setState(() => _incluirVariantes = value),
          onRazonChanged: (value) => setState(() => _razon = value),
        );
      case 2:
        return BlocBuilder<AjusteMasivoCubit, AjusteMasivoState>(
          builder: (context, state) {
            return Paso3PreviewCambios(
              previewData: state is AjusteMasivoPreviewLoaded ? state.previewData : null,
              isLoading: state is AjusteMasivoLoading,
              onAplicarCambios: _aplicarCambios,
            );
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 10),),
            ),
          ),
          const SizedBox(width: 12),
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppColors.blue1),
                ),
                child: const Text('Anterior', style: TextStyle(fontSize: 10),),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
              ),
              child: Text(_getNextButtonLabel(), style: TextStyle(fontSize: 10),),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Siguiente';
      case 1:
        return 'Generar Preview';
      case 2:
        return 'Aplicar Cambios';
      default:
        return 'Siguiente';
    }
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentStep) {
      case 0:
        return _canProceedFromStep1() ? () => setState(() => _currentStep++) : null;
      case 1:
        return _generarPreview;
      case 2:
        return null;
      default:
        return null;
    }
  }

  bool _canProceedFromStep1() {
    if (_alcance == 'TODOS') return true;
    if (_alcance == 'SELECCIONADOS' && _productosSeleccionadosIds.isNotEmpty) return true;
    return false;
  }

  void _generarPreview() {
    setState(() => _currentStep = 2);

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;

    final dto = {
      'alcance': _alcance,
      if (_alcance == 'SELECCIONADOS') 'productosIds': _productosSeleccionadosIds,
      'tipoAjuste': 'PORCENTAJE',
      'valor': _porcentaje,
      'operacion': _operacion,
      'incluirVariantes': _incluirVariantes,
      'redondeo': 'DOS_DECIMALES',
      if (_razon.isNotEmpty) 'razon': _razon,
    };

    context.read<AjusteMasivoCubit>().generarPreview(
          empresaId: empresaId,
          dto: dto,
        );
  }

  Future<void> _aplicarCambios() async {
    // Leer el estado ANTES de mostrar el diálogo
    final state = context.read<AjusteMasivoCubit>().state;
    int totalProductos = 0;
    if (state is AjusteMasivoPreviewLoaded) {
      final resumen = state.previewData['resumen'];
      if (resumen != null && resumen is Map) {
        totalProductos = resumen['totalProductosAfectados'] ?? 0;
      }
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Ajuste'),
        content: Text(
          '¿Estás seguro de aplicar el ajuste de ${_operacion == 'INCREMENTO' ? '+' : '-'}$_porcentaje% '
          'a $totalProductos productos?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Verificar que el widget todavía está montado después del diálogo
    if (!mounted) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;

    final dto = {
      'alcance': _alcance,
      if (_alcance == 'SELECCIONADOS') 'productosIds': _productosSeleccionadosIds,
      'tipoAjuste': 'PORCENTAJE',
      'valor': _porcentaje,
      'operacion': _operacion,
      'incluirVariantes': _incluirVariantes,
      'redondeo': 'DOS_DECIMALES',
      if (_razon.isNotEmpty) 'razon': _razon,
    };

    context.read<AjusteMasivoCubit>().aplicarAjuste(
          empresaId: empresaId,
          dto: dto,
        );
  }
}

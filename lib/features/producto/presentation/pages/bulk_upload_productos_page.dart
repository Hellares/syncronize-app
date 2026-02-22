import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/bulk_upload_result.dart';
import '../bloc/bulk_upload/bulk_upload_cubit.dart';
import '../bloc/bulk_upload/bulk_upload_state.dart';

class BulkUploadProductosPage extends StatelessWidget {
  const BulkUploadProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locator<BulkUploadCubit>(),
      child: const _BulkUploadContent(),
    );
  }
}

class _BulkUploadContent extends StatefulWidget {
  const _BulkUploadContent();

  @override
  State<_BulkUploadContent> createState() => _BulkUploadContentState();
}

class _BulkUploadContentState extends State<_BulkUploadContent> {
  int _currentStep = 0;
  String? _selectedFilePath;
  String? _selectedFileName;
  List<String> _selectedSedesIds = [];
  bool _templateDownloaded = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BulkUploadCubit, BulkUploadState>(
      listener: (context, state) {
        if (state is BulkUploadTemplateDownloaded) {
          setState(() => _templateDownloaded = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantilla guardada en: ${state.filePath}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is BulkUploadSuccess) {
          setState(() => _currentStep = 2);
        } else if (state is BulkUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          title: 'Carga Masiva de Productos',
          centerTitle: false,
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
                _buildStepperHeader(),
                Expanded(child: _buildStepContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Archivo'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Subir'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Resultado'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.blue1 : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: AppColors.blue1, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.blue1 : Colors.grey,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isCompleted ? AppColors.blue1 : Colors.grey.shade300,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================
  // PASO 1: Descargar plantilla y seleccionar archivo
  // ============================
  Widget _buildStep1() {
    return BlocBuilder<BulkUploadCubit, BulkUploadState>(
      builder: (context, state) {
        final isDownloading = state is BulkUploadDownloadingTemplate;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.blue1, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Instrucciones',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600).copyWith(color: AppColors.blue1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Descarga la plantilla Excel con las columnas requeridas\n'
                      '2. Completa los datos de tus productos (solo el Nombre es obligatorio)\n'
                      '3. Las categorias, marcas y unidades deben coincidir con las registradas en tu empresa\n'
                      '4. Selecciona el archivo completado y sube para procesar',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Aviso de límite de registros
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'El archivo puede contener hasta 1000 registros por carga. '
                        'Si tienes mas productos, divide el archivo en partes.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Boton descargar plantilla
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isDownloading
                      ? null
                      : () => context.read<BulkUploadCubit>().downloadTemplate(),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _templateDownloaded ? Icons.check_circle : Icons.download,
                          color: _templateDownloaded ? Colors.green : null,
                        ),
                  label: Text(
                    isDownloading
                        ? 'Descargando...'
                        : _templateDownloaded
                            ? 'Plantilla descargada'
                            : 'Descargar Plantilla Excel',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: _templateDownloaded ? Colors.green : AppColors.blue1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Separador
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Luego selecciona tu archivo',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Boton seleccionar archivo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleccionar Archivo Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // Archivo seleccionado
              if (_selectedFileName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Archivo listo para subir',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedFilePath = null;
                            _selectedFileName = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Boton continuar
              if (_selectedFilePath != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
        });
      }
    }
  }

  // ============================
  // PASO 2: Seleccionar sedes y confirmar
  // ============================
  Widget _buildStep2() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return BlocBuilder<BulkUploadCubit, BulkUploadState>(
      builder: (context, state) {
        final isUploading = state is BulkUploadUploading;

        if (isUploading) {
          return CustomLoading.small(
            message: 'Procesando archivo...',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen del archivo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.blue1, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Archivo seleccionado',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Seleccion de sedes (si hay multiples)
              if (sedes.length > 1) ...[
                Text(
                  'Sedes donde crear stock',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selecciona en que sedes se creara el stock inicial de los productos',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...sedes.map((sede) {
                  final isSelected = _selectedSedesIds.contains(sede.id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(sede.nombre),
                    subtitle: sede.esPrincipal
                        ? const Text('Sede principal',
                            style: TextStyle(fontSize: 12, color: Colors.blue))
                        : null,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSedesIds.add(sede.id);
                        } else {
                          _selectedSedesIds.remove(sede.id);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Las filas con errores seran ignoradas y se reportaran. '
                        'Las filas validas se crearan como productos nuevos.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Atras'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _uploadFile,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Subir y Procesar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _uploadFile() {
    if (_selectedFilePath == null || _selectedFileName == null) return;

    context.read<BulkUploadCubit>().uploadExcel(
          filePath: _selectedFilePath!,
          fileName: _selectedFileName!,
          sedesIds: _selectedSedesIds.isNotEmpty ? _selectedSedesIds : null,
        );
  }

  // ============================
  // PASO 3: Resultados
  // ============================
  Widget _buildStep3() {
    return BlocBuilder<BulkUploadCubit, BulkUploadState>(
      builder: (context, state) {
        if (state is! BulkUploadSuccess) {
          return const SizedBox.shrink();
        }

        final result = state.result;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen
              _buildResultSummary(result),
              const SizedBox(height: 20),

              // Productos creados
              if (result.creados > 0) ...[
                Text(
                  'Productos creados (${result.creados})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600).copyWith(color: Colors.green.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.productosCreados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prod = result.productosCreados[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                        title: Text(prod.nombre,
                            style: const TextStyle(fontSize: 13)),
                        trailing: Text(prod.codigoEmpresa,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Errores
              if (result.errores > 0) ...[
                Text(
                  'Errores encontrados (${result.errores})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600).copyWith(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.detalleErrores.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final error = result.detalleErrores[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        title: Text(
                          'Fila ${error.fila} - ${error.columna}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          error.mensaje,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: error.valor.isNotEmpty
                            ? Text(
                                error.valor,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.list),
                      label: const Text('Ir a Productos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep = 0;
                          _selectedFilePath = null;
                          _selectedFileName = null;
                          _selectedSedesIds = [];
                        });
                        context.read<BulkUploadCubit>().reset();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Subir Otro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultSummary(BulkUploadResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.errores == 0
            ? Colors.green.shade50
            : result.creados == 0
                ? Colors.red.shade50
                : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.errores == 0
              ? Colors.green.shade300
              : result.creados == 0
                  ? Colors.red.shade300
                  : Colors.orange.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            result.errores == 0
                ? Icons.check_circle_outline
                : result.creados == 0
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
            size: 48,
            color: result.errores == 0
                ? Colors.green
                : result.creados == 0
                    ? Colors.red
                    : Colors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            result.errores == 0
                ? 'Carga exitosa'
                : result.creados == 0
                    ? 'No se crearon productos'
                    : 'Carga parcial',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem('Total filas', '${result.totalFilas}', Colors.grey),
              _buildSummaryItem('Creados', '${result.creados}', Colors.green),
              _buildSummaryItem('Errores', '${result.errores}', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

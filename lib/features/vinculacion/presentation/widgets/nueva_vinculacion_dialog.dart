import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../../../cliente_empresa/domain/entities/cliente_empresa.dart';
import '../../../cliente_empresa/domain/repositories/cliente_empresa_repository.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../data/datasources/vinculacion_remote_datasource.dart';
import '../bloc/vinculacion_action/vinculacion_action_cubit.dart';
import '../bloc/vinculacion_action/vinculacion_action_state.dart';

class NuevaVinculacionDialog extends StatefulWidget {
  const NuevaVinculacionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<VinculacionActionCubit>()),
          BlocProvider.value(value: context.read<EmpresaContextCubit>()),
        ],
        child: const NuevaVinculacionDialog(),
      ),
    );
  }

  @override
  State<NuevaVinculacionDialog> createState() => _NuevaVinculacionDialogState();
}

enum _DialogMode { initial, vinculable, noTenant }

class _NuevaVinculacionDialogState extends State<NuevaVinculacionDialog> {
  final _rucController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _isChecking = false;
  bool _isSending = false;
  String? _errorMessage;

  // Resultado check-ruc (empresa tenant encontrada)
  Map<String, dynamic>? _checkResult;

  // Resultado consulta SUNAT (no es tenant)
  ConsultaRuc? _sunatResult;

  _DialogMode _mode = _DialogMode.initial;

  @override
  void dispose() {
    _rucController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _checkRuc() async {
    final ruc = _rucController.text.trim();
    if (ruc.length != 11 || !RegExp(r'^\d{11}$').hasMatch(ruc)) {
      setState(() { _errorMessage = 'El RUC debe tener 11 digitos'; _mode = _DialogMode.initial; });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _checkResult = null;
      _sunatResult = null;
      _mode = _DialogMode.initial;
    });

    try {
      final ds = locator<VinculacionRemoteDataSource>();
      final data = await ds.checkRucRaw(ruc);

      if (!mounted) return;

      if (data != null) {
        // Empresa tenant encontrada
        setState(() { _isChecking = false; _checkResult = data; _mode = _DialogMode.vinculable; });
      } else {
        // No es tenant → consultar SUNAT
        await _consultarSunat(ruc);
      }
    } catch (e) {
      if (mounted) setState(() { _isChecking = false; _errorMessage = 'Error al verificar RUC'; });
    }
  }

  Future<void> _consultarSunat(String ruc) async {
    try {
      final useCase = locator<ConsultarRucUseCase>();
      final result = await useCase(ruc);

      if (!mounted) return;

      if (result is Success<ConsultaRuc>) {
        setState(() { _isChecking = false; _sunatResult = result.data; _mode = _DialogMode.noTenant; });
      } else if (result is Error<ConsultaRuc>) {
        setState(() { _isChecking = false; _errorMessage = 'RUC no encontrado en SUNAT'; });
      }
    } catch (e) {
      if (mounted) setState(() { _isChecking = false; _errorMessage = 'Error al consultar SUNAT'; });
    }
  }

  void _enviarVinculacion() {
    if (_checkResult == null) return;
    setState(() => _isSending = true);

    final clienteEmpresaId = _checkResult!['clienteEmpresaId'] as String?;
    final ruc = _rucController.text.trim();

    if (clienteEmpresaId != null) {
      context.read<VinculacionActionCubit>().crear(
        clienteEmpresaId: clienteEmpresaId,
        mensaje: _mensajeController.text.trim().isEmpty ? null : _mensajeController.text.trim(),
      );
    } else {
      context.read<VinculacionActionCubit>().crearConRuc(
        ruc: ruc,
        mensaje: _mensajeController.text.trim().isEmpty ? null : _mensajeController.text.trim(),
      );
    }
  }

  Future<void> _registrarComoCliente() async {
    if (_sunatResult == null) return;
    setState(() => _isSending = true);

    final empresaState = context.read<EmpresaContextCubit>().state;
    final empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';

    if (empresaId.isEmpty) {
      setState(() { _isSending = false; _errorMessage = 'No se pudo obtener la empresa actual'; });
      return;
    }

    final repo = locator<ClienteEmpresaRepository>();
    final result = await repo.crearClienteEmpresa(
      empresaId: empresaId,
      razonSocial: _sunatResult!.razonSocial,
      numeroDocumento: _sunatResult!.ruc,
      direccion: _sunatResult!.direccion,
      departamento: _sunatResult!.departamento,
      provincia: _sunatResult!.provincia,
      distrito: _sunatResult!.distrito,
      estadoContribuyente: _sunatResult!.estado,
      condicionContribuyente: _sunatResult!.condicion,
      ubigeo: _sunatResult!.ubigeo,
    );

    if (!mounted) return;

    if (result is Success<ClienteEmpresaCreado>) {
      Navigator.pop(context, true);
      SnackBarHelper.showSuccess(context, 'Cliente empresa registrado exitosamente');
    } else if (result is Error<ClienteEmpresaCreado>) {
      setState(() { _isSending = false; _errorMessage = result.message; });
    }
  }

  bool get _canVincular {
    if (_checkResult == null) return false;
    final yaVinculada = _checkResult!['yaVinculada'] as bool? ?? false;
    final vinculacionExistente = _checkResult!['vinculacionExistente'];
    return !yaVinculada && vinculacionExistente == null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VinculacionActionCubit, VinculacionActionState>(
      listener: (context, state) {
        if (state is VinculacionActionSuccess) {
          Navigator.pop(context, true);
          SnackBarHelper.showSuccess(context, state.mensaje);
        } else if (state is VinculacionActionError) {
          setState(() { _isSending = false; _errorMessage = state.message; });
        }
      },
      child: AlertDialog(
        title: const Text('Nueva Vinculacion', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa el RUC de la empresa',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // RUC input + buscar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rucController,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: InputDecoration(
                          labelText: 'RUC',
                          hintText: '20123456789',
                          counterText: '',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          errorText: _errorMessage,
                          errorMaxLines: 2,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) {
                          if (_mode != _DialogMode.initial || _errorMessage != null) {
                            setState(() {
                              _mode = _DialogMode.initial;
                              _checkResult = null;
                              _sunatResult = null;
                              _errorMessage = null;
                            });
                          }
                        },
                        onSubmitted: (_) => _checkRuc(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkRuc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isChecking
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),

                // Resultado: empresa tenant encontrada
                if (_mode == _DialogMode.vinculable && _checkResult != null) ...[
                  const SizedBox(height: 16),
                  _buildVinculableResult(),
                ],

                // Resultado: no es tenant, datos SUNAT
                if (_mode == _DialogMode.noTenant && _sunatResult != null) ...[
                  const SizedBox(height: 16),
                  _buildSunatResult(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          if (_mode == _DialogMode.vinculable && _canVincular)
            ElevatedButton(
              onPressed: _isSending ? null : _enviarVinculacion,
              child: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar solicitud'),
            ),
          if (_mode == _DialogMode.noTenant && _sunatResult != null)
            ElevatedButton(
              onPressed: _isSending ? null : _registrarComoCliente,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrar cliente'),
            ),
        ],
      ),
    );
  }

  Widget _buildVinculableResult() {
    final nombre = _checkResult!['nombre'] as String? ?? '';
    final rubro = _checkResult!['rubro'] as String?;
    final clienteEmpresaId = _checkResult!['clienteEmpresaId'];
    final yaVinculada = _checkResult!['yaVinculada'] as bool? ?? false;
    final vinculacionExistente = _checkResult!['vinculacionExistente'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade900),
                ),
              ),
            ],
          ),
          if (rubro != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(rubro, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(
              'Esta empresa usa la plataforma',
              style: TextStyle(fontSize: 10, color: Colors.green.shade600),
            ),
          ),
          const SizedBox(height: 8),

          if (yaVinculada) ...[
            _statusRow(Icons.link, 'Ya esta vinculada', Colors.blue),
          ] else if (vinculacionExistente != null) ...[
            _statusRow(
              Icons.hourglass_empty,
              'Ya tiene solicitud ${(vinculacionExistente['estado'] as String?)?.toLowerCase() ?? 'activa'}',
              Colors.orange,
            ),
          ] else ...[
            _statusRow(Icons.check, clienteEmpresaId != null
                ? 'Lista para vincular'
                : 'Se registrara como cliente automaticamente', Colors.green),
            const SizedBox(height: 8),
            TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSunatResult() {
    final sunat = _sunatResult!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No usa la plataforma',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sunat.razonSocial,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          _sunatRow(Icons.badge_outlined, 'RUC', sunat.ruc),
          _sunatRow(Icons.location_on_outlined, 'Direccion', sunat.direccionCompleta),
          _sunatRow(Icons.verified_outlined, 'Estado', '${sunat.estado} - ${sunat.condicion}'),
          const SizedBox(height: 8),
          Text(
            'Puedes registrarla como Cliente Empresa',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _sunatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        const SizedBox(width: 26),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

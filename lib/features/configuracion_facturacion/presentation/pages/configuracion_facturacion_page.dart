import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/environment/env_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/configuracion_facturacion.dart';
import '../bloc/configuracion_facturacion_cubit.dart';
import '../bloc/configuracion_facturacion_state.dart';

class ConfiguracionFacturacionPage extends StatelessWidget {
  const ConfiguracionFacturacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ConfiguracionFacturacionCubit>()..cargar(),
      child: const _ConfiguracionFacturacionView(),
    );
  }
}

class _ConfiguracionFacturacionView extends StatelessWidget {
  const _ConfiguracionFacturacionView();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Configuración de Facturación'),
        body: BlocConsumer<ConfiguracionFacturacionCubit,
            ConfiguracionFacturacionState>(
          listener: (context, state) {
            if (state is ConfiguracionFacturacionLoaded &&
                state.mensajeExito != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensajeExito!),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            } else if (state is ConfiguracionFacturacionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensaje),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ConfiguracionFacturacionLoading ||
                state is ConfiguracionFacturacionInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ConfiguracionFacturacionError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(state.mensaje,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade400)),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: () =>
                            context.read<ConfiguracionFacturacionCubit>().cargar(),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is ConfiguracionFacturacionLoaded) {
              return _FormView(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final ConfiguracionFacturacionLoaded state;
  const _FormView({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(state: state),
                  const SizedBox(height: 10),
                  _ProveedorSection(state: state),
                  if (state.editada.proveedorActivo ==
                      ProveedorFacturacion.syncrofact) ...[
                    const SizedBox(height: 10),
                    const _WebhookSection(),
                  ],
                  const SizedBox(height: 10),
                  _DatosEmpresaSection(state: state),
                  if (state.resultadoPrueba != null) ...[
                    const SizedBox(height: 10),
                    _ResultadoPruebaCard(resultado: state.resultadoPrueba!),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _Footer(state: state),
        ],
      ),
    );
  }
}

// ── Header: estado general ──

class _HeaderCard extends StatelessWidget {
  final ConfiguracionFacturacionLoaded state;
  const _HeaderCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConfiguracionFacturacionCubit>();
    final editada = state.editada;
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: AppColors.blue1),
                const SizedBox(width: 6),
                const Text(
                  'Estado',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _proveedorBadge(editada.proveedorActivo),
                const SizedBox(width: 6),
                _entornoBadge(editada.entorno),
              ],
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Facturación electrónica activa',
              subtitle: editada.facturacionActiva
                  ? 'Los comprobantes se enviarán al proveedor'
                  : 'Los comprobantes NO se enviarán a SUNAT',
              value: editada.facturacionActiva,
              onChanged: cubit.cambiarFacturacionActiva,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _proveedorBadge(ProveedorFacturacion p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(p.label,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.indigo,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _entornoBadge(EntornoFacturacion e) {
    final esProd = e == EntornoFacturacion.produccion;
    final color = esProd ? Colors.red.shade600 : Colors.amber.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(esProd ? 'PROD' : 'BETA',
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Sección Proveedor ──

class _ProveedorSection extends StatefulWidget {
  final ConfiguracionFacturacionLoaded state;
  const _ProveedorSection({required this.state});

  @override
  State<_ProveedorSection> createState() => _ProveedorSectionState();
}

class _ProveedorSectionState extends State<_ProveedorSection> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _branchCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.state.editada;
    _urlCtrl = TextEditingController(text: e.proveedorRuta ?? '');
    _tokenCtrl = TextEditingController(text: e.proveedorToken ?? '');
    _companyCtrl = TextEditingController(text: e.companyId?.toString() ?? '');
    _branchCtrl = TextEditingController(text: e.branchId?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProveedorSection old) {
    super.didUpdateWidget(old);
    final e = widget.state.editada;
    _syncCtrl(_urlCtrl, e.proveedorRuta ?? '');
    _syncCtrl(_tokenCtrl, e.proveedorToken ?? '');
    _syncCtrl(_companyCtrl, e.companyId?.toString() ?? '');
    _syncCtrl(_branchCtrl, e.branchId?.toString() ?? '');
  }

  void _syncCtrl(TextEditingController ctrl, String value) {
    if (ctrl.text != value) {
      ctrl.text = value;
      ctrl.selection =
          TextSelection.fromPosition(TextPosition(offset: value.length));
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    _companyCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConfiguracionFacturacionCubit>();
    final editada = widget.state.editada;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Proveedor', Icons.cloud_outlined),
            const SizedBox(height: 10),
            CustomDropdown<ProveedorFacturacion>(
              label: 'Proveedor de facturación',
              value: editada.proveedorActivo,
              borderColor: AppColors.blue1,
              items: ProveedorFacturacion.values
                  .map((p) => DropdownItem<ProveedorFacturacion>(
                      value: p, label: p.label))
                  .toList(),
              onChanged: (v) {
                if (v != null) _confirmarCambioProveedor(v, cubit);
              },
            ),
            const SizedBox(height: 10),
            CustomDropdown<EntornoFacturacion>(
              label: 'Entorno',
              value: editada.entorno,
              borderColor: AppColors.blue1,
              items: EntornoFacturacion.values
                  .map((e) => DropdownItem<EntornoFacturacion>(
                      value: e, label: e.label))
                  .toList(),
              onChanged: (v) {
                if (v != null) cubit.cambiarEntorno(v);
              },
            ),
            if (editada.entorno == EntornoFacturacion.produccion) ...[
              const SizedBox(height: 8),
              _warningBanner(
                'Modo PRODUCCIÓN: los comprobantes irán a SUNAT real.',
              ),
            ],
            const SizedBox(height: 10),
            CustomText(
              controller: _urlCtrl,
              label: 'URL del proveedor',
              hintText: 'https://api-beta.syncrofact.net.pe/api',
              keyboardType: TextInputType.url,
              borderColor: AppColors.blue1,
              onChanged: cubit.cambiarUrl,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _tokenCtrl,
              label: 'Token / credencial',
              obscureText: true,
              borderColor: AppColors.blue1,
              onChanged: cubit.cambiarToken,
            ),
            if (editada.proveedorActivo.requiereCompanyBranch) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      controller: _companyCtrl,
                      label: 'Company ID',
                      fieldType: FieldType.number,
                      borderColor: AppColors.blue1,
                      onChanged: (v) =>
                          cubit.cambiarCompanyId(int.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      controller: _branchCtrl,
                      label: 'Branch ID',
                      fieldType: FieldType.number,
                      borderColor: AppColors.blue1,
                      onChanged: (v) =>
                          cubit.cambiarBranchId(int.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarCambioProveedor(
    ProveedorFacturacion nuevo,
    ConfiguracionFacturacionCubit cubit,
  ) async {
    final actual = widget.state.editada.proveedorActivo;
    if (nuevo == actual) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar proveedor'),
        content: Text(
          'Cambiarás de ${actual.label} a ${nuevo.label}.\n\n'
          'Los comprobantes ya emitidos seguirán consultándose con su proveedor original '
          'y no se modifican. Los nuevos comprobantes se emitirán con ${nuevo.label}.\n\n'
          'Después del cambio recomendamos sincronizar series.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.cambiarProveedor(nuevo);
  }
}

// ── Sección Webhook (info para copiar al panel Syncrofact) ──

class _WebhookSection extends StatelessWidget {
  const _WebhookSection();

  String get _webhookUrl => '${EnvConfig.baseUrl}/webhooks/syncrofact';

  Future<void> _copiar(BuildContext context, String texto, String etiqueta) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$etiqueta copiada'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Webhook', Icons.webhook_outlined),
            const SizedBox(height: 8),
            Text(
              'Pega esta URL en el panel de Syncrofact al crear el webhook '
              'de tu empresa. El secret te lo proporciona el administrador del sistema.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            _CampoCopiable(
              label: 'URL del webhook',
              valor: _webhookUrl,
              onCopiar: () => _copiar(context, _webhookUrl, 'URL'),
            ),
            const SizedBox(height: 8),
            _CampoCopiable(
              label: 'Eventos a suscribir',
              valor: 'invoice.*, daily_summary.*, communication.*',
              onCopiar: () => _copiar(
                context,
                'invoice.*, daily_summary.*, communication.*',
                'Lista de eventos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoCopiable extends StatefulWidget {
  final String label;
  final String valor;
  final VoidCallback onCopiar;

  const _CampoCopiable({
    required this.label,
    required this.valor,
    required this.onCopiar,
  });

  @override
  State<_CampoCopiable> createState() => _CampoCopiableState();
}

class _CampoCopiableState extends State<_CampoCopiable> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valor);
  }

  @override
  void didUpdateWidget(covariant _CampoCopiable old) {
    super.didUpdateWidget(old);
    if (old.valor != widget.valor && _ctrl.text != widget.valor) {
      _ctrl.text = widget.valor;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo lectura: campo informativo para copiar al panel de Syncrofact.
    return CustomText(
      controller: _ctrl,
      label: widget.label,
      readOnly: true,
      borderColor: AppColors.blue1,
      autovalidateMode: AutovalidateModeX.disabled,
      showValidationIndicator: false,
      suffixIcon: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: widget.onCopiar,
        tooltip: 'Copiar al portapapeles',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

// ── Sección Datos Empresa ──

class _DatosEmpresaSection extends StatefulWidget {
  final ConfiguracionFacturacionLoaded state;
  const _DatosEmpresaSection({required this.state});

  @override
  State<_DatosEmpresaSection> createState() => _DatosEmpresaSectionState();
}

class _DatosEmpresaSectionState extends State<_DatosEmpresaSection> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _resolucionCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.state.editada;
    _emailCtrl = TextEditingController(text: e.emailFacturacion ?? '');
    _resolucionCtrl = TextEditingController(text: e.resolucionSunat ?? '');
  }

  @override
  void didUpdateWidget(covariant _DatosEmpresaSection old) {
    super.didUpdateWidget(old);
    final e = widget.state.editada;
    _syncCtrl(_emailCtrl, e.emailFacturacion ?? '');
    _syncCtrl(_resolucionCtrl, e.resolucionSunat ?? '');
  }

  void _syncCtrl(TextEditingController ctrl, String value) {
    if (ctrl.text != value) {
      ctrl.text = value;
      ctrl.selection =
          TextSelection.fromPosition(TextPosition(offset: value.length));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _resolucionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConfiguracionFacturacionCubit>();
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Datos de facturación', Icons.business_outlined),
            const SizedBox(height: 10),
            CustomText(
              controller: _emailCtrl,
              label: 'Email de facturación',
              hintText: 'facturacion@miempresa.pe',
              fieldType: FieldType.email,
              required: false,
              borderColor: AppColors.blue1,
              onChanged: (v) =>
                  cubit.cambiarEmailFacturacion(v.trim().isEmpty ? null : v),
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _resolucionCtrl,
              label: 'Resolución SUNAT (opcional)',
              hintText: 'No.034-005-0005315',
              borderColor: AppColors.blue1,
              onChanged: (v) =>
                  cubit.cambiarResolucionSunat(v.trim().isEmpty ? null : v),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resultado de prueba ──

class _ResultadoPruebaCard extends StatelessWidget {
  final ResultadoProbarConexion resultado;
  const _ResultadoPruebaCard({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final color = resultado.ok ? Colors.green : Colors.red;
    return GradientContainer(
      borderColor: color.shade200,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(resultado.ok ? Icons.check_circle : Icons.error_outline,
                    size: 16, color: color.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(resultado.mensaje,
                      style: TextStyle(
                          fontSize: 12,
                          color: color.shade700,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (resultado.error != null) ...[
              const SizedBox(height: 4),
              Text(resultado.error!,
                  style: TextStyle(fontSize: 10, color: color.shade500)),
            ],
            if (resultado.branches.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Sucursales detectadas:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ...resultado.branches.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${b.codigo} · ${b.nombre}  (${b.totalSeries} serie${b.totalSeries == 1 ? '' : 's'})',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Footer ──

class _Footer extends StatelessWidget {
  final ConfiguracionFacturacionLoaded state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConfiguracionFacturacionCubit>();
    final puedeGuardar = state.tieneCambios && !state.guardando;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: state.probando ? 'Probando...' : 'Probar conexión',
              textColor: AppColors.blue1,
              icon: const Icon(Icons.wifi_tethering, size: 16),
              borderColor: AppColors.blue1,
              isLoading: state.probando,
              onPressed: state.probando ? null : cubit.probarConexion,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: state.guardando ? 'Guardando...' : 'Guardar',
              icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              isLoading: state.guardando,
              enabled: puedeGuardar,
              onPressed: puedeGuardar ? cubit.guardar : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers compartidos ──

Widget _sectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.blue1),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );
}

Widget _warningBanner(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber, size: 14, color: Colors.red.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
        ),
      ],
    ),
  );
}

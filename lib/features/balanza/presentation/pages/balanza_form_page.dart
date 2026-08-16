import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../domain/entities/balanza_config.dart';
import '../../domain/entities/lectura_peso.dart';
import '../../domain/entities/perfil_trama.dart';
import '../../domain/services/balanzas_manager.dart';
import '../../domain/services/trama_balanza_parser.dart';
import '../widgets/balanza_visor_sheet.dart';

/// Alta y edición de una balanza.
///
/// Lo que hace útil a esta pantalla no es el formulario sino el **probador de
/// trama** del final: se pega una línea real de la balanza y se ve, en vivo,
/// qué peso se está entendiendo y si la lectura sale estable. Sin eso, ajustar
/// un patrón contra una marca que nadie documentó es adivinar.
class BalanzaFormPage extends StatefulWidget {
  /// null = alta.
  final BalanzaConfig? balanza;

  const BalanzaFormPage({super.key, this.balanza});

  @override
  State<BalanzaFormPage> createState() => _BalanzaFormPageState();
}

class _BalanzaFormPageState extends State<BalanzaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _manager = locator<BalanzasManager>();

  late final TextEditingController _nombre;
  late final TextEditingController _direccion;
  late final TextEditingController _patron;
  late final TextEditingController _tokensEstable;
  late final TextEditingController _terminador;
  late final TextEditingController _comandoPeso;
  late final TextEditingController _comandoTara;

  /// Lo que se teclea en el probador. Arranca con un ejemplo del preset para
  /// que la pantalla se explique sola al abrirla.
  late final TextEditingController _prueba;

  late TipoTransporte _transporte;
  late UnidadPeso _unidad;
  late bool _exigeEstable;
  late bool _esPrincipal;

  /// Preset elegido. `null` = personalizado (se tocó el patrón a mano).
  PerfilTrama? _preset;

  bool _guardando = false;

  bool get _esEdicion => widget.balanza != null;

  @override
  void initState() {
    super.initState();
    final b = widget.balanza;
    final perfil = b?.perfil ?? PerfilesTrama.casToledo;

    _nombre = TextEditingController(text: b?.nombre ?? '');
    _direccion = TextEditingController(text: b?.direccion ?? '');
    _patron = TextEditingController(text: perfil.patron);
    _tokensEstable = TextEditingController(text: perfil.tokensEstable.join(', '));
    _terminador = TextEditingController(text: PerfilTrama.escapar(perfil.terminador));
    _comandoPeso =
        TextEditingController(text: PerfilTrama.escapar(perfil.comandoPedirPeso));
    _comandoTara =
        TextEditingController(text: PerfilTrama.escapar(perfil.comandoTara));
    _prueba = TextEditingController(text: 'ST,GS,+  1.234kg');

    _transporte = b?.transporte ?? TipoTransporte.clasico;
    _unidad = perfil.unidadPorDefecto;
    _exigeEstable = perfil.exigeEstable;
    _esPrincipal = b?.esPrincipal ?? false;
    _preset = PerfilesTrama.todos
        .where((p) => p.patron == perfil.patron)
        .cast<PerfilTrama?>()
        .firstWhere((p) => true, orElse: () => null);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _patron.dispose();
    _tokensEstable.dispose();
    _terminador.dispose();
    _comandoPeso.dispose();
    _comandoTara.dispose();
    _prueba.dispose();
    super.dispose();
  }

  /// El perfil tal como quedaría con lo que hay escrito ahora mismo. Lo usan
  /// el probador y el guardado, así que lo que se prueba es exactamente lo que
  /// se guarda.
  PerfilTrama get _perfilActual => PerfilTrama(
        nombre: _preset?.nombre ?? 'Personalizado',
        patron: _patron.text.trim(),
        unidadPorDefecto: _unidad,
        tokensEstable: _tokensEstable.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        exigeEstable: _exigeEstable,
        terminador: PerfilTrama.desescapar(_terminador.text),
        comandoPedirPeso: PerfilTrama.desescapar(_comandoPeso.text),
        comandoTara: PerfilTrama.desescapar(_comandoTara.text),
      );

  void _aplicarPreset(PerfilTrama? p) {
    if (p == null) return;
    setState(() {
      _preset = p;
      _patron.text = p.patron;
      _tokensEstable.text = p.tokensEstable.join(', ');
      _terminador.text = PerfilTrama.escapar(p.terminador);
      _comandoPeso.text = PerfilTrama.escapar(p.comandoPedirPeso);
      _comandoTara.text = PerfilTrama.escapar(p.comandoTara);
      _unidad = p.unidadPorDefecto;
      _exigeEstable = p.exigeEstable;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final config = BalanzaConfig(
        id: widget.balanza?.id ?? '',
        nombre: _nombre.text.trim(),
        transporte: _transporte,
        direccion: _direccion.text.trim(),
        perfil: _perfilActual,
        esPrincipal: _esPrincipal,
      );
      if (_esEdicion) {
        await _manager.actualizar(config);
      } else {
        await _manager.crear(config);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      SnackBarHelper.showError(context, 'No se pudo guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: _esEdicion ? 'Editar balanza' : 'Nueva balanza',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: Form(
          key: _formKey,
          child: ListView(
            // 🔴 El inset de abajo va SUMADO: sin él, "Guardar" queda debajo
            // de la barra de navegación del celular —se ve, pero no se puede
            // tocar—. Un `SafeArea` alrededor no sirve acá: el scroll tiene que
            // llegar hasta el borde, lo que necesita respiro es el CONTENIDO.
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
            children: [
              _seccion('EQUIPO'),
              CustomText(
                controller: _nombre,
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
                label: 'Nombre *',
                hintText: 'Balanza mostrador',
                prefixIcon: const Icon(Icons.scale),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 10),
              CustomDropdown<TipoTransporte>(
                value: _transporte,
                label: 'Tipo de conexión',
                borderColor: AppColors.blue1,
                // `elegibles` y no `values`: en un build de producción el
                // simulador ni siquiera aparece en la lista.
                items: TipoTransporte.elegibles
                    .map((t) => DropdownItem(value: t, label: t.label))
                    .toList(),
                onChanged: (v) => setState(() => _transporte = v ?? _transporte),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: AppSubtitle(
                  _transporte.ayuda,
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              // 🔴 Sin este aviso, una balanza se configura entera y recién al
              // ir a pesar aparece que ese transporte no lee nada. Pasó: se
              // creó una llamada "SIMULADOR" pero con la conexión en el default
              // (clásico), y el visor solo dejaba escribir a mano.
              if (!_transporte.puedeConectar)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              'Esta conexión todavía no puede leer el peso',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                            const SizedBox(height: 2),
                            AppSubtitle(
                              'La balanza se guarda igual, pero al pesar solo se '
                              'va a poder escribir a mano. Para ver el flujo '
                              'completo ahora, elegí «Simulador».',
                              fontSize: 10,
                              color: Colors.orange.shade900,
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => setState(
                                  () => _transporte = TipoTransporte.simulador),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: AppSubtitle(
                                  'Usar el simulador →',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blue1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              CustomText(
                controller: _direccion,
                borderColor: AppColors.blue1,
                label: 'Dirección del equipo',
                hintText: '00:11:22:33:44:55',
                prefixIcon: const Icon(Icons.bluetooth),
              ),
              // El buscador de equipos llega con el transporte real. Se dice
              // acá y no se esconde: dejar un botón muerto es peor que no
              // tenerlo.
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: AppSubtitle(
                  'La búsqueda de equipos cercanos se habilita al conectar la '
                  'balanza. Por ahora se pega la dirección a mano.',
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),

              _seccion('CÓMO LEE EL PESO'),
              AppSubtitle(
                'Cada marca manda su propia trama. Elegí el formato más '
                'parecido y ajustalo con el probador de abajo.',
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              CustomDropdown<PerfilTrama>(
                value: _preset,
                label: 'Formato de trama',
                hintText: 'Personalizado',
                borderColor: AppColors.blue1,
                items: PerfilesTrama.todos
                    .map((p) => DropdownItem(value: p, label: p.nombre))
                    .toList(),
                onChanged: _aplicarPreset,
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: _patron,
                borderColor: AppColors.blue1,
                label: 'Patrón (regex)',
                hintText: r'(?<peso>\d+(?:[.,]\d+)?)',
                prefixIcon: const Icon(Icons.code),
                // Tocar el patrón deja de ser un preset: decirlo evita que el
                // desplegable siga mostrando un nombre que ya no corresponde.
                onChanged: (_) => setState(() => _preset = null),
                validator: (v) => (v == null || !v.contains('(?<peso>'))
                    ? 'Tiene que capturar un grupo llamado (?<peso>...)'
                    : null,
              ),
              const SizedBox(height: 10),
              CustomDropdown<UnidadPeso>(
                value: _unidad,
                label: 'Unidad que reporta',
                borderColor: AppColors.blue1,
                items: UnidadPeso.values
                    .map((u) => DropdownItem(value: u, label: u.label))
                    .toList(),
                onChanged: (v) => setState(() => _unidad = v ?? _unidad),
              ),
              const SizedBox(height: 4),
              AppSubtitle(
                'Se usa solo si la trama no dice la unidad. Si la dice, manda la trama.',
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              CustomSwitchTile(
                value: _exigeEstable,
                activeColor: AppColors.blue1,
                title: 'Esperar el peso estable',
                subtitle: _exigeEstable
                    ? 'Solo deja usar el peso cuando la balanza avisa que se asentó.'
                    : 'La balanza no avisa. Se acepta cualquier lectura: el cajero decide cuándo.',
                onChanged: (v) => setState(() => _exigeEstable = v),
              ),
              if (_exigeEstable) ...[
                const SizedBox(height: 8),
                CustomText(
                  controller: _tokensEstable,
                  borderColor: AppColors.blue1,
                  label: 'Marca de peso estable',
                  hintText: 'ST',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
              ],
              const SizedBox(height: 10),
              CustomText(
                controller: _terminador,
                borderColor: AppColors.blue1,
                label: 'Fin de trama',
                hintText: r'\r\n',
                prefixIcon: const Icon(Icons.keyboard_return),
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: _comandoPeso,
                borderColor: AppColors.blue1,
                label: 'Comando para pedir el peso',
                hintText: 'Vacío si transmite sola',
                prefixIcon: const Icon(Icons.download),
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: _comandoTara,
                borderColor: AppColors.blue1,
                label: 'Comando de tara',
                hintText: 'Vacío si solo se tara con el botón del equipo',
                prefixIcon: const Icon(Icons.exposure_zero),
              ),

              const SizedBox(height: 16),
              _ProbadorTrama(
                controller: _prueba,
                perfil: () => _perfilActual,
              ),

              const SizedBox(height: 16),
              _seccion('USO'),
              CustomSwitchTile(
                value: _esPrincipal,
                activeColor: AppColors.blue1,
                title: 'Balanza principal',
                subtitle: 'Es la que se usa al pesar sin preguntar cuál.',
                onChanged: (v) => setState(() => _esPrincipal = v),
              ),

              const SizedBox(height: 12),
              // Probar el visor con ESTA balanza, sin pasar por una venta.
              // Solo tiene sentido si el transporte puede conectar; con los
              // reales todavía sin implementar, sería un botón que abre un
              // cartel de error.
              if (_transporte.puedeConectar)
                CustomButton(
                  text: 'Probar el visor',
                  backgroundColor: AppColors.white,
                  borderColor: AppColors.blue1,
                  textColor: AppColors.blue1,
                  icon: const Icon(Icons.play_arrow,
                      size: 16, color: AppColors.blue1),
                  onPressed: () => showBalanzaVisor(
                    context,
                    // El visor habla en la unidad del producto; para probar
                    // alcanza con kilos, que es el caso real de un granel.
                    pres: const UnidadPresentacion(
                        factor: 1000, simbolo: 'kg', simboloVenta: 'g'),
                    balanza: BalanzaConfig(
                      id: widget.balanza?.id ?? 'preview',
                      nombre: _nombre.text.trim().isEmpty
                          ? 'Balanza de prueba'
                          : _nombre.text.trim(),
                      transporte: _transporte,
                      direccion: _direccion.text.trim(),
                      perfil: _perfilActual,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              CustomButton(
                text: _guardando ? 'Guardando…' : 'Guardar',
                backgroundColor: AppColors.blue1,
                enabled: !_guardando,
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: AppSubtitle(titulo, fontSize: 11, fontWeight: FontWeight.w700),
      );
}

/// Pega una trama real y mostrá cómo se está interpretando.
///
/// 🔑 Es la pieza que hace configurable el módulo de verdad. Con balanzas de
/// marcas y proveedores distintos, nadie puede saber de antemano qué manda cada
/// una; acá se copia una línea del manual —o la que se vea en el diagnóstico
/// cuando haya equipo— y se ajusta el patrón hasta que el número esté bien.
class _ProbadorTrama extends StatefulWidget {
  final TextEditingController controller;

  /// Se pide por función y no por valor: el perfil cambia con cada tecla del
  /// formulario y el probador tiene que leer el ÚLTIMO, no el de cuando se
  /// construyó el widget.
  final PerfilTrama Function() perfil;

  const _ProbadorTrama({required this.controller, required this.perfil});

  @override
  State<_ProbadorTrama> createState() => _ProbadorTramaState();
}

class _ProbadorTramaState extends State<_ProbadorTrama> {
  @override
  Widget build(BuildContext context) {
    final LecturaPeso? lectura =
        parsearTrama(widget.controller.text, widget.perfil());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 15, color: AppColors.blue1),
              const SizedBox(width: 6),
              AppSubtitle('PROBAR LA TRAMA',
                  fontSize: 11, fontWeight: FontWeight.w700),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: widget.controller,
            borderColor: AppColors.blue1,
            label: 'Trama de ejemplo',
            hintText: 'ST,GS,+  1.234kg',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (lectura == null)
            _resultado(
              icono: Icons.error_outline,
              color: Colors.red.shade700,
              titulo: 'El patrón no reconoce esta trama',
              detalle:
                  'Revisá el patrón, o pegá la trama tal cual la manda el equipo.',
            )
          else
            _resultado(
              icono: lectura.esValidoParaVender
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: lectura.esValidoParaVender
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
              titulo:
                  '${lectura.kilos.toStringAsFixed(3)} kg  ·  ${lectura.gramosEnteros} g',
              detalle: lectura.estable
                  ? 'Peso estable: se puede usar en la venta.'
                  : 'Lectura INESTABLE: el botón de usar el peso queda bloqueado.',
            ),
        ],
      ),
    );
  }

  Widget _resultado({
    required IconData icono,
    required Color color,
    required String titulo,
    required String detalle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle(titulo,
                  fontSize: 13, fontWeight: FontWeight.w800, color: color),
              const SizedBox(height: 2),
              AppSubtitle(detalle, fontSize: 10, color: Colors.grey.shade700),
            ],
          ),
        ),
      ],
    );
  }
}

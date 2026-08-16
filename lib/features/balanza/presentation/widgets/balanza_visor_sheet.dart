import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../domain/entities/balanza_config.dart';
import '../../domain/entities/lectura_peso.dart';
import '../../domain/services/balanza_device.dart';
import '../../domain/services/balanzas_manager.dart';

/// Abre el visor de la balanza y devuelve la cantidad **en la unidad en la que
/// se cobra** (kg), o `null` si se salió sin tomar el peso.
///
/// Se le pasa [pres] para hablar en la misma unidad que el campo que lo abrió;
/// la conversión a unidad atómica la sigue haciendo el llamador con
/// `cantidadAUnidadDeVenta`, igual que cuando se teclea. La balanza reemplaza
/// al teclado y nada más: no toca precios, ni stock, ni el cubit.
Future<double?> showBalanzaVisor(
  BuildContext context, {
  required UnidadPresentacion pres,
  BalanzaConfig? balanza,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BalanzaVisorSheet(pres: pres, balanzaForzada: balanza),
  );
}

/// ¿Tiene sentido ofrecer la balanza para esta presentación?
///
/// Un granel puede venderse en metros (tela) o en litros, y ahí una balanza no
/// pinta. Se decide por el símbolo y no por un campo nuevo en Producto: la
/// unidad ya está cargada y agregar un `esPesable` sería pedirle al usuario que
/// declare por segunda vez algo que el sistema ya sabe.
bool presentacionEsPesable(UnidadPresentacion pres) {
  final s = (pres.simboloVisible ?? '').toLowerCase().trim();
  return const {'kg', 'g', 'gr', 'grs', 'kgs', 'lb', 'lbs', 'oz', 'ton', 't'}
      .contains(s);
}

class _BalanzaVisorSheet extends StatefulWidget {
  final UnidadPresentacion pres;

  /// Para probar el visor desde la pantalla de configuración con una balanza
  /// puntual, sin depender de cuál esté marcada como principal.
  final BalanzaConfig? balanzaForzada;

  const _BalanzaVisorSheet({required this.pres, this.balanzaForzada});

  @override
  State<_BalanzaVisorSheet> createState() => _BalanzaVisorSheetState();
}

class _BalanzaVisorSheetState extends State<_BalanzaVisorSheet> {
  BalanzaConfig? _config;
  BalanzaDevice? _device;
  StreamSubscription<LecturaPeso>? _sub;

  LecturaPeso? _ultima;
  bool _cargando = true;

  /// Por qué no se está leyendo. Null = todo bien.
  String? _motivoSinLectura;

  /// Escape a mano. 🔴 Regla del módulo: la balanza NUNCA puede trabar una
  /// venta. Si no conecta, si no existe, si el equipo se cuelga — siempre tiene
  /// que quedar el camino de escribir el peso.
  final _manual = TextEditingController();

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final config =
        widget.balanzaForzada ?? await locator<BalanzasManager>().getPrincipal();

    if (!mounted) return;
    if (config == null) {
      setState(() {
        _cargando = false;
        _motivoSinLectura =
            'No hay ninguna balanza configurada en este dispositivo.';
      });
      return;
    }

    final device = crearDevice(config);
    if (device == null) {
      setState(() {
        _config = config;
        _cargando = false;
        // Un simulador guardado en un build de producción queda INERTE. Hay
        // que decirlo con todas las letras: si dijera solo "no disponible", el
        // cajero pensaría que se rompió y llamaría a soporte.
        _motivoSinLectura = config.transporte.esSimulador
            ? 'Esta balanza es un SIMULADOR y no funciona en la app de '
                'producción. Configurá una balanza real o escribí el peso a mano.'
            : 'La conexión ${config.transporte.label} todavía no está disponible '
                'en esta versión. Escribí el peso a mano.';
      });
      return;
    }

    try {
      await device.conectar();
      if (!mounted) return;
      _sub = device.lecturas.listen((l) {
        if (mounted) setState(() => _ultima = l);
      });
      setState(() {
        _config = config;
        _device = device;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _config = config;
        _cargando = false;
        _motivoSinLectura = 'No se pudo conectar con ${config.nombre}: $e';
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _device?.desconectar();
    if (_device is BalanzaFake) (_device as BalanzaFake).dispose();
    _manual.dispose();
    super.dispose();
  }

  /// El peso listo para usarse, en la unidad en la que se cobra.
  double? get _pesoUsable {
    final l = _ultima;
    if (l == null || !l.esValidoParaVender) return null;
    // La balanza da gramos; el campo del carrito habla en kg. La división es
    // por el factor de la presentación y no por 1000 fijo: si el producto se
    // vendiera en gramos, `pres` no está activa y el peso pasa tal cual.
    return widget.pres.activa ? l.gramos / widget.pres.factor : l.gramos;
  }

  void _usar(double cantidad) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(cantidad);
  }

  @override
  Widget build(BuildContext context) {
    final simbolo = widget.pres.simboloVisible ?? '';
    final esSimulador = _config?.transporte.esSimulador ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        // 🔴 Son DOS insets distintos y hacen falta los dos: `viewInsets` es el
        // TECLADO (0 si está cerrado) y `padding` es la barra de navegación del
        // celular. Con solo el primero, "Usar peso" quedaba tapado por la barra
        // justo cuando no se estaba tecleando, que es el caso normal al pesar.
        //
        // El 36 (16 + 20) es aire pedido a mano: el sheet mide lo que mide su
        // contenido, así que este número es a la vez el alto extra del sheet y
        // la separación entre los botones y la barra de navegación. Tocando
        // este valor se mueven las dos cosas juntas.
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            56,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scale, size: 18, color: AppColors.blue1),
              const SizedBox(width: 8),
              Expanded(
                child: AppSubtitle(
                  _config?.nombre ?? 'Balanza',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // 🔴 El simulador se anuncia sin sutilezas: un peso inventado que
          // entra a una venta como real es el peor error posible de este módulo.
          if (esSimulador)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: AppSubtitle(
                'SIMULADOR — estos pesos son inventados, no vienen de una balanza.',
                fontSize: 10,
                color: Colors.orange.shade900,
              ),
            ),

          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _visor(simbolo),
            const SizedBox(height: 12),
            // 🔴 El motivo va en un bloque que se ve, no en una línea gris al
            // pie: si la balanza no está leyendo, eso es LO MÁS importante de
            // la pantalla. Como línea chica pasaba desapercibido y el cajero
            // solo notaba que "no llega el peso".
            if (_motivoSinLectura != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppSubtitle(
                        _motivoSinLectura!,
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            _entradaManual(simbolo),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_device != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Tara',
                      backgroundColor: AppColors.white,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      onPressed: () => _device!.tara(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Usar peso',
                    backgroundColor: AppColors.blue1,
                    // 🔴 Solo con lectura ESTABLE. Tomar un peso a medio
                    // asentar se ve bien en pantalla y se cobra distinto de lo
                    // que hay en el plato.
                    enabled: _pesoUsable != null,
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    onPressed: () => _usar(_pesoUsable!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _visor(String simbolo) {
    final l = _ultima;
    final hay = l != null;
    final valor = hay
        ? (widget.pres.activa ? l.gramos / widget.pres.factor : l.gramos)
        : 0.0;
    final estable = l?.estable ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hay && estable ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            hay ? valor.toStringAsFixed(3) : '—',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
              color: hay && estable ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          AppSubtitle(simbolo, fontSize: 12, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                !hay
                    ? Icons.horizontal_rule
                    : estable
                        ? Icons.check_circle
                        : Icons.more_horiz,
                size: 13,
                color: !hay
                    ? Colors.grey.shade400
                    : estable
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
              ),
              const SizedBox(width: 5),
              AppSubtitle(
                !hay
                    // Distinguir "no conecta" de "conecta pero todavía no
                    // mandó nada": son dos problemas distintos y el cajero
                    // hace cosas distintas con cada uno.
                    ? (_motivoSinLectura != null
                        ? 'Sin conexión'
                        : 'Esperando lectura…')
                    : estable
                        ? 'Peso estable'
                        : 'Asentándose…',
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Escribir el peso a mano. Siempre disponible, conecte o no: es la salida
  /// que evita que una balanza rota deje la caja parada.
  Widget _entradaManual(String simbolo) {
    return Row(
      children: [
        Expanded(
          // 🔴 `CustomText` devuelve una Column con `mainAxisSize.max`: adentro
          // de un Row se estira a todo el alto disponible y el sheet queda
          // deforme. Acotarlo con un alto fijo es el arreglo conocido, y de
          // paso lo deja alineado con el botón de al lado, que también mide 35.
          child: SizedBox(
            height: 35,
            child: CustomText(
              controller: _manual,
              hintText: 'Escribir el peso a mano',
              suffixText: simbolo,
              borderColor: AppColors.blue1,
              height: 35,
              // Con presentación se teclean kilos: `FieldType.number` se come
              // el punto (su formatter hace replaceAll de todo lo que no sea
              // dígito), así que va como texto con formatter propio.
              fieldType: FieldType.text,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,3}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 35,
          child: CustomButton(
            text: 'Usar',
            width: 78,
            backgroundColor: AppColors.white,
            borderColor: AppColors.blue1,
            textColor: AppColors.blue1,
            enabled: _manualValido != null,
            onPressed: () => _usar(_manualValido!),
          ),
        ),
      ],
    );
  }

  double? get _manualValido {
    final v = double.tryParse(_manual.text.trim().replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }
}

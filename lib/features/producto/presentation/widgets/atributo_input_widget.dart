import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncronize/core/constants/tipos_dato.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/barcode_scanner_button.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/entities/consulta_licencia.dart';
import '../../../consultas_externas/domain/entities/consulta_placa.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/repositories/consultas_repository.dart';
import '../../../servicio/presentation/widgets/celda_widgets.dart';
import '../../../servicio/presentation/widgets/firma_sheet.dart';
import '../../../servicio/presentation/widgets/inspeccion_visual_sheet.dart';
import '../../../servicio/presentation/widgets/patron_desbloqueo_sheet.dart';
import '../../domain/entities/producto_atributo.dart';

/// Captura el valor de un atributo según su tipo de dato.
///
/// Los tipos son los mismos que los de las plantillas de servicio (catálogo
/// compartido en `core/constants/tipos_dato.dart`) y acá se capturan con los
/// mismos widgets que el `DynamicFormRenderer` de servicios: el escáner, la
/// firma, el patrón y la inspección visual se reusan tal cual en vez de
/// reimplementarse.
///
/// 🔑 El valor SIEMPRE viaja como String: `ProductoAtributoValor.valor` es una
/// columna de texto con índice GIN para los filtros del marketplace. Foto,
/// firma y archivo guardan la URL del storage; la inspección visual guarda su
/// JSON serializado; el resto, el dato tal cual.
class AtributoInputWidget extends StatefulWidget {
  final ProductoAtributo atributo;
  final String? valorActual;
  final Function(String) onChanged;

  /// Necesario para subir foto y firma, y para buscar en el catálogo. Si no se
  /// pasa se usa el del propio atributo, que es el caso normal; viene aparte
  /// porque `ProductoAtributo.fromPlantillaInfo` lo deja vacío.
  final String? empresaId;

  /// Solo lo usa `PRODUCTO_CATALOGO`, para tomar el precio de la sede correcta.
  final String? sedeId;

  /// Valor elegido en el atributo PADRE, para los dependientes.
  ///
  /// Lo pasa quien tiene el mapa completo de valores del producto: este widget
  /// ve un atributo por vez y no puede saberlo solo. Sin esto, el desplegable
  /// queda bloqueado con el aviso de que falta elegir arriba.
  final String? valorDelPadre;

  const AtributoInputWidget({
    super.key,
    required this.atributo,
    this.valorActual,
    required this.onChanged,
    this.empresaId,
    this.sedeId,
    this.valorDelPadre,
  });

  @override
  State<AtributoInputWidget> createState() => _AtributoInputWidgetState();
}

class _AtributoInputWidgetState extends State<AtributoInputWidget> {
  late TextEditingController _controller;
  late TextEditingController _dateController;

  /// Nombre / marca / modelo que devolvió la consulta externa. Es ayuda visual:
  /// lo que se guarda es el número, igual que en las órdenes de servicio.
  String? _datoConsultado;
  bool _consultando = false;
  bool _subiendoFirma = false;

  String get _empresaId => widget.empresaId ?? widget.atributo.empresaId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual ?? '');
    _dateController = TextEditingController(text: _isoADdMmAaaa(widget.valorActual));
  }

  @override
  void didUpdateWidget(AtributoInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valorActual != oldWidget.valorActual) {
      _controller.text = widget.valorActual ?? '';
      _dateController.text = _isoADdMmAaaa(widget.valorActual);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: AppSubtitle(
                widget.atributo.nombre,
                fontSize: 10,
              ),
            ),
            if (widget.atributo.requerido)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Requerido',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
        if (widget.atributo.descripcion != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.atributo.descripcion!,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 2),
        _buildInputByType(),
      ],
    );
  }

  // El ícono sale del catálogo compartido: antes esta pantalla tenía su propio
  // switch y no coincidía con el de las otras.
  Widget _buildIcon() => Icon(
        tipoDatoIcono(widget.atributo.tipo.value),
        size: 16,
        color: AppColors.blue1,
      );

  Widget _buildInputByType() {
    switch (widget.atributo.tipo) {
      // Con lista de valores. Los cuatro legacy (color, talla, material,
      // capacidad) siempre se comportaron como select: no son tipos de dato
      // sino nombres de atributo, y ya no se ofrecen al crear.
      case AtributoTipo.select:
      case AtributoTipo.color:
      case AtributoTipo.talla:
      case AtributoTipo.material:
      case AtributoTipo.capacidad:
        return _buildSelectInput();

      case AtributoTipo.selectDependiente:
        return _buildSelectDependienteInput();

      case AtributoTipo.multiSelect:
        return _buildMultiSelectInput();

      case AtributoTipo.texto:
        return _buildTextInput();

      case AtributoTipo.textoArea:
        return _buildTextInput(maxLines: 4);

      case AtributoTipo.numero:
        return _buildNumberInput();

      case AtributoTipo.moneda:
        return _buildMonedaInput();

      case AtributoTipo.boolean:
        return _buildBooleanInput();

      case AtributoTipo.fecha:
        return _buildFechaInput();

      case AtributoTipo.hora:
        return _buildHoraInput();

      case AtributoTipo.email:
        return _buildTextInput(
          keyboardType: TextInputType.emailAddress,
          icono: Icons.email_outlined,
          hint: 'nombre@dominio.com',
        );

      case AtributoTipo.telefono:
        return _buildTextInput(
          keyboardType: TextInputType.phone,
          icono: Icons.phone_outlined,
          hint: '999 999 999',
        );

      case AtributoTipo.url:
        return _buildTextInput(
          keyboardType: TextInputType.url,
          icono: Icons.link,
          hint: 'https://',
        );

      case AtributoTipo.codigoBarras:
        return _buildCodigoBarrasInput();

      case AtributoTipo.pinClave:
        return _buildPinInput();

      case AtributoTipo.patronDesbloqueo:
        return _buildPatronInput();

      case AtributoTipo.documentoIdentidad:
      case AtributoTipo.placaVehiculo:
      case AtributoTipo.licenciaConducir:
        return _buildDocumentoInput();

      case AtributoTipo.foto:
        return _buildFotoInput();

      case AtributoTipo.firma:
        return _buildFirmaInput();

      case AtributoTipo.archivo:
        // Divergencia consciente con servicios, donde ARCHIVO es un switch de
        // "sí/no adjuntó" y no sube nada. Acá guarda la URL, que es lo que el
        // nombre promete y lo que sirve para una ficha técnica.
        return _buildTextInput(
          keyboardType: TextInputType.url,
          icono: Icons.attach_file,
          hint: 'Enlace al archivo',
        );

      case AtributoTipo.inspeccionVisual:
        return _buildInspeccionInput();

      case AtributoTipo.productoCatalogo:
        return _buildProductoCatalogoInput();
    }
  }

  /// Selección cuya lista sale de la rama del padre.
  ///
  /// Mientras el padre no tenga valor no se ofrece nada: la lista plana trae
  /// los procesadores de TODAS las marcas mezclados, y dejar elegir ahí es
  /// justamente lo que esta pantalla viene a evitar.
  Widget _buildSelectDependienteInput() {
    final padre = widget.valorDelPadre;
    if (padre == null || padre.isEmpty) {
      return Row(
        children: [
          Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Elegí primero el atributo del que depende',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ),
        ],
      );
    }

    final disponibles = widget.atributo.opcionesPara(padre);
    if (disponibles.isEmpty) {
      return Text(
        '"$padre" no tiene opciones cargadas en ${widget.atributo.nombre}',
        style: TextStyle(color: Colors.orange.shade800, fontSize: 10),
      );
    }

    return _buildSelectInput(disponibles);
  }

  Widget _buildSelectInput([List<String>? opciones]) {
    final valoresDisponibles = opciones ?? widget.atributo.valores;
    if (valoresDisponibles.isEmpty) {
      return Text(
        'No hay valores disponibles para este atributo',
        style: TextStyle(color: Colors.grey[600], fontSize: 10),
      );
    }

    // Solo usar value si no está vacío y existe en la lista de valores
    final currentValue = widget.valorActual;
    final validValue = (currentValue != null &&
                        currentValue.isNotEmpty &&
                        valoresDisponibles.contains(currentValue))
        ? currentValue
        : null;

    return CustomDropdown<String>(
      value: validValue,
      hintText: 'Seleccionar ${widget.atributo.nombre.toLowerCase()}',
      borderColor: AppColors.blue1,
      items: [
        // Agregar opción vacía solo si el atributo no es requerido
        if (!widget.atributo.requerido)
          const DropdownItem(
            value: '',
            label: '-- Seleccionar --',
          ),
        ...valoresDisponibles.map((valor) {
          return DropdownItem(
            value: valor,
            label: widget.atributo.unidad != null ? '$valor ${widget.atributo.unidad}' : valor,
          );
        }),
      ],
      onChanged: (value) {
        widget.onChanged(value ?? '');
      },
    );
  }

  Widget _buildMultiSelectInput() {
    // 🔴 `''.split(',')` devuelve `['']`, no una lista vacía: sin filtrar, el
    // primer valor que se elegía se guardaba como ",ROJO".
    final selectedValues = (widget.valorActual ?? '')
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.atributo.valores.map((valor) {
        final isSelected = selectedValues.contains(valor);
        // Mismo chip seleccionable que los filtros del resto del app
        // (gestión de unidades): borde fino, radio 4 y check al elegir.
        return InfoChip(
          text: widget.atributo.unidad != null
              ? '$valor ${widget.atributo.unidad}'
              : valor,
          fontSize: 10,
          borderRadius: 4,
          borderColor: AppColors.blue1,
          borderWidth: 0.6,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: AppColors.white,
          selectedBackgroundColor: AppColors.bluechip,
          selectedTextColor: AppColors.blue1,
          showCheckmark: true,
          iconSize: 12,
          selected: isSelected,
          onSelected: (selected) {
            final newValues = List<String>.from(selectedValues);
            if (selected) {
              newValues.add(valor);
            } else {
              newValues.remove(valor);
            }
            widget.onChanged(newValues.join(','));
          },
        );
      }).toList(),
    );
  }

  Widget _buildNumberInput() {
    return CustomText(
      controller: _controller,
      hintText: 'Ingrese un número',
      suffixText: widget.atributo.unidad,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: widget.onChanged,
    );
  }

  /// Guarda el NÚMERO, no el texto formateado: el backend lo valida como
  /// numérico y así se puede sumar en un reporte.
  Widget _buildMonedaInput() {
    return CurrencyTextField(
      controller: _controller,
      hintText: '0.00',
      borderColor: AppColors.blue1,
      // CurrencyTextField entrega un double ya parseado; el atributo se guarda
      // como texto, así que se serializa acá.
      onChanged: (monto) => widget.onChanged(monto.toString()),
    );
  }

  Widget _buildTextInput({
    int? maxLines,
    TextInputType? keyboardType,
    IconData? icono,
    String? hint,
  }) {
    return CustomText(
      controller: _controller,
      hintText: hint ?? 'Ingrese ${widget.atributo.nombre.toLowerCase()}',
      suffixText: widget.atributo.unidad,
      keyboardType: keyboardType ?? TextInputType.text,
      prefixIcon: icono == null ? null : Icon(icono, size: 18),
      maxLines: maxLines ?? (widget.atributo.descripcion != null ? 3 : 1),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildBooleanInput() {
    final isTrue = widget.valorActual?.toLowerCase() == 'true';

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(isTrue ? 'Sí' : 'No'),
      value: isTrue,
      onChanged: (value) {
        widget.onChanged(value.toString());
      },
    );
  }

  /// Se muestra dd/MM/yyyy y se guarda ISO (yyyy-MM-dd), igual que en las
  /// órdenes de servicio: así ordena y compara como texto.
  Widget _buildFechaInput() {
    return CustomDate(
      controller: _dateController,
      borderColor: AppColors.blue1,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      onChanged: (value) {
        if (value.isEmpty) {
          widget.onChanged('');
          return;
        }
        final partes = value.split('/');
        if (partes.length != 3) return;
        final dia = int.tryParse(partes[0]) ?? 1;
        final mes = int.tryParse(partes[1]) ?? 1;
        final anio = int.tryParse(partes[2]) ?? DateTime.now().year;
        widget.onChanged('$anio-${_dosDigitos(mes)}-${_dosDigitos(dia)}');
      },
    );
  }

  Widget _buildHoraInput() {
    return CustomText(
      controller: _controller,
      hintText: 'HH:MM',
      keyboardType: TextInputType.datetime,
      prefixIcon: const Icon(Icons.access_time, size: 18),
      suffixIcon: IconButton(
        icon: const Icon(Icons.schedule, size: 18),
        tooltip: 'Elegir hora',
        onPressed: _elegirHora,
      ),
      onChanged: widget.onChanged,
    );
  }

  Future<void> _elegirHora() async {
    final actual = _parseHora(_controller.text);
    final elegida = await showTimePicker(
      context: context,
      initialTime: actual ?? TimeOfDay.now(),
    );
    if (elegida == null || !mounted) return;
    final texto = '${_dosDigitos(elegida.hour)}:${_dosDigitos(elegida.minute)}';
    _controller.text = texto;
    widget.onChanged(texto);
  }

  /// El campo sigue siendo escribible a propósito: un lector físico teclea el
  /// código, la cámara es una vía más y no la única.
  Widget _buildCodigoBarrasInput() {
    return CustomText(
      controller: _controller,
      hintText: 'Escanea o escribe el código',
      borderColor: AppColors.blue1,
      prefixIcon: const Icon(Icons.barcode_reader, size: 18),
      suffixIcon: BarcodeScannerButton(
        onScanned: (code) {
          _controller.text = code;
          widget.onChanged(code);
        },
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildPinInput() {
    return CustomText(
      controller: _controller,
      hintText: 'PIN o clave',
      obscureText: true,
      borderColor: AppColors.blue1,
      prefixIcon: const Icon(Icons.lock_outline, size: 18),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildPatronInput() {
    final patron = widget.valorActual ?? '';
    return _TileAccion(
      icono: Icons.pattern,
      titulo: patron.isEmpty ? 'Definir patrón' : 'Patrón: $patron',
      subtitulo: patron.isEmpty ? 'Toca para dibujarlo' : 'Toca para cambiarlo',
      onTap: () async {
        final result = await PatronDesbloqueoSheet.show(
          context,
          initialValue: patron.isEmpty ? null : patron,
        );
        if (result != null) widget.onChanged(result);
      },
    );
  }

  /// DNI / RUC, placa y licencia comparten campo: cambia a quién se consulta.
  /// Se guarda SOLO el número; el nombre resuelto es ayuda visual y se descarta
  /// si el documento cambia.
  Widget _buildDocumentoInput() {
    final tipo = widget.atributo.tipo;
    final hint = switch (tipo) {
      AtributoTipo.placaVehiculo => 'ABC-123',
      AtributoTipo.licenciaConducir => 'DNI del conductor (8 dígitos)',
      _ => 'DNI (8), CE (9) o RUC (11)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          controller: _controller,
          hintText: hint,
          borderColor: AppColors.blue1,
          prefixIcon: Icon(tipoDatoIcono(tipo.value), size: 18),
          suffixIcon: _consultando
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  tooltip: 'Consultar',
                  onPressed: _consultarDocumento,
                ),
          onChanged: (v) {
            // El dato resuelto deja de valer apenas cambia el número.
            if (_datoConsultado != null) setState(() => _datoConsultado = null);
            widget.onChanged(v);
          },
        ),
        if (_datoConsultado != null && _datoConsultado!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _datoConsultado!,
            style: TextStyle(fontSize: 10, color: Colors.green.shade700),
          ),
        ],
      ],
    );
  }

  Future<void> _consultarDocumento() async {
    final valor = _controller.text.trim();
    final tipo = widget.atributo.tipo;

    if (tipo == AtributoTipo.placaVehiculo && valor.isEmpty) return;
    if (tipo == AtributoTipo.licenciaConducir && valor.length != 8) {
      _snack('La licencia se busca por el DNI del conductor (8 dígitos)');
      return;
    }
    if (tipo == AtributoTipo.documentoIdentidad &&
        ![8, 9, 11].contains(valor.length)) {
      _snack('Ingresa un DNI (8), CE (9) o RUC (11 dígitos)');
      return;
    }

    setState(() => _consultando = true);
    final repo = locator<ConsultasRepository>();
    final dynamic result = switch (tipo) {
      AtributoTipo.placaVehiculo => await repo.consultarPlaca(valor),
      AtributoTipo.licenciaConducir => await repo.consultarLicencia(valor),
      _ => valor.length == 11
          ? await repo.consultarRuc(valor)
          : valor.length == 9
              ? await repo.consultarCee(valor)
              : await repo.consultarDni(valor),
    };
    if (!mounted) return;

    setState(() {
      _consultando = false;
      if (result is Success) {
        final d = result.data;
        _datoConsultado = switch (d) {
          ConsultaPlaca p => [p.marca, p.modelo, p.color]
              .where((e) => e.trim().isNotEmpty)
              .join(' · '),
          ConsultaLicencia l =>
            '${l.nombreCompleto} · cat. ${l.licenciaCategoria}',
          ConsultaRuc r => r.razonSocial,
          ConsultaDni dni => dni.nombreCompleto,
          _ => '',
        };
      }
    });
    if (result is Error) _snack(result.message);
  }

  Widget _buildFotoInput() {
    if (_empresaId.isEmpty) {
      return _avisoSinEmpresa('la foto');
    }
    return SizedBox(
      height: 110,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: CeldaFoto(
          url: widget.valorActual,
          empresaId: _empresaId,
          onCambio: (url) => widget.onChanged(url ?? ''),
        ),
      ),
    );
  }

  /// Sube el PNG al storage y guarda SOLO la URL: el trazo inflaría cada fila.
  Widget _buildFirmaInput() {
    if (_empresaId.isEmpty) {
      return _avisoSinEmpresa('la firma');
    }
    final url = widget.valorActual ?? '';
    return _TileAccion(
      icono: Icons.draw_outlined,
      titulo: url.isEmpty ? 'Firmar' : 'Firma guardada',
      subtitulo: _subiendoFirma
          ? 'Subiendo…'
          : (url.isEmpty ? 'Toca para firmar' : 'Toca para volver a firmar'),
      onTap: _subiendoFirma ? null : _capturarFirma,
    );
  }

  Future<void> _capturarFirma() async {
    final bytes = await FirmaSheet.show(context, titulo: widget.atributo.nombre);
    if (bytes == null || !mounted) return;

    setState(() => _subiendoFirma = true);
    try {
      // Archivo temporal: uploadFile trabaja con File, no con bytes.
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/firma_${widget.atributo.clave}_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final res = await locator<StorageService>().uploadFile(
        file: file,
        empresaId: _empresaId,
        // Enum CERRADO del backend, no texto libre.
        categoria: 'FIRMA',
      );
      if (!mounted) return;
      widget.onChanged(res.url);
    } catch (e) {
      if (mounted) _snack('No se pudo guardar la firma: $e');
    } finally {
      if (mounted) setState(() => _subiendoFirma = false);
    }
  }

  Widget _buildInspeccionInput() {
    final jsonStr = widget.valorActual ?? '';
    var puntos = 0;
    if (jsonStr.isNotEmpty) {
      try {
        final data = jsonDecode(jsonStr);
        if (data is Map && data['puntos'] is List) {
          puntos = (data['puntos'] as List).length;
        }
      } catch (_) {
        // Valor viejo o escrito a mano: se muestra como vacío y al guardar se
        // reemplaza. No vale tirar una excepción por pintar un subtítulo.
      }
    }
    return _TileAccion(
      icono: Icons.car_crash_outlined,
      titulo: puntos == 0 ? 'Marcar inspección' : '$puntos ${puntos == 1 ? 'marca' : 'marcas'}',
      subtitulo: 'Toca para abrir la silueta',
      onTap: () async {
        final result = await InspeccionVisualSheet.show(
          context,
          initialValue: jsonStr.isEmpty ? null : jsonStr,
        );
        if (result != null) widget.onChanged(result);
      },
    );
  }

  /// Guarda el NOMBRE del producto elegido, congelado: el atributo documenta
  /// qué se usó aunque después el producto cambie de precio o se borre.
  Widget _buildProductoCatalogoInput() {
    if (_empresaId.isEmpty) {
      return _avisoSinEmpresa('el buscador de productos');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
      ),
      child: CeldaProducto(
        valor: widget.valorActual,
        empresaId: _empresaId,
        sedeId: widget.sedeId,
        onResuelto: (datos) => widget.onChanged(datos['nombre'] ?? ''),
      ),
    );
  }

  Widget _avisoSinEmpresa(String que) => Text(
        'No se puede usar $que desde esta pantalla: falta la empresa.',
        style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  /// El valor se guarda ISO pero `CustomDate` muestra dd/MM/yyyy.
  static String _isoADdMmAaaa(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final partes = iso.split('-');
    if (partes.length != 3) return '';
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  static TimeOfDay? _parseHora(String texto) {
    final partes = texto.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

/// Fila tocable para los tipos que se capturan en un sheet aparte (patrón,
/// firma, inspección). Mismo alto y mismo borde que un campo de texto, para
/// que la columna no se vea despareja.
class _TileAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  const _TileAccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icono, size: 18, color: AppColors.blue1),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

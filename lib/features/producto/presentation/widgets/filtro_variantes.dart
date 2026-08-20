/// Buscador + filtro numérico de variantes, compartido por la edición masiva
/// y el análisis de variantes.
///
/// Vive acá y no copiado en cada página porque la lógica tiene tres trampas
/// que ya costaron encontrar una vez: el SKU no puede entrar al match por
/// fragmentos, el resaltado necesita índices que mapeen al texto original, y
/// el stock solo se puede sumar entre variantes de la misma presentación.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/busqueda_texto.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/producto_variante.dart';

/// Contra qué precio filtra la barra numérica.
enum CampoPrecio {
  venta('P. Venta'),
  costo('Costo'),
  mayor('Por mayor');

  const CampoPrecio(this.etiqueta);
  final String etiqueta;
}

/// Cómo se compara. `sin` no lleva valor: sirve para el caso más útil de
/// todos —"mostrame las que TODAVÍA no tienen precio por mayor"— que es lo
/// que se revisa al terminar de cargar una lista.
enum OpPrecio {
  igual('='),
  menor('<'),
  mayorQue('>'),
  entre('entre'),
  sin('vacío');

  const OpPrecio(this.etiqueta);
  final String etiqueta;

  bool get pideValor => this != OpPrecio.sin;
  bool get pideDos => this == OpPrecio.entre;
}

/// Estado del buscador y del filtro numérico.
///
/// La página es dueña de los controllers (los crea y los libera) y decide
/// dónde va cada pedazo de UI; acá vive solo el estado y las reglas.
class FiltroVariantes {
  final busqueda = TextEditingController();
  final desde = TextEditingController();
  final hasta = TextEditingController();

  bool abierto = false;
  CampoPrecio campo = CampoPrecio.venta;
  OpPrecio op = OpPrecio.igual;

  void dispose() {
    busqueda.dispose();
    desde.dispose();
    hasta.dispose();
  }

  /// Al cerrar el panel se limpian los valores: un filtro activo pero
  /// invisible haría creer que faltan variantes.
  void alternarPanel() {
    abierto = !abierto;
    if (!abierto) {
      desde.clear();
      hasta.clear();
    }
  }

  bool get filtraPrecio {
    if (!abierto) return false;
    if (!op.pideValor) return true;
    return parseNumero(desde.text) != null;
  }

  bool get filtraTexto => busqueda.text.trim().isNotEmpty;

  bool get activo => filtraTexto || filtraPrecio;

  /// La consulta lista para buscar en el SKU, o null si no corresponde.
  ///
  /// 🔴 El SKU va SEPARADO y sin partir en palabras. Es un código con números
  /// (`VAR-000230`) y con el match por fragmentos del nombre pasaba esto:
  /// buscando "3 pzs", el término "3" caía dentro de `VAR-000230` y una
  /// variante de **5 PZS** entraba en los resultados. Un código solo tiene
  /// sentido buscado entero, y con menos de 3 caracteres vuelve a enganchar
  /// medio catálogo por el número.
  String? get consultaSku {
    final consulta = normalizarTexto(busqueda.text);
    return consulta.length >= 3 ? consulta : null;
  }

  /// Clave para memoizar el resultado en la página. Se le suma afuera lo que
  /// dependa del contexto (identidad de la lista, sede).
  String get clave =>
      '${busqueda.text}|$abierto|${campo.name}|${op.name}|${desde.text}|${hasta.text}';

  /// Filtra por texto Y por precio.
  ///
  /// [valorDe] devuelve el valor del campo pedido **en unidad de
  /// PRESENTACIÓN** — la misma en la que se ve en pantalla y en la que se
  /// teclea el filtro. Lo resuelve la página porque solo ella sabe de qué
  /// sede está hablando.
  List<ProductoVariante> filtrar(
    List<ProductoVariante> variantes,
    double? Function(ProductoVariante v, CampoPrecio campo) valorDe,
  ) {
    final terminos = terminosBusqueda(busqueda.text);
    final porSku = consultaSku;

    return variantes.where((v) {
      if (terminos.isNotEmpty) {
        // Nombre + valores de atributo: acá sí conviene el match por
        // fragmentos y en cualquier orden, así "frozen 3 pzs" filtra de una.
        final texto =
            '${v.nombre} ${v.atributosValores.map((a) => a.valor).join(' ')}';
        final porNombre = coincideTodosLosTerminos(texto, terminos);
        final porCodigo = porSku != null && _coincideCodigo(v, porSku);
        if (!porNombre && !porCodigo) return false;
      }
      return _pasaPrecio(v, valorDe);
    }).toList();
  }

  /// ¿Alguno de los CÓDIGOS de la variante contiene la consulta entera?
  ///
  /// Los tres van juntos y sin partir en palabras, por la misma razón que el
  /// SKU: son cadenas con números y, partidos, el "3" de "3 pzs" cae dentro de
  /// `VAR-000230` o de un EAN y arrastra media lista.
  bool _coincideCodigo(ProductoVariante v, String consulta) {
    if (normalizarTexto(v.sku).contains(consulta)) return true;
    if (normalizarTexto(v.codigoEmpresa).contains(consulta)) return true;
    final barras = v.codigoBarras;
    return barras != null && normalizarTexto(barras).contains(consulta);
  }

  bool _pasaPrecio(
    ProductoVariante v,
    double? Function(ProductoVariante, CampoPrecio) valorDe,
  ) {
    if (!filtraPrecio) return true;
    final valor = valorDe(v, campo);
    if (op == OpPrecio.sin) return valor == null;
    if (valor == null) return false;

    final a = parseNumero(desde.text);
    if (a == null) return true;

    switch (op) {
      // Tolerancia de medio centavo: los precios se muestran con 2 decimales
      // y un == sobre doubles no engancharía nunca.
      case OpPrecio.igual:
        return (valor - a).abs() < 0.005;
      case OpPrecio.menor:
        return valor < a;
      case OpPrecio.mayorQue:
        return valor > a;
      case OpPrecio.entre:
        final b = parseNumero(hasta.text);
        return b == null ? valor >= a : valor >= a && valor <= b;
      case OpPrecio.sin:
        return false; // ya resuelto arriba
    }
  }

  /// Parte [texto] en tramos, marcando los que coinciden con la búsqueda.
  ///
  /// Con [esSku] se resalta usando la consulta ENTERA en vez de las palabras
  /// sueltas, igual que como se filtra: si no, el "3" de "3 pzs" se pintaba
  /// dentro de `VAR-000230` aunque la fila hubiera entrado por el nombre.
  List<TextSpan> resaltar(
    String texto,
    TextStyle base, {
    bool esSku = false,
  }) {
    final terminos = esSku
        ? [if (consultaSku != null) consultaSku!]
        : terminosBusqueda(busqueda.text);
    if (terminos.isEmpty) return [TextSpan(text: texto, style: base)];

    final heno = normalizarConservandoPosiciones(texto);
    // Si las longitudes no coinciden los índices no mapean y pintaría
    // corrido: mejor sin resaltar que mal resaltado.
    if (heno.length != texto.length) {
      return [TextSpan(text: texto, style: base)];
    }

    final marcado = List<bool>.filled(texto.length, false);
    for (final termino in terminos) {
      var desdeIdx = 0;
      while (desdeIdx <= heno.length - termino.length) {
        final i = heno.indexOf(termino, desdeIdx);
        if (i < 0) break;
        for (var k = i; k < i + termino.length; k++) {
          marcado[k] = true;
        }
        desdeIdx = i + termino.length;
      }
    }

    // Tramos contiguos con el mismo estado, para no emitir un span por letra.
    final destacado = base.copyWith(
      fontWeight: FontWeight.w900,
      color: Colors.black,
      backgroundColor: colorResaltado,
    );
    final spans = <TextSpan>[];
    var i = 0;
    while (i < texto.length) {
      final estado = marcado[i];
      var j = i;
      while (j < texto.length && marcado[j] == estado) {
        j++;
      }
      spans.add(TextSpan(
        text: texto.substring(i, j),
        style: estado ? destacado : base,
      ));
      i = j;
    }
    return spans;
  }

  /// Cian marcador. Saturado y opaco para separarse de los tintes de fondo
  /// (fila editada, fila enfocada), que son muy tenues.
  static const colorResaltado = Color(0xFF82F0FF);
}

/// El teclado numérico deja escribir coma: "0,5" tiene que valer lo mismo que
/// "0.5" y no caerse a null.
double? parseNumero(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t.replaceAll(',', '.'));
}

final _soloDecimal = FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'));

/// Caja chica con cuántas variantes se están viendo y cuánto stock suman.
///
/// [stock] en null se muestra como "mixto": sumar 5000 g de un granel con 2
/// sacos da un número que no significa nada, así que la página manda null
/// cuando lo visible no comparte presentación.
class ResumenVariantes extends StatelessWidget {
  final int cantidad;
  final int total;
  final String? stock;
  final bool filtrando;

  const ResumenVariantes({
    super.key,
    required this.cantidad,
    required this.total,
    required this.stock,
    required this.filtrando,
  });

  @override
  Widget build(BuildContext context) {
    final vacio = cantidad == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minWidth: 54),
      decoration: BoxDecoration(
        color: vacio
            ? Colors.red.withValues(alpha: 0.08)
            : AppColors.blue1.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filtrando && !vacio
              ? AppColors.blue1.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // Con filtro se ve "23/91": el denominador es lo que evita creer
            // que se perdieron variantes.
            filtrando ? '$cantidad/$total' : '$cantidad',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: vacio ? Colors.red.shade700 : AppColors.blue1,
            ),
          ),
          Text(
            stock ?? 'mixto',
            style: TextStyle(fontSize: 9, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

/// UNA sola fila: campo, comparador y valor(es).
///
/// Con chips ocupaba nueve renglones —ocho opciones no entran a lo ancho de
/// un teléfono— y se comía la mitad de la pantalla, que es justo lo que hace
/// falta para ver la tabla.
class FilaFiltroPrecio extends StatelessWidget {
  final FiltroVariantes filtro;
  final VoidCallback onCambio;

  /// Alto de los controles, para que emparejen con la fila de la página.
  final double alto;

  const FilaFiltroPrecio({
    super.key,
    required this.filtro,
    required this.onCambio,
    this.alto = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _selector<CampoPrecio>(
            valor: filtro.campo,
            opciones: CampoPrecio.values,
            etiqueta: (c) => c.etiqueta,
            // 100 y no menos: "Por mayor" con la flecha y el padding no entra
            // en 92 y saldría con ellipsis.
            ancho: 100,
            onChanged: (c) {
              filtro.campo = c;
              onCambio();
            },
          ),
          const SizedBox(width: 6),
          _selector<OpPrecio>(
            valor: filtro.op,
            opciones: OpPrecio.values,
            etiqueta: (o) => o.etiqueta,
            ancho: 80,
            onChanged: (o) {
              filtro.op = o;
              if (!o.pideDos) filtro.hasta.clear();
              if (!o.pideValor) filtro.desde.clear();
              onCambio();
            },
          ),
          if (filtro.op.pideValor) ...[
            const SizedBox(width: 6),
            Expanded(
              child: _campo(
                filtro.desde,
                filtro.op.pideDos ? 'Desde' : 'Valor S/',
              ),
            ),
            if (filtro.op.pideDos) ...[
              const SizedBox(width: 6),
              Expanded(child: _campo(filtro.hasta, 'Hasta')),
            ],
          ] else
            // Sin campo de valor la fila quedaría con dos selectores sueltos
            // a la izquierda; el resumen ocupa el hueco y explica qué filtra.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Sin ${filtro.campo.etiqueta.toLowerCase()} cargado',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String hint) {
    return SizedBox(
      height: alto,
      child: CustomText(
        controller: controller,
        hintText: hint,
        onChanged: (_) => onCambio(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_soloDecimal],
        height: alto,
        borderColor: AppColors.blue1Alpha40,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
        showValidationIndicator: false,
      ),
    );
  }

  Widget _selector<T>({
    required T valor,
    required List<T> opciones,
    required String Function(T) etiqueta,
    required ValueChanged<T> onChanged,
    required double ancho,
  }) {
    return SizedBox(
      width: ancho,
      child: CustomDropdown<T>(
        value: valor,
        height: alto,
        itemExtent: 32,
        borderColor: AppColors.blue1Alpha40,
        borderWidth: 0.6,
        textStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        items: [
          for (final o in opciones) DropdownItem<T>(value: o, label: etiqueta(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

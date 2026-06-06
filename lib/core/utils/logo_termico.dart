import 'package:image/image.dart' as img;

/// Prepara un logo para impresión térmica ESC-POS:
///
///  1. Aplana la transparencia sobre BLANCO (las térmicas rasterizan el
///     alpha como negro o basura).
///  2. Recorta los márgenes blancos del canvas CON TOLERANCIA: los logos
///     suelen venir con "aire" alrededor del arte que en el papel se
///     convierte en centímetros en blanco. `img.trim` con TrimMode
///     compara el color EXACTO de la esquina — el ruido de compresión
///     JPEG (blancos 250-254) lo derrota; por eso se escanea fila/columna
///     considerando blanca toda la que tenga solo píxeles con
///     luminancia >= [umbral].
img.Image prepararLogoTermico(img.Image decoded, {int umbral = 235}) {
  var logo = decoded;
  try {
    // 1. Alpha → blanco
    if (logo.hasAlpha) {
      final canvas = img.Image(width: logo.width, height: logo.height);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(canvas, logo);
      logo = canvas;
    }

    // 2. Trim con tolerancia
    bool esBlanco(img.Pixel p) =>
        p.r >= umbral && p.g >= umbral && p.b >= umbral;

    bool filaBlanca(int y) {
      for (var x = 0; x < logo.width; x++) {
        if (!esBlanco(logo.getPixel(x, y))) return false;
      }
      return true;
    }

    bool columnaBlanca(int x, int top, int bottom) {
      for (var y = top; y <= bottom; y++) {
        if (!esBlanco(logo.getPixel(x, y))) return false;
      }
      return true;
    }

    var top = 0;
    while (top < logo.height - 1 && filaBlanca(top)) {
      top++;
    }
    var bottom = logo.height - 1;
    while (bottom > top && filaBlanca(bottom)) {
      bottom--;
    }
    var left = 0;
    while (left < logo.width - 1 && columnaBlanca(left, top, bottom)) {
      left++;
    }
    var right = logo.width - 1;
    while (right > left && columnaBlanca(right, top, bottom)) {
      right--;
    }

    final hayRecorte =
        top > 0 || left > 0 || bottom < logo.height - 1 || right < logo.width - 1;
    final esValido = right > left && bottom > top;
    if (hayRecorte && esValido) {
      logo = img.copyCrop(
        logo,
        x: left,
        y: top,
        width: right - left + 1,
        height: bottom - top + 1,
      );
    }
  } catch (_) {
    // Formato raro → se imprime tal cual.
  }
  return logo;
}

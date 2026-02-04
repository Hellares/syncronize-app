import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Servicio global para manejar el reconocimiento de voz (Speech-to-Text)
/// Singleton para ser usado en toda la aplicación
class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Indica si el servicio está escuchando actualmente
  bool get isListening => _isListening;

  /// Indica si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de reconocimiento de voz
  /// Retorna true si se inicializó correctamente
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Solicitar permiso de micrófono
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('❌ Permiso de micrófono denegado');
        return false;
      }

      // Inicializar el servicio de speech-to-text
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Error en speech-to-text: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('📢 Estado speech-to-text: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        debugPrint('✅ Speech-to-Text inicializado correctamente');
      } else {
        debugPrint('❌ No se pudo inicializar Speech-to-Text');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error al inicializar speech-to-text: $e');
      return false;
    }
  }

  /// Comienza a escuchar y transcribir voz
  /// [onResult] callback que se ejecuta cuando hay texto reconocido (se llama con cada actualización parcial)
  /// [localeId] idioma para el reconocimiento (por defecto español)
  Future<bool> startListening({
    required Function(String text) onResult,
    String localeId = 'es_ES',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      debugPrint('⚠️ Ya está escuchando');
      return false;
    }

    try {
      // Verificar locales disponibles
      final locales = await _speech.locales();
      final hasSpanish = locales.any((l) =>
        l.localeId.startsWith('es') || l.localeId == localeId
      );

      final selectedLocale = hasSpanish ? localeId : 'es_ES';

      debugPrint('🎤 Iniciando escucha en locale: $selectedLocale');

      await _speech.listen(
        onResult: (result) {
          // result.recognizedWords contiene TODO el texto reconocido hasta ahora,
          // no solo las palabras nuevas
          if (result.recognizedWords.isNotEmpty) {
            debugPrint('📝 Texto reconocido: "${result.recognizedWords}" (final: ${result.finalResult})');
            onResult(result.recognizedWords);
          }
        },
        localeId: selectedLocale,
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
          partialResults: true, // Actualizaciones en tiempo real
          listenMode: stt.ListenMode.dictation,
        ),
      );

      _isListening = true;
      return true;
    } catch (e) {
      debugPrint('❌ Error al iniciar escucha: $e');
      _isListening = false;
      return false;
    }
  }

  /// Detiene la escucha activa
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Escucha detenida');
    } catch (e) {
      debugPrint('❌ Error al detener escucha: $e');
    }
  }

  /// Cancela la escucha sin procesar el resultado
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      debugPrint('❌ Escucha cancelada');
    } catch (e) {
      debugPrint('❌ Error al cancelar escucha: $e');
    }
  }

  /// Verifica si el dispositivo soporta reconocimiento de voz
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los idiomas disponibles para reconocimiento
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  /// Libera los recursos del servicio
  void dispose() {
    _speech.stop();
    _isListening = false;
  }
}

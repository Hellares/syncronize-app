package com.syncronize.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Recibe ubicaciones compartidas desde otras apps (WhatsApp → Compartir, o un
 * enlace `geo:`) y se las pasa a Flutter por [CHANNEL].
 *
 * Dos caminos según el estado de la app:
 *  - **App cerrada**: el texto se guarda en [pendingSharedText] y Dart lo pide
 *    con `getInitialSharedText` cuando termina de arrancar.
 *  - **App abierta**: llega por `onNewIntent` y se empuja a Dart con
 *    `onSharedText`. Requiere `launchMode="singleTask"` en el manifest — sin eso
 *    Android crea una Activity nueva y este método nunca se ejecuta. `singleTop`
 *    NO alcanza: solo reutiliza la Activity si está encima de la MISMA tarea, y
 *    el intent de WhatsApp sale desde la tarea de WhatsApp.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedText" -> {
                        result.success(pendingSharedText)
                        pendingSharedText = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        pendingSharedText = extractSharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Sin esto getIntent() sigue devolviendo el intent con el que arrancó la app.
        setIntent(intent)

        val text = extractSharedText(intent) ?: return
        val channel = this.channel
        if (channel != null) {
            channel.invokeMethod("onSharedText", text)
        } else {
            pendingSharedText = text
        }
    }

    /**
     * Saca el texto de un Compartir (`ACTION_SEND` + `text/plain`) o la URI de
     * un `geo:` (`ACTION_VIEW`).
     *
     * Consume el dato del intent al leerlo: Android reentrega el mismo intent
     * cada vez que la app vuelve a foreground, y sin esto la ubicación se
     * reprocesaría una y otra vez.
     */
    private fun extractSharedText(intent: Intent?): String? {
        if (intent == null) return null

        val text = when (intent.action) {
            Intent.ACTION_SEND ->
                if (intent.type == "text/plain") intent.getStringExtra(Intent.EXTRA_TEXT) else null
            Intent.ACTION_VIEW -> intent.data?.toString()
            else -> null
        }
        if (text == null) return null

        intent.removeExtra(Intent.EXTRA_TEXT)
        intent.data = null
        intent.action = null

        return text.takeIf { it.isNotBlank() }
    }

    companion object {
        private const val CHANNEL = "com.syncronize.app/shared_location"
    }
}

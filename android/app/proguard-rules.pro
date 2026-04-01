# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# OkHttp (usado internamente por Dio en Android)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Gson / JSON serialization
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Evitar problemas con reflexión en plugins Flutter
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Mantener clases de certificados SSL/TLS
-keep class javax.net.ssl.** { *; }
-keep class java.security.** { *; }
-keep class sun.security.ssl.** { *; }

# Bluetooth Thermal Printer
-keep class com.example.bluetooth_thermal_printer.** { *; }

# Image picker / file picker
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.app.** { *; }

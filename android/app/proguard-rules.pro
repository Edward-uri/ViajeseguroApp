# =============================================================================
# ProGuard / R8 rules — Jala Pasajero
# =============================================================================

# --- Flutter ------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Flutter's generated plugin registrant
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }

# --- Mapbox -------------------------------------------------------------------
-keep class com.mapbox.** { *; }
-keep class com.mapbox.geojson.** { *; }
-keep class com.mapbox.mapboxsdk.** { *; }
-dontwarn com.mapbox.**

# Mapbox annotation / stylegen
-keep class com.mapbox.bindgen.** { *; }
-keep class com.mapbox.common.** { *; }
-keep class com.mapbox.turf.** { *; }

# --- Firebase Messaging -------------------------------------------------------
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-dontwarn com.google.firebase.messaging.**

# Firebase JSON / annotations
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations

# --- Socket.IO ----------------------------------------------------------------
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# --- URL Launcher -------------------------------------------------------------
-keep class io.flutter.plugins.urllauncher.** { *; }

# --- Image Picker -------------------------------------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }

# --- Secure Storage -----------------------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.it_nomads.fluttersecurestorage.ciphers.** { *; }

# --- JSON / Serialization -----------------------------------------------------
-keep class com.jala.pasajero.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep R8 from stripping sealed / data classes used by reflection
-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- General Android ----------------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,EnclosingMethod

# --- Play Core (Flutter dynamic delivery — not used but referenced) -----------
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# --- Dart/Flutter model classes that use fromJson/toJson ----------------------
# Evitar que R8 elimine constructores o campos accedidos por nombre
-keep class **.domain.entities.** { *; }
-keep class **.data.remote.** { *; }
-keepclassmembers class ** {
    *** fromJson(...);
    *** toJson(...);
}

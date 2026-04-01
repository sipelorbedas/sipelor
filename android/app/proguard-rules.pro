# ============================================================
# ProGuard Rules for SIPELOR BEDAS — Production
# ============================================================

# ── General Flutter ──────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# ── App model classes ────────────────────────────────────────
-keep class com.bedas.sipelor.** { *; }

# ── Attributes ───────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception
-keepattributes InnerClasses
-keepattributes SourceFile
-keepattributes LineNumberTable
-keepattributes EnclosingMethod

# ── Native methods ───────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── Serializable ─────────────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ── Enums ────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Remove debug logging ──────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# ── Supabase / Postgrest ─────────────────────────────────────
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# ── OkHttp / Ktor (used by Supabase & Dio) ───────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# ── Ktor (Supabase realtime & auth) ──────────────────────────
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# ── Sentry ───────────────────────────────────────────────────
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**
-keepnames class io.sentry.** { *; }

# ── Kotlin coroutines / Serialization ────────────────────────
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-keep class kotlinx.serialization.** { *; }
-dontwarn kotlinx.serialization.**
-keepclassmembers class **$serializer {
    static **$serializer INSTANCE;
}

# ── Gson / JSON ──────────────────────────────────────────────
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Google Maps ───────────────────────────────────────────────
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.common.**
-keep class com.google.maps.flutter.** { *; }

# ── Google Fonts ─────────────────────────────────────────────
-keep class com.google.fonts.** { *; }

# ── flutter_secure_storage ───────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── local_auth (biometric) ───────────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn io.flutter.plugins.localauth.**

# ── flutter_local_notifications ──────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ── speech_to_text ───────────────────────────────────────────
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# ── file_picker ──────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# ── gal (save to gallery) ────────────────────────────────────
-keep class com.nomeqc.gal.** { *; }
-dontwarn com.nomeqc.gal.**

# ── url_launcher ─────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ── app_links (deep links) ───────────────────────────────────
-keep class com.llfbandit.app_links.** { *; }
-dontwarn com.llfbandit.app_links.**

# ── connectivity_plus ────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ── device_info_plus ─────────────────────────────────────────
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# ── package_info_plus ────────────────────────────────────────
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-dontwarn dev.fluttercommunity.plus.packageinfo.**

# ── permission_handler ───────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── shared_preferences ───────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ── path_provider ────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ── vibration ────────────────────────────────────────────────
-keep class com.benjaminabel.vibration.** { *; }
-dontwarn com.benjaminabel.vibration.**

# ── fl_chart ─────────────────────────────────────────────────
-keep class com.pauldemarco.flutter_blue.** { *; }

# ── crypto / encrypt (AES-256) ───────────────────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ── Multidex ─────────────────────────────────────────────────
-keep class androidx.multidex.** { *; }

# ── AndroidX / Lifecycle ─────────────────────────────────────
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

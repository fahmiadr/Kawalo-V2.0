# Flutter Wrapper & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve native JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve reflection and type annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# Isar Database native bindings
-keep class dev.isar.** { *; }
-dontwarn dev.isar.**

# Keep standard security and crypto classes
-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# RootBeer & Frida native detection (jailbreak_root_detection)
-keep class com.scottyab.rootbeer.** { *; }
-dontwarn com.scottyab.rootbeer.**
-keep class com.w3connext.jailbreak_root_detection.** { *; }
-dontwarn com.w3connext.jailbreak_root_detection.**

# AndroidX Security Crypto (flutter_secure_storage)
-keep class androidx.security.crypto.** { *; }

# Package Info Plus (installerStore & signingInfo)
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Flutter engine references Play Core deferred-component classes that this app does not bundle
-dontwarn com.google.android.play.core.**

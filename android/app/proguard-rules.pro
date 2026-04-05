# Flutter wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase & HTTP
-keepattributes Signature, *Annotation*, EnclosingMethod
-keep class com.google.gson.** { *; }
-dontwarn com.google.errorprone.annotations.**

# LiveKit Rules
-keep class io.livekit.android.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn io.livekit.android.**

# Mobile Scanner
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# Sentry
-keepattributes LineNumberTable, SourceFile
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Hive (if using generic types or reflection)
-keep class io.hivedb.** { *; }
-keepnames class * extends io.hivedb.hive.HiveObject
-dontwarn io.hivedb.hive.internal.**

# Desugaring
-dontwarn java.lang.invoke.**
-dontwarn j$.**

# Ignore Play Core missing classes (Flutter engine references these for deferred components)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# Supabase, Postgrest, GoTrue
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }
-keep interface io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Keep all models to prevent JSON serialization errors
-keep class com.twinclassroom.app.features.**.domain.models.** { *; }
-keepclassmembers class com.twinclassroom.app.features.**.domain.models.** { *; }

# General Networking
-keepattributes Signature, *Annotation*, EnclosingMethod
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animalsniffer.**

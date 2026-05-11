# Flutter ProGuard Rules for Supabase & Networking

# Keep Supabase classes
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Keep Networking/JSON classes
-keep class com.google.gson.** { *; }
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keepattributes Signature
-keepattributes *Annotation*

# Keep models to prevent obfuscation of JSON mapping fields
-keep class com.fleetpay.fleetpay.models.** { *; }

# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ignore missing Play Core classes (referenced by Flutter engine but not always present)
-dontwarn com.google.android.play.core.**

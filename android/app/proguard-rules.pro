# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Supabase
-keep class io.github.jan-tennert.supabase.** { *; }

# Keep annotation
-keepattributes *Annotation*

# R8 missing classes - suppress warnings
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn org.jetbrains.kotlin.**
-dontwarn javax.annotation.**

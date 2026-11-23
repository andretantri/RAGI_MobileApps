# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# flutter_jailbreak_detection / RootBeer
-keep class com.scottyab.rootbeer.** { *; }
-keep class com.muntanto.flutterjailbreakdetection.** { *; }

# Dio
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep model classes (adjust package as needed)
-keep class com.minu.staff.myinu_staff.** { *; }

# Play Core deferred components
-dontwarn com.google.android.play.core.**

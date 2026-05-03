# Flutter + Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Drift (SQLite)
-keep class com.example.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth
-keep class androidx.biometric.** { *; }

# Keep all models (Drift generated row classes)
-keep class ** extends androidx.sqlite.** { *; }

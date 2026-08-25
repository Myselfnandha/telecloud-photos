# Flutter & Engine
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Play Core & Deferred Components warnings suppression
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# TDLib & SQLite Native Libraries
-keep class org.drinkless.tdlib.** { *; }
-keep class org.sqlite.** { *; }

# DisplayMode
-keep class com.github.sbugert.flutter_displaymode.** { *; }

# Google Sign-In & Auth
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.android.gms.**

# Drift & Workmanager
-keep class androidx.work.** { *; }

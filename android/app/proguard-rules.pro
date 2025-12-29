# Proguard rules for Shareo app
# Preserve Dio HTTP client
-keep class io.flutter.embedding.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Dio classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }

# Keep all model classes
-keep class * {
    public protected *;
}

# Don't warn about some unused classes
-dontwarn android.content.res.**
-dontwarn android.util.**
-dontwarn android.graphics.**

# Preserve line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

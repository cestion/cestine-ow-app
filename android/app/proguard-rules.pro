# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Play Core deferred components — 本项目未使用 Play Store split APK，
# 但 Flutter embedding 仍引用这些类。让 R8 忽略缺失引用而非报错。
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Privy
-keep class io.privy.** { *; }
-keep class io.privy.privyflutter.** { *; }
-keepattributes Signature, RuntimeVisibleAnnotations, RuntimeInvisibleAnnotations

# Solana SDK
-keep class com.solana.** { *; }
-keepclassmembers class com.solana.** { *; }
-keep class com.github.komputing.** { *; }
-keep class org.bitcoinj.** { *; }

# Gson / json_serializable 反射
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}
-keep class **JsonAdapter { *; }
-keep class * implements com.google.gson.TypeAdapter { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }

# Hive 生成型适配器
-keep class * extends com.google.gson.TypeAdapter { *; }
-keepattributes *Annotation*

# ExoPlayer / better_native_video_player
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# 保留 *Model* 类（json_serializable 反射用到）
-keep class **.model.** { *; }
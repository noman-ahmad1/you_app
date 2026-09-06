# ---------------------------------------------------------------------------
# R8 / ProGuard keep rules for the You app.
#
# Most dependencies (Firebase, RevenueCat, Play Services) ship consumer rules
# inside their AARs, so this file only covers what those don't.
# ---------------------------------------------------------------------------

# --- Flutter engine ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Hive / reflection-free but keep adapters if any are added later ---
-keep class * extends hive.TypeAdapter { *; }

# --- Models deserialised from Firestore are plain Dart, not Java, so no keeps
#     are needed for them. Kotlin metadata, however, is used by Play Billing. ---
-keep class kotlin.Metadata { *; }

# --- Keep annotations R8 would otherwise strip and Play Billing relies on ---
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# --- Silence warnings from optional transitive deps that are never loaded ---
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

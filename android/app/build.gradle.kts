import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("com.google.firebase.crashlytics") // ADDED FOR CRASHLYTICS
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.youstartup.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.youstartup.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // RevenueCat / purchases_flutter 8.x requires Android API 24+.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val keystorePath = keystoreProperties.getProperty("storeFile")
            if (keystorePath != null) {
                storeFile = file(keystorePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // R8: shrink, optimise and obfuscate. Off by default in AGP, which
            // shipped this app unobfuscated and unshrunk. Keep rules live in
            // proguard-rules.pro; Firebase, RevenueCat and Hive ship their own
            // consumer rules in their AARs.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
dependencies {
    // 1. BOM dependency must be declared using the 'platform()' function call.
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // 2. Regular dependencies are passed as a string argument to the 'implementation()' function.
    implementation("com.google.firebase:firebase-auth")
    
    // 3. Dependency for Google Sign-In is also passed as a string argument.
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    // 4. Dependency for Crashlytics is also passed as a string argument.
    implementation("com.google.firebase:firebase-crashlytics")
}

flutter {
    source = "../.."
}

import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (local, git-ignored) or OPENMOSH_* environment
// variables (CI). Without either, release builds fall back to the debug key so local
// `flutter run --release` keeps working; the release workflow refuses to build without it.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    keystoreProperties.getProperty(property) ?: System.getenv(env)

val releaseStoreFile = signingValue("storeFile", "OPENMOSH_KEYSTORE_PATH")

android {
    namespace = "dev.openmosh.openmosh"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "dev.openmosh.openmosh"
        // Android 9+: SSH keys are stored under an auth-bound Keystore key
        // (flutter_secure_storage AndroidOptions.biometric requires API 28).
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "OPENMOSH_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "OPENMOSH_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "OPENMOSH_KEY_PASSWORD")
            }
        }
    }

    // Compressed native libraries: the APK download is about half the size.
    // They are extracted once at install instead of mapped from the APK.
    packaging {
        jniLibs {
            useLegacyPackaging = true
            // sherpa-onnx: Dart loads only the C API; the C++ API library is unused.
            excludes += "**/libsherpa-onnx-cxx-api.so"
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// UnifiedPush's connector pulls the JVM `tink` artifact while
// flutter_secure_storage uses `tink-android` (same classes). Keep the
// Android flavour only.
configurations.all {
    exclude(group = "com.google.crypto.tink", module = "tink")
}

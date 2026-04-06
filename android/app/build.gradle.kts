plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// FIX 1: Use Kotlin syntax (val) instead of Groovy (def)
// Use standard imports for FileInputStream and Properties
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.devcms.UMTcharms"
    compileSdk = flutter.compileSdkVersion.toInt()

    // Explicitly set the NDK version
    ndkVersion = "27.0.12077973"

    compileOptions {
        // FIX 1: Use '=' and 'is' prefix for Kotlin DSL
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.devcms.UMTcharms"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        // FIX 2: Use create("name") and correct assignment syntax
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            // FIX 3: Use '=' for assignment and 'is' prefix for booleans
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FIX 2: Use double quotes and parentheses
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
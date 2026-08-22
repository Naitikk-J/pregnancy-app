pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    // START: FlutterFire Configuration
    // google-services bumped from the FlutterFire default (4.3.15) for
    // Gradle 9 / Groovy 4 compatibility.
    // The Crashlytics gradle plugin was removed 2026-08-09 along with the
    // firebase_crashlytics package (release R8 stripped its ComponentRegistrar,
    // crashing Firebase init on real devices).
    id("com.google.gms.google-services") version("4.4.2") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

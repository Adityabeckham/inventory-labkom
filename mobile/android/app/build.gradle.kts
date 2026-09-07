import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kunci penandatanganan rilis dibaca dari android/key.properties — berkas yang
// TIDAK ikut masuk repo (lihat .gitignore). Kalau berkasnya tidak ada, build
// rilis jatuh ke kunci debug dan tetap jalan.
//
// Kuncinya sengaja tidak dibuatkan di sini. Kunci rilis gunanya membuktikan
// bahwa pembaruan berasal dari pembuat yang sama, jadi ia hanya bermakna kalau
// yang menyimpannya adalah pemilik aplikasi. Kalau kunci ini dibuat di mesin
// pengembang lalu hilang, aplikasinya tidak akan pernah bisa diperbarui —
// pengguna harus mencabut pasang dulu. Cara membuatnya ada di
// docs/INSTALLATION.md, dijalankan pihak sekolah sendiri.
val fileKunci = rootProject.file("key.properties")
val kunci = Properties().apply {
    if (fileKunci.exists()) FileInputStream(fileKunci).use { load(it) }
}
val adaKunciRilis = fileKunci.exists() &&
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .all { !kunci.getProperty(it).isNullOrBlank() }

android {
    namespace = "id.sch.smkalmadani.inventory_labkom"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.sch.smkalmadani.inventory_labkom"
        // minSdk mengikuti Flutter (24). flutter_secure_storage butuh API 23+,
        // jadi angka bawaan Flutter sudah memenuhi dan tidak perlu dipatok.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (adaKunciRilis) {
            create("release") {
                storeFile = file(kunci.getProperty("storeFile"))
                storePassword = kunci.getProperty("storePassword")
                keyAlias = kunci.getProperty("keyAlias")
                keyPassword = kunci.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Tanpa key.properties, APK rilis ditandatangani kunci debug:
            // tetap bisa dipasang, tapi pembaruannya tidak terotentikasi.
            // Konsekuensinya ditulis terang di catatan rilis, bukan disembunyikan.
            signingConfig = signingConfigs.getByName(
                if (adaKunciRilis) "release" else "debug"
            )
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

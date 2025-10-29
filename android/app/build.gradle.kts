plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.flashlingo"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flashlingo"
        minSdk = 24
        targetSdk = 36
        versionCode = 2
        versionName = "1.0.1"
        
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Disable minification to avoid R8 issues for now
            // Enable later when you have proper ProGuard rules
            isMinifyEnabled = false
            isShrinkResources = false
            
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM for version management
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    
    // Firebase dependencies (versions managed by BOM)
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
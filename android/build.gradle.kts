// The compileSdk every Android module in this build must reach.
//
// Several plugins pinned in this project still hardcode an outdated compileSdk in
// their own build.gradle:
//     app_links 3.5.1            -> compileSdkVersion 31
//     connectivity_plus 5.0.2    -> compileSdkVersion 33
//     device_info_plus 9.1.2     -> compileSdkVersion 33
//     firebase_messaging 14.7.10 -> compileSdkVersion 33
//     native_exif 0.6.2          -> compileSdkVersion 33
//
// Their AndroidX dependencies (fragment 1.7.1, activity 1.8.1, window 1.2.0, ...)
// declare that consumers must compile against API 34+, and AGP 9 promotes that
// mismatch from a warning to a hard failure:
//
//     Execution failed for task ':app_links:checkDebugAarMetadata'.
//     > Dependency 'androidx.fragment:fragment:1.7.1' requires libraries and
//       applications that depend on it to compile against version 34 or later
//       of the Android APIs.
//       :app_links is currently compiled against android-31.
//
// The plugins themselves are otherwise fine (they are pulled in transitively by
// supabase_flutter and firebase, and forcing newer majors through
// dependency_overrides would break their Dart APIs), so the mismatch is resolved
// here instead by raising compileSdk on every Android subproject to the same
// value the app uses (FlutterExtension.compileSdkVersion == 36).
val pluginCompileSdk = 36

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate

        // Looked up reflectively: with android.newDsl=false AGP 9 uses the legacy
        // DSL, where compileSdk is a `compileSdkVersion(int)` method. Reflection
        // keeps this root script compiling without AGP on its own classpath.
        val setter = androidExtension.javaClass.methods.firstOrNull { method ->
            method.name == "compileSdkVersion" &&
                method.parameterTypes.size == 1 &&
                (method.parameterTypes[0] == Int::class.javaPrimitiveType ||
                    method.parameterTypes[0] == Int::class.javaObjectType)
        }

        if (setter == null) {
            logger.warn(
                "[compileSdk] ${project.path} exposes an android extension but no " +
                    "compileSdkVersion(int) method; left unchanged.",
            )
        } else {
            setter.invoke(androidExtension, pluginCompileSdk)
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

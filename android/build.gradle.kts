allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val isar = name == "isar_flutter_libs"
    if (isar) {
        pluginManager.withPlugin("com.android.library") {
            val android = extensions.findByName("android")
            if (android != null) {
                // Fix 1: Namespace
                try {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "dev.isar.isar_flutter_libs")
                    println("Isar: Set namespace to dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    println("Isar: Failed to set namespace: $e")
                }

                // Fix 2: compileSdk (try multiple ways)
                try {
                    // Try property integer
                    val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Integer.TYPE)
                    setCompileSdk.invoke(android, 35)
                    println("Isar: Set compileSdk to 35")
                } catch (e: Exception) {
                     try {
                        // Fallback to older compileSdkVersion
                        val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                        setCompileSdkVersion.invoke(android, "android-35")
                        println("Isar: Set compileSdkVersion to android-35")
                     } catch (e2: Exception) {
                        println("Isar: Failed to set compileSdk: $e2")
                     }
                }
            }
        }
    }
    
    // Check if we need to force resolution strategy as a last resort
    // If lStar persists, we might need to apply this to the specific project configuration
    if (isar) {
         project.configurations.all {
             resolutionStrategy {
                 force("androidx.core:core:1.6.0")
             }
         }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
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

subprojects {
    // AGP 9 requires each Android library to compile against at least the SDK
    // of its dependencies. Several Flutter plugins still declare API 33/34.
    fun bumpLibraryCompileSdk() {
        extensions
            .findByType<com.android.build.api.dsl.LibraryExtension>()
            ?.compileSdk = 36
    }
    if (state.executed) {
        bumpLibraryCompileSdk()
    } else {
        afterEvaluate { bumpLibraryCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

allprojects {
    repositories {
        // First, so the AARs from a `pnpm sdk:bootstrap` (`publishToMavenLocal`
        // in `sdk/appwin-android`) win over the ones Maven Central holds under
        // the same version: otherwise a change to the native SDK stays
        // invisible here. The counterpart of the iOS Podfile's `:path =>` pods.
        mavenLocal()
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

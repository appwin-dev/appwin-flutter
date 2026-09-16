allprojects {
    repositories {
        google()
        mavenCentral()
        // The Appwin AARs are not published to a remote repository yet: we
        // consume them from `~/.m2` after a `./gradlew publishToMavenLocal` in
        // `sdk/android-build`. The counterpart of the iOS Podfile's `:path =>`
        // pods. To remove once the Maven repository exists.
        mavenLocal()
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

// Define repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define a custom build directory
val newBuildDir: org.gradle.api.file.Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Define the build directory for subprojects
subprojects {
    val newSubprojectBuildDir: org.gradle.api.file.Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensure all subprojects depend on the ":app" project
subprojects {
    project.evaluationDependsOn(":app")
}

// Register a clean task to delete the build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Add Google services plugin to the buildscript
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.google.gms:google-services:4.4.1") // Updated to latest stable version
    }
}
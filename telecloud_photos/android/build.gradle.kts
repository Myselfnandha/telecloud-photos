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

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android")
        if (android != null) {
            val namespace = try {
                android.javaClass.getMethod("getNamespace").invoke(android)
            } catch (e: Exception) {
                null
            }
            if (namespace == null) {
                val targetNamespace = if (name == "tdlib") "org.naji.td.tdlib" else "com.plugin.${name.replace('-', '_')}"
                try {
                    android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, targetNamespace)
                } catch (e: Exception) {
                    // ignore
                }
            }
        }
    }

    project.tasks.configureEach {
        if (name.contains("Manifest", ignoreCase = true)) {
            doFirst {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val cleaned = content.replace(Regex("""package="[^"]*""""), "")
                        manifestFile.writeText(cleaned)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

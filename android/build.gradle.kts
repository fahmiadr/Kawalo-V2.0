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
        val android = project.extensions.findByName("android") ?: return@withId
        try {
            val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
            val fallbackNamespace = project.group.toString().takeIf { it.isNotBlank() && it != "unspecified" }
                ?: "com.example.${project.name.replace('-', '_')}"
            setNamespaceMethod.invoke(android, fallbackNamespace)
        } catch (_: Exception) {
        }
    }
}

subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android") ?: return@afterEvaluate
            try {
                val setMethod = android.javaClass.getMethod("compileSdk", Int::class.javaPrimitiveType)
                setMethod.invoke(android, 36)
            } catch (_: Exception) {
            }
        }
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

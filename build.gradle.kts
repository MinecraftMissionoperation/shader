plugins {
    id("java")
}

group = "com.eaglercraft.shaders"
version = "1.0.0"

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

repositories {
    mavenCentral()
    maven {
        name = "eagler-teavm"
        url = uri("https://eaglercraft-teavm-fork.github.io/maven/")
    }
}

dependencies {
    implementation("com.carrotsearch:hppc:0.10.0")
    implementation("com.google.code.findbugs:jsr305:3.0.2")
    implementation("org.apache.commons:commons-lang3:3.6")
}

sourceSets {
    named("main") {
        java.srcDir("src/main/java")
        resources.srcDir("src/main/resources")
    }
}

tasks.withType<Jar> {
    entryCompression = ZipEntryCompression.STORED
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    manifest {
        attributes(
            "Implementation-Title" to "Eaglercraft Shader Collection",
            "Implementation-Version" to version,
            "Implementation-Vendor" to "Eaglercraft Shaders"
        )
    }
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.compilerArgs.addAll(listOf("-Xlint:unchecked", "-Xlint:deprecation"))
}
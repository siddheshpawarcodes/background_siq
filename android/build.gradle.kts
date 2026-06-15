allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.test:runner:1.3.0")

            // The ffmpeg_kit_flutter_new plugin pulls in `ffmpeg-kit-full-gpl`,
            // which ships every video codec (x264/x265/vpx…) and bloats each ABI
            // by ~20 MB. This app is audio-only (mp3/aac/flac/ogg/wav + audio
            // filters), so substitute the much smaller, LGPL `audio` variant.
            // Same publisher + version => clean drop-in.
            dependencySubstitution {
                substitute(module("com.antonkarpenko:ffmpeg-kit-full-gpl"))
                    .using(module("com.antonkarpenko:ffmpeg-kit-audio:2.1.0"))
                    .because("Audio-only app: drop full-gpl video codecs to shrink native libs")
            }
        }
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

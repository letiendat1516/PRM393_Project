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
    // flutter_plugin_android_lifecycle 2.0.35 build bằng compileSdk 36 (AAR metadata
    // yêu cầu >= 36) trong khi một số plugin cũ còn compileSdk thấp hơn (file_picker
    // 8.3.7 = 34, image_picker_android, flutter_local_notifications = 35) →
    // checkDebugAarMetadata fail. AGP 9 khoá extension sau khi đọc nên sauEvaluate
    // không set được — dùng hook chuẩn finalizeDsl (chạy sau khi DSL plugin điền xong,
    // trước khi bị khoá) để nâng compileSdk các module plugin lên 36.
    // SỬA TẬN GỐC (phiên chính): nâng file_picker / image_picker /
    // flutter_local_notifications trong pubspec.yaml rồi có thể xoá block này.
    plugins.withId("com.android.library") {
        // Gọi androidComponents.finalizeDsl qua Groovy interop — AGP 9 không expose
        // class extension này trên classpath của root script nên không gọi trực tiếp được.
        extensions.getByName("androidComponents").withGroovyBuilder {
            "finalizeDsl"(
                object : org.gradle.api.Action<Any> {
                    override fun execute(ext: Any) {
                        ext.withGroovyBuilder {
                            val cur = getProperty("compileSdk") as? Int
                            if (cur == null || cur < 36) {
                                setProperty("compileSdk", 36)
                            }
                        }
                    }
                }
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

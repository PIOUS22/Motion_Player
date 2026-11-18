"""Run after `flutter create`: adds Firebase plugins (if google-services.json exists)
and release signing (if KEYSTORE_PATH env is set). Idempotent."""
import os, re, pathlib
a = pathlib.Path('android')
settings, app = a / 'settings.gradle.kts', a / 'app' / 'build.gradle.kts'
if not settings.exists() or not app.exists():
    raise SystemExit('Expected Kotlin DSL gradle files (settings.gradle.kts / app/build.gradle.kts)')

if (a / 'app' / 'google-services.json').exists():
    t = settings.read_text()
    if 'google-services' not in t:
        t = re.sub(r'(\n\s*id\("com\.android\.application"\) version "[^"]+" apply false)',
                   r'\1\n    id("com.google.gms.google-services") version "4.4.2" apply false\n    id("com.google.firebase.crashlytics") version "3.0.2" apply false', t, 1)
        settings.write_text(t)
    t = app.read_text()
    if 'google-services' not in t:
        t = t.replace('id("dev.flutter.flutter-gradle-plugin")',
                      'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")\n    id("com.google.firebase.crashlytics")', 1)
        app.write_text(t)

if os.environ.get('KEYSTORE_PATH'):
    t = app.read_text()
    if 'motionRelease' not in t:
        t += '''
android {
    signingConfigs {
        create("motionRelease") {
            storeFile = file(System.getenv("KEYSTORE_PATH"))
            storePassword = System.getenv("STORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes { getByName("release") { signingConfig = signingConfigs.getByName("motionRelease") } }
}
'''
        app.write_text(t)
print('gradle patched')

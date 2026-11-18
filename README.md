# Motion Player
1. `flutter create --platforms=android .` inside this folder (keeps lib/ and pubspec.yaml)
2. Replace android/app/src/main/AndroidManifest.xml with the provided one (match your MainActivity package)
3. In android/app/build.gradle(.kts): minSdk 24, compileSdk 34+
4. `flutter pub get && flutter run`
Structure: core/ (theme) | features/library | player | equalizer | vault. State: Riverpod.

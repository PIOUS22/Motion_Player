# Owner guide - controlling Motion Player

## A. One-time setup
1. Firebase: console.firebase.google.com > Add project > Add Android app, package `com.motionplayer.motion_player`.
   Download `google-services.json`.
2. GitHub > repo > Settings > Secrets and variables > Actions, add:
   - `GOOGLE_SERVICES_JSON` = `base64 -w0 google-services.json`
   - Signing key (create once, KEEP A BACKUP):
     `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias motion`
     `KEYSTORE_BASE64` = `base64 -w0 release.jks`, `STORE_PASSWORD`, `KEY_ALIAS` (motion), `KEY_PASSWORD`
3. In Firebase console add SHA-1/SHA-256 of your release key (optional, needed for some services).
4. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`.

## B. Admin panel = Firebase Console (free)
| Need | Where |
|---|---|
| Force update / kill switch / announcement / feature flags | Remote Config |
| Push notification to all users | Messaging > New campaign > Topic `all` |
| Users, countries, devices, events | Analytics |
| Crashes with code line | Crashlytics |

### Remote Config keys (Publish changes after editing)
| Key | Example | Effect |
|---|---|---|
| min_version | 1.2.0 | Older apps are blocked with "Update required" + Download/Install |
| kill_switch | true | Blocks the app and shows kill_message |
| kill_message | "Please update" | Text on the block screen |
| announcement | "New equalizer presets!" | Banner on the home screen |
| announcement_id | 2 | Change it so people who dismissed see the new message |
| ads_enabled | false | Hides ads (premium / ad-free period) |
| feature_vault, feature_equalizer | false | Flags (add checks where you want to switch features off) |

## C. Income (AdMob)
1. admob.google.com > add app > copy App ID and a Banner unit ID.
2. Replace the TEST ids in `AndroidManifest.xml` (APPLICATION_ID) and `lib/features/ads/ad_banner.dart` (_bannerUnit).
3. Never click your own live ads. Add a privacy policy (required).

## D. Play Store with staged rollout
1. play.google.com/console ($25 one-time) > Create app.
2. First release: upload the `.aab` from the GitHub Actions artifact (Internal testing first).
3. Production > Create release > Upload .aab > Rollout percentage 10% > later raise to 50%, 100%.
   Problem found? Use "Halt rollout".
4. Fill Data safety (mention analytics, crash logs, ads) and a privacy policy URL.
5. Every new version needs a higher versionCode: the workflow uses the run number automatically.

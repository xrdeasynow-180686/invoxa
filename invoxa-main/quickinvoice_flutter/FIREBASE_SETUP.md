# Firebase Analytics — Setup for InovXA

The app uses Firebase Analytics to track only three events:

| Event              | When it fires                                         |
|--------------------|-------------------------------------------------------|
| `app_open`         | Every time the app is launched                        |
| `invoice_created`  | Right after a PDF is successfully generated           |
| `invoice_shared`   | After the OS share sheet reports a successful share   |

Analytics is **optional at dev time** — the app boots fine without Firebase
configured (all calls become no-ops). Follow the steps below to enable it
for a release build.

---

## 1. Create a Firebase project

1. Open <https://console.firebase.google.com/> and click **Add project**.
2. Name it e.g. `InovXA` and finish the wizard.
3. In the project, click **Add app** and pick the platforms you need
   (Android and/or iOS).

### Android
- **Package name**: must match the one in
  `android/app/build.gradle` (by default `com.example.inovxa` — change it in
  `applicationId` if you have your own).
- Download **`google-services.json`** and drop it into
  `android/app/google-services.json` (same folder as `build.gradle`).
- In **`android/build.gradle`** (project-level) add inside `buildscript > dependencies`:
  ```gradle
  classpath 'com.google.gms:google-services:4.4.2'
  ```
- In **`android/app/build.gradle`** add at the very bottom:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```
- `minSdkVersion` must be `21` or higher (already the case for this project).

### iOS
- **Bundle ID**: must match the one in `ios/Runner.xcodeproj` (default
  `com.example.inovxa`).
- Download **`GoogleService-Info.plist`** and drag it into
  `ios/Runner/` in Xcode (make sure "Copy items if needed" and the
  `Runner` target are ticked).
- Open `ios/Runner/AppDelegate.swift` — nothing to change; the Flutter
  `firebase_core` plugin auto-initialises from the plist.

---

## 2. Install dependencies

The two Firebase packages are already declared in `pubspec.yaml`:

```yaml
firebase_core: ^3.6.0
firebase_analytics: ^11.3.3
```

Run:

```bash
flutter pub get
```

That is the only code change needed — `lib/main.dart` already calls
`Firebase.initializeApp()` and `AnalyticsService.enable()`.

---

## 3. Verify events are flowing

1. `flutter run` the app on a real device (Analytics will not populate in
   an emulator unless Google Play Services is installed).
2. Open <https://console.firebase.google.com/project/_/analytics/debugview>.
3. On the device, enable Analytics debug mode (once):
   ```bash
   adb shell setprop debug.firebase.analytics.app <your.package.name>
   ```
   (iOS: `-FIRDebugEnabled` in Xcode scheme arguments.)
4. Launch the app → `app_open` should show up in DebugView within seconds.
5. Create and share an invoice → `invoice_created` and `invoice_shared`
   should follow.

Once confirmed, remove the debug flag:
```bash
adb shell setprop debug.firebase.analytics.app .none.
```

---

## 4. Common pitfalls

- **`Default FirebaseApp is not initialized`** — usually means
  `google-services.json` is missing or the `com.google.gms.google-services`
  plugin line was not added in `android/app/build.gradle`.
- **Events never appear in the Analytics dashboard** — standard (non-debug)
  events take up to 24 hours to aggregate. Use DebugView for instant feedback.
- **iOS release build crash on launch** — confirm the
  `GoogleService-Info.plist` is included in the `Runner` target's **Build
  Phases → Copy Bundle Resources** list.

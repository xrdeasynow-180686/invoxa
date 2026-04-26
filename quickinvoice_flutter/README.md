# InovXA — QuickInvoice (Flutter)

A simple, fast invoice generator. Create a professional invoice with your logo and
export/share it as a PDF in under 30 seconds.

## Features
- Business details: name, address, **phone, email, ABN (optional)** + logo
- Client details
- Auto-generated invoice number, today's date by default
- Add multiple items (name, qty, price) with auto-calculated total
- Logo upload from device gallery
- Manual currency symbol (e.g. `$`, `€`, `₹`, `AED`, etc.)
- Generate professional PDF (logo + business + client + items table + bold total)
- **All business details (name, address, phone, email, ABN, logo) are saved locally and auto-fill on next launch**
- Save PDF locally and share via WhatsApp, Email, etc.

## Project structure
```
lib/
├── main.dart
├── screens/
│   └── invoice_form_screen.dart
├── models/
│   ├── invoice.dart
│   └── item.dart
├── services/
│   └── pdf_service.dart
└── widgets/
    └── item_input_widget.dart
```

## Setup

### 1. Prerequisites
- Flutter 3.19+ (Dart 3.3+) — verify with `flutter --version`
- Android Studio / Xcode for device deploys

### 2. Create the Flutter project shell
This repository ships only the `lib/` folder and `pubspec.yaml`. Generate the native
platform folders (android/, ios/) on your machine:

```bash
# In a new empty directory:
flutter create --project-name inovxa --org com.inovxa .
# Now copy the provided lib/ folder and pubspec.yaml into this directory,
# OVERWRITING the auto-generated ones.
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Platform configuration

**iOS** — open `ios/Runner/Info.plist` and add:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pick your business logo for invoices</string>
<key>NSCameraUsageDescription</key>
<string>Capture your business logo</string>
```

**Android** — open `android/app/src/main/AndroidManifest.xml` and add the following so the generated PDF lands in the public **Downloads** folder (visible in any file manager):

1. Inside `<manifest>` (above `<application>`):
   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                    android:maxSdkVersion="32" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                    android:maxSdkVersion="32" />
   ```
2. On the `<application ...>` tag add:
   ```xml
   android:requestLegacyExternalStorage="true"
   ```

> Note: On Android 13+ (API 33) the app falls back to its private documents directory because the public `Downloads` folder requires the MediaStore API to write reliably across all OEMs. The path that was used is shown in the success sheet, and the file can still be opened/shared from there.

### 5. Generate the app launcher icon (one-time)
The brand icon is included at `assets/app_icon.png`. To bake it into Android & iOS native icon sets:

```bash
flutter pub get
dart run flutter_launcher_icons
```

This regenerates `android/app/src/main/res/mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset` automatically. Re-run this command any time you replace `assets/app_icon.png`.

### 6. Run
```bash
flutter run
```

## Packages used (all stable, null-safe)
- `pdf` ^3.11.1 — PDF document construction
- `printing` ^5.13.2 — PDF preview / print sheet
- `image_picker` ^1.1.2 — pick logo from gallery
- `path_provider` ^2.1.4 — local filesystem path for saving PDF
- `share_plus` ^10.0.2 — system share sheet (WhatsApp, Email, …)
- `intl` ^0.19.0 — date formatting
- `shared_preferences` ^2.3.2 — local key-value storage for the saved business profile (offline)

> No deprecated/discontinued packages; `open_file` is intentionally NOT used.

## How to use
1. **First launch** — a snackbar prompts you to enter your business details.
2. Tap the logo placeholder → pick an image from your gallery.
3. Fill in business and client details.
4. The invoice number and date are pre-filled (editable date via tap).
5. Add items; each row auto-calculates a subtotal; grand total updates live.
6. Tap **Generate Invoice** → a sheet appears with:
   - **Preview / Print** — system print/preview dialog
   - **Share PDF** — WhatsApp, Email, Drive, etc.
   - The local save path is shown at the bottom.
7. Your **logo, business name, and address are saved locally** (SharedPreferences) when you tap *Generate Invoice*. On the next launch they auto-fill — you only have to enter the client and items.
8. Tap the **trash icon** in the app bar to clear the saved business profile.

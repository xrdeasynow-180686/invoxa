# InovXA — QuickInvoice (Flutter)

A simple, fast invoice generator. Create a professional invoice with your logo and
export/share it as a PDF in under 30 seconds.

## Features
- Business & client details
- Auto-generated invoice number, today's date by default
- Add multiple items (name, qty, price) with auto-calculated total
- Logo upload from device gallery
- Manual currency symbol (e.g. `$`, `€`, `₹`, `AED`, etc.)
- Generate professional PDF (logo + business + client + items table + bold total)
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

**Android** — `image_picker` works without extra permissions on modern Android
(the system Photo Picker is used). No edits needed for typical builds.

### 5. Run
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

> No deprecated/discontinued packages; `open_file` is intentionally NOT used.

## How to use
1. Tap the logo placeholder → pick an image from your gallery.
2. Fill in business and client details.
3. The invoice number and date are pre-filled (editable date via tap).
4. Add items; each row auto-calculates a subtotal; grand total updates live.
5. Tap **Generate Invoice** → a sheet appears with:
   - **Preview / Print** — system print/preview dialog
   - **Share PDF** — WhatsApp, Email, Drive, etc.
   - The local save path is shown at the bottom.

# InovXA — Tradie Edition — PRD

## Original problem statement
Transform the existing InovXA Flutter invoice maker into a niche product
for tradies (electricians, plumbers, mechanics). Core goal: a tradie
should be able to finish a job → create an invoice → send via WhatsApp
in under 10–15 seconds. Keep the app lightweight and fast for low-end
Android. Do not over-engineer. No TODOs, full working code only.

## Architecture (unchanged, just extended)
- Flutter / Material 3, Dart SDK 3.3+
- Local-only storage via SharedPreferences (no backend, no DB)
- PDF via `pdf` + `printing` + `share_plus`
- Firebase Analytics (firebase_core + firebase_analytics) — optional
  at dev time, wrapped in try/catch in main.dart
- In-App Purchase for Pro entitlement (pre-existing, untouched)

## User persona
Field tradie (electrician / plumber / mechanic) on-site, needs to bill
a customer fast on a phone with a cracked screen in direct sunlight.

## Core requirements (locked)
1. Create Invoice → PDF → Share sheet in ≤15 s (Quick Invoice Mode)
2. Auto-fill business details, currency and default item
3. Big, sunlight-friendly tap targets & high-contrast indigo theme
4. Paid / Pending status tracking on every invoice
5. Call-out Fee & Hourly Rate quick-add buttons
6. Firebase Analytics — only 3 events (app_open, invoice_created,
   invoice_shared)

## Implemented (2026-01)
- NEW `lib/screens/quick_invoice_screen.dart` — fast flow
- Rebuilt `lib/screens/invoice_history_screen.dart` — tradie home with
  greeting, stats (This month / Paid / Pending), big Create Invoice CTA,
  status badges on recent invoices
- NEW `lib/services/analytics_service.dart` — defensive Firebase wrapper
- NEW `lib/services/last_client_storage.dart` — saves last client name
- Updated `lib/main.dart` — Firebase init + app_open event
- Updated `lib/screens/invoice_form_screen.dart` — Call-out Fee &
  Hourly Rate quick-add buttons, default "Service Work" line,
  last-client recall, analytics events
- Updated `lib/screens/invoice_detail_screen.dart` — Mark Paid /
  Mark Pending toggle
- Updated models + history storage for `status: paid | pending`
  (backward-compatible JSON fallback)
- Added `firebase_core ^3.6.0`, `firebase_analytics ^11.3.3` to pubspec
- Added `FIREBASE_SETUP.md` with platform-specific setup steps

## Backlog / next
- P1: Add client directory (save multiple past clients, pick from list)
- P1: "Mark as Paid" push via WhatsApp reminder after N days
- P2: CSV export of invoice history for bookkeepers
- P2: Optional photo attachment of completed job

## Non-goals
- No backend, no user accounts, no cloud sync
- No redesign of the invoice PDF (existing polished template kept)
- No extra auth / login

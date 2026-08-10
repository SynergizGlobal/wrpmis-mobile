# WR PMIS Mobile

Western Railways Project Management Information System — Flutter app for Android & iOS.

## Stack

- Flutter 3.44 / Dart 3.12
- Riverpod + go_router + Dio
- Feature-first clean architecture (`lib/src/{app,core,features}`)

## Platforms

| Platform | Package / Bundle ID | Notes |
|----------|---------------------|--------|
| Android | `com.synergiz.wr.pmis` | **targetSdk / compileSdk 36 (Android 16)**, minSdk 24 |
| iOS | `com.synergiz.wr.pmis` | Cleartext ATS enabled for current QA host |

## User feedback

Use `GlobalDialog` for all user messages — **never** use `SnackBar`, `Toast`, or `ScaffoldMessenger`.

```dart
await GlobalDialog.info('Message', title: 'Title');
await GlobalDialog.error('Something went wrong.');
await GlobalDialog.success('Saved successfully.');
final bool ok = await GlobalDialog.confirm(message: 'Are you sure?');
```


```bash
flutter pub get
flutter run
```

Switch QA/Prod in `lib/main.dart` via `Environment.init(Env.qa | Env.prod)`.

## Current screens

1. **Login** — WR branding (ochre panel, IR logo)
2. **Home** — project summary + category cards
3. **Update Forms** — API-driven list with submenu sheet
4. **Profile** — session details, settings, logout

## API base

Configured in `lib/src/core/constants/api_hosts.dart`:

- QA: `http://203.153.40.44:90/wrpmis_qa/`
- Prod: `http://203.153.40.44:90/wrpmis/`

Endpoints in `lib/src/core/constants/api_constants.dart` (aligned with WCR-style PMIS paths).

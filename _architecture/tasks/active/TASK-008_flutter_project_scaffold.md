# TASK-008 — `client_flutter` Project Scaffold + pubspec

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `c:\horaizon-3.0\client_flutter\` |
| **Blocks** | TASK-009, TASK-010, TASK-011, TASK-012 |
| **Prerequisites** | Flutter SDK installed (`flutter doctor` passes for Windows + Android) |

---

## Context & Architectural Directives

Bootstrap the `client_flutter` Flutter project from scratch. This task covers: `flutter create`, `pubspec.yaml` with all Phase 1 dependencies, folder structure aligned with the spec, `analysis_options.yaml`, and platform-specific config for Windows and Android.

> [!IMPORTANT]
> **NO SDUI. NO LOCAL DRIFT DATABASE.**
> - **ADR-001 Native UI**: All UI is 100% native Flutter Dart widgets. Zero SDUI engine, zero `SduiSocketManager`, zero `SduiStateVault`, zero `SduiTransport`.
> - **Online-Only Architecture**: No client-side Drift/SQLite database (`LocalDatabase`), no offline sync queues (`ShuaSyncQueue`), no Lamport clock columns. Pi 5 is the single source of truth at all times.
> - Communication is strictly typed MessagePack over WebSocket (HBP v2) using Riverpod providers.

Read `_architecture/specs/client_flutter/client_flutter_spec.md` before implementing.

---

## Step 1: Create the Flutter project

```powershell
cd c:\horaizon-3.0

# Create with Windows + Android targets only (explicitly exclude others)
flutter create client_flutter `
  --org dev.horaizon `
  --project-name client_flutter `
  --platforms windows,android `
  --template app
```

Verify:
```powershell
cd client_flutter
flutter doctor
flutter run -d windows  # should open a blank Flutter window
```

---

## Step 2: Replace `pubspec.yaml`

Replace the entire generated `pubspec.yaml` with:

```yaml
name: client_flutter
description: "horAIzon 3.0 — Native Flutter client (Windows + Android)"
version: 0.1.0+1
publish_to: 'none'

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.2

  # MessagePack (HBP v2 payload encoding)
  messagepack: ^0.2.2

  # WebSocket
  web_socket_channel: ^3.0.1

  # Local persistence (user preferences only: theme, host IP, etc. — NO DB)
  shared_preferences: ^2.3.1

  # Biometric authentication (Face ID / Touch ID / Fingerprint fallback)
  local_auth: ^2.2.0

  # mDNS Pi 5 discovery on LAN
  multicast_dns: ^0.3.2+3

  # Material You Android dynamic color
  dynamic_color: ^1.7.0

  # UUID generation
  uuid: ^4.4.0

  # Fonts
  google_fonts: ^6.2.1

  # Material color utilities (HCT theme)
  material_color_utilities: ^0.11.1

  # Icons & SVG
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.11
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.13

flutter:
  uses-material-design: true
  fonts:
    - family: Outfit
      fonts:
        - asset: assets/fonts/Outfit-Regular.ttf
        - asset: assets/fonts/Outfit-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Outfit-Bold.ttf
          weight: 700
    - family: Lora
      fonts:
        - asset: assets/fonts/Lora-Regular.ttf
        - asset: assets/fonts/Lora-Italic.ttf
          style: italic
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
  assets:
    - assets/fonts/
```

Then run:
```powershell
flutter pub get
```

---

## Step 3: Download fonts

Download from Google Fonts and place in `assets/fonts/`:
- **Outfit**: Regular, SemiBold, Bold — https://fonts.google.com/specimen/Outfit
- **Lora**: Regular, Italic — https://fonts.google.com/specimen/Lora
- **JetBrains Mono**: Regular, Bold — https://fonts.google.com/specimen/JetBrains+Mono

```powershell
New-Item -ItemType Directory -Force client_flutter/assets/fonts
```

---

## Step 4: Create the full native folder structure

```powershell
cd client_flutter

# Core
New-Item -ItemType Directory -Force `
  lib/core/hbp,`
  lib/core/hbp/generated,`
  lib/core/config,`
  lib/core/theme,`
  lib/core/auth,`
  lib/core/logging

# Features — Phase 1
New-Item -ItemType Directory -Force `
  lib/features/dashboard,`
  lib/features/settings,`
  lib/features/governor

# Features — Phase 2/3 stubs
New-Item -ItemType Directory -Force `
  lib/features/resume,`
  lib/features/diary,`
  lib/features/diary/widgets,`
  lib/features/diary/widgets/blocks,`
  lib/features/code_visualizer

# Shared
New-Item -ItemType Directory -Force `
  lib/shared/widgets,`
  lib/shared/models

# Router
New-Item -ItemType Directory -Force lib/router
```

---

## Step 5: Write `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
  exclude:
    - lib/core/hbp/generated/**
    - "**/*.g.dart"

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_final_fields: true
    use_key_in_widget_constructors: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
```

---

## Step 6: Write stub files for all modules

Create a placeholder `// TODO` file in each feature directory:

**`lib/features/resume/resume_screen.dart`**
```dart
// TODO: Implemented in Phase 3
// See _architecture/specs/shua_resume/shua_resume_spec.md
```

**`lib/features/diary/diary_screen.dart`**
```dart
// TODO: Implemented in Phase 3
// See TASK-019_flutter_diary_screen_and_block_library.md
```

**`lib/features/code_visualizer/code_topology_screen.dart`**
```dart
// TODO: Implemented in Phase 2
// See TASK-016
```

---

## Step 7: Write `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: HoraizonApp()));
}
```

---

## Step 8: Write `lib/app.dart` (placeholder — full impl in TASK-010)

```dart
import 'package:flutter/material.dart';

/// Root application widget.
/// GoRouter and theme are wired up in TASK-010.
class HoraizonApp extends StatelessWidget {
  const HoraizonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'horAIzon 3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'horAIzon 3.0',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
```

---

## Step 9: Android — set minimum SDK

Edit `android/app/build.gradle`:
```gradle
android {
    compileSdk = 35
    defaultConfig {
        minSdk = 26          // Android 8.0 — required for WebSocket + modern APIs
        targetSdk = 35
    }
}
```

---

## Step 10: Verify

```powershell
flutter pub get
flutter analyze           # should pass with no errors
flutter run -d windows    # blank dark screen with "horAIzon 3.0" text
```

---

## Acceptance Criteria

- [ ] `flutter create` succeeded — project exists at `client_flutter/`
- [ ] Zero SDUI, zero local Drift database dependencies
- [ ] `pubspec.yaml` has `dynamic_color`, `local_auth`, `multicast_dns`, `go_router`, `flutter_riverpod`, `messagepack`, `web_socket_channel`
- [ ] `flutter pub get` succeeds with no dependency conflicts
- [ ] All font files exist in `assets/fonts/`
- [ ] All feature directory stubs exist (including native diary block folder)
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter run -d windows` — app launches on Windows
- [ ] Android minimum SDK set to 26

---

## References

- `_architecture/specs/client_flutter/client_flutter_spec.md` — technology stack, folder structure
- `_architecture/decisions/ADR-001_native_over_sdui.md` — native over SDUI directive

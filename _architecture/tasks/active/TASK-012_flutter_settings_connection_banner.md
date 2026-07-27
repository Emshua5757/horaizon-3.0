# TASK-012 — `client_flutter` SettingsScreen + Connection Banner & 7 Theme Presets Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] In progress (Active) |
| **Branch** | `task/TASK-012-theme-engine` |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart (Flutter Native M3) |
| **Target** | `client_flutter/lib/core/theme/`, `client_flutter/lib/features/settings/`, `client_flutter/lib/shared/widgets/` |
| **Complexity** | Time: $O(1)$ theme compilation & reactive rebuild, Space: $O(1)$ memory allocation for cached presets |

---

## 📌 Sub-Task Execution Checklist

- [ ] **Sub-Task 1: Core Theme Contracts (`AppEffectsTheme` & `AppSemanticPalette`)**
  - Path: `client_flutter/lib/core/theme/app_effects_theme.dart` & `app_semantic_palette.dart`
  - Purpose: Define `ThemeExtension<AppEffectsTheme>` and `AppSemanticPalette` for dynamic shadows, corner radius, borders, noise grain, and harmonized status/chart colors across themes.
  - Complexity: Time $O(1)$, Space $O(1)$.

- [ ] **Sub-Task 2: Modular Presets Contract & 7 Preset Implementations**
  - Path: `client_flutter/lib/core/theme/app_theme_preset.dart` & `client_flutter/lib/core/theme/presets/`
  - Files to create:
    1. `cyber_obsidian.dart` (Cyberpunk Dark & Slate Light variants)
    2. `creamy_latte.dart` (Ceramic Cream & Roasted Mocha variants)
    3. `oled_pure_black.dart` (Tactical OLED Black & High-Contrast White variants)
    4. `midnight_synthwave.dart` (Deep Space Navy & Solar Flare variants)
    5. `matchaZen.dart` (Dark Forest Pine & Light Matcha Tea variants)
    6. `cyber_amber.dart` (Industrial Rust & Amber Sand variants)
    7. `vintage_parchment.dart` (Antique Parchment & Dark Sepia Leather variants)
  - Complexity: Time $O(1)$, Space $O(1)$.

- [ ] **Sub-Task 3: Preset Registry, Theme Compiler & Circadian Provider**
  - Path: `client_flutter/lib/core/theme/theme_preset_registry.dart`, `theme_compiler.dart`, `theme_provider.dart`
  - Purpose: Dynamic registry for presets, compiler converting presets to `ThemeData`, and Riverpod `ThemeNotifier` handling SharedPreferences persistence, Light/Dark variants, and Circadian Time-of-Day auto-shifting.
  - Complexity: Time $O(1)$, Space $O(1)$.

- [ ] **Sub-Task 4: Universal `AppCard` Container & `ConnectionStatusBanner` Widget**
  - Path: `client_flutter/lib/shared/widgets/app_card.dart` & `connection_status_banner.dart`
  - Purpose: Create adaptive container wrapper listening to `AppEffectsTheme` and live WebSocket connection health banner.
  - Complexity: Time $O(1)$ layout rendering.

- [ ] **Sub-Task 5: Interactive `SettingsScreen` UI**
  - Path: `client_flutter/lib/features/settings/settings_screen.dart`
  - Sections:
    1. 🎨 **Visual Engine (7 Theme Vibe Cards)**: Grid selector, Light/Dark/Circadian toggle, accent swatches, font profile, animation slider.
    2. 🌐 **Network & Pi 5 Connection**: Tailscale Host/Port text fields + mDNS `horaizon.local` auto-discovery button.
    3. 🛠️ **Developer Tools**: Launch `/dev/blocks` gallery button.
    4. ℹ️ **About**: System summary node details.
  - Complexity: Time $O(1)$, Space $O(1)$.

- [ ] **Sub-Task 6: Developer `BlockGalleryScreen` Route (`/dev/blocks`)**
  - Path: `client_flutter/lib/features/diary/block_gallery_screen.dart` & `app_router.dart`
  - Purpose: Preview all native diary block widgets in a scrollable gallery for developer testing.

- [ ] **Sub-Task 7: Verification & Clean Build**
  - Run `flutter analyze lib/` to verify zero errors / zero warnings.
  - Verify hot reload in running `flutter run -d windows` app.

---

## 🎨 Detailed Preset Matrix (8 Design Dimensions)

```text
lib/core/theme/
  ├── app_effects_theme.dart       <-- ThemeExtension for shadows, blurs, borders, noise grain & halo LEDs
  ├── app_semantic_palette.dart    <-- Semantic colors for telemetry charts, temp badges & status LEDs
  ├── app_theme_preset.dart        <-- Abstract contract for multi-dimensional presets (Light/Dark variants)
  ├── theme_preset_registry.dart   <-- Dynamic registry listing all available presets
  ├── theme_compiler.dart          <-- Compiles any AppThemePreset into ThemeData
  ├── theme_provider.dart          <-- Riverpod notifier (Circadian timer, Light/Dark toggle, SharedPreferences)
  └── presets/                      <-- 📁 Modular single-file theme presets
      ├── cyber_obsidian.dart       (Dark & Light Cyberpunk variants)
      ├── creamy_latte.dart         (Warm Light Cream & Dark Roasted Mocha variants)
      ├── oled_pure_black.dart      (Tactical OLED Black & High-Contrast White variants)
      ├── midnight_synthwave.dart   (Deep Space Synthwave & Solar Flare variants)
      ├── matcha_zen.dart           (Dark Forest Pine & Light Matcha Tea variants)
      ├── cyber_amber.dart          (Industrial Dark Rust & Amber Sand variants)
      └── vintage_parchment.dart    (Antique Parchment & Dark Sepia Leather variants)
```

---

## Acceptance Criteria

- [ ] Git feature branch `task/TASK-012-theme-engine` active
- [ ] 7 single-file presets created under `lib/core/theme/presets/`
- [ ] `AppEffectsTheme` and `AppSemanticPalette` integrated with `AppCard`
- [ ] `ConnectionStatusBanner` shows live WebSocket status
- [ ] Interactive `SettingsScreen` UI functional with preset selector & circadian shift
- [ ] `flutter analyze` — 0 errors, 0 warnings

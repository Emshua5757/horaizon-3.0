# TASK-012 — `client_flutter` SettingsScreen + Connection Banner & Block Gallery

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/features/settings/`, `lib/shared/widgets/` |
| **Blocks** | Nothing — this completes Phase 1 Flutter |
| **Prerequisites** | TASK-011 complete |

---

## Context & Native Improvements

Implement the rich Settings screen (with advanced visual customization & mDNS Pi 5 auto-discovery), the `ConnectionStatusBanner` live health pill widget, and the developer `BlockGalleryScreen` route.

> [!NOTE]
> **Native Upgrades in 3.0**:
> 1. **`ConnectionStatusBanner`**: A subtle animated banner/pill at the top of the shell showing live WebSocket health (`Connected` = green pulse, `Reconnecting` = amber spin, `Offline` = red banner disabling UI interactions).
> 2. **State-of-the-Art Visual Customization Card**:
>    - Primary & Secondary Color Seed Swatches (Cyber Blue `#00E5FF`, Cyber Emerald `#00E5A0`, Violet `#9D4EDD`, Sunset `#FF6B6B`).
>    - Surface Material Modes (`Cyber Obsidian` `#0D0D12`, `OLED Pure Black` `#000000`, `Midnight Space` `#121826`, `Warm Light` `#F7F5F0`).
>    - Typography Profiles (`Modern Outfit`, `Cyber Mono`, `Editorial Lora`).
>    - Glowing Borders Switch (primary/secondary neon aura around cards).
>    - Android Wallpaper Toggle (`dynamic_color`).
>    - Micro-animation speed slider (`150ms` - `500ms`) & Font scale slider.
> 3. **mDNS LAN Auto-Discovery**: Network settings card includes a *"Scan for Pi 5"* button that broadcasts mDNS query (`horaizon.local`) using `multicast_dns` package to auto-fill the Tailscale/LAN IP.
> 4. **Developer `BlockGalleryScreen` (`/dev/blocks`)**: Interactive gallery preview route displaying all 36 native diary block widgets in demo state (replaces `SduiSandboxScreen`).

---

## Part A — ConnectionStatusBanner Widget (`lib/shared/widgets/connection_status_banner.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/hbp/hbp_client.dart';
import '../../core/hbp/hbp_client_provider.dart';

class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(hbpConnectionStateProvider);
    final theme = Theme.of(context);

    return stateAsync.when(
      data: (state) {
        if (state == HbpConnectionState.connected) return const SizedBox.shrink();

        final (color, message) = switch (state) {
          HbpConnectionState.connecting => (Colors.amber, 'Connecting to Pi 5…'),
          HbpConnectionState.reconnecting => (Colors.amber, 'Reconnecting to Pi 5…'),
          _ => (Colors.red, 'Offline — Cannot connect to Pi 5 (ws://100.67.11.0:7700)'),
        };

        return Container(
          width: double.infinity,
          color: color.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == HbpConnectionState.connecting || state == HbpConnectionState.reconnecting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              else
                const Icon(Icons.wifi_off, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

---

## Part B — SettingsScreen (`lib/features/settings/settings_screen.dart`)

Organized into four distinct glassmorphic Card sections:

### 1. Appearance & Visual Engine
- **Primary & Secondary Seed Swatches**: Interactive color dots (Cyber Blue, Cyber Emerald, Violet, Coral, Solar Gold).
- **Surface Material Mode Segmented Button**: `Obsidian`, `OLED Black`, `Midnight Space`, `Warm Light`.
- **Typography Segmented Button**: `Modern Outfit` (Sans), `Cyber Mono` (JetBrains Mono display), `Editorial Lora` (Serif).
- **Glowing Borders Switch**: Toggles `primarySeed.withOpacity(0.35)` outline around cards.
- **Android Wallpaper Match Switch**: Uses `dynamic_color` wallpaper extraction when on Android.
- **Animation Speed Slider**: `150ms` (Snappy) to `500ms` (Smooth).
- **Font Scale Slider**: `0.8×` to `1.4×`.

### 2. Network & Pi 5 Connection
- **Host & Port TextFields**: Tailscale/LAN IP (`100.67.11.0`) and Port (`7700`).
- **mDNS Auto-Discovery Button**: Broadcasts `horaizon.local` query to auto-fill host IP.
- **Live Connection Chip**: Displays resolved WebSocket target (`ws://100.67.11.0:7700/hbp`).

### 3. Developer Tools
- **Block Gallery Launcher**: Button navigating to `/dev/blocks` (`BlockGalleryScreen`) for testing all 36 native diary block widgets.

### 4. About
- **System Architecture Summary**: horAIzon 3.0 Native Flutter Client, HBP v2 MessagePack RPC, Raspberry Pi 5 node details.

---

## Part C — Developer `BlockGalleryScreen` (`lib/features/diary/block_gallery_screen.dart`)

Renders all 36 native block widgets in a scrollable preview list for dev testing.

---

## Acceptance Criteria

- [ ] `ConnectionStatusBanner` displays animated reconnect status and red offline banner
- [ ] Settings screen includes complete rich visual customizer (primary/secondary seeds, surface modes, glowing borders, typography profiles, animation slider)
- [ ] Settings screen includes mDNS auto-discovery scan for `horaizon.local`
- [ ] `/dev/blocks` route opens `BlockGalleryScreen` showing all 36 native block types
- [ ] `flutter analyze` — 0 errors

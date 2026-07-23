# client_flutter — Specification

| Field | Value |
| :--- | :--- |
| **Language** | Dart |
| **Framework** | Flutter |
| **Phase** | Phase 1 |
| **Targets** | Windows (MSI, 100.90.83.12) + Android (Moto G84, 100.111.230.72) |
| **State** | Riverpod (`AsyncNotifier`, `Notifier`, `StreamNotifier`) |
| **Navigation** | GoRouter (typed routes) |
| **Transport** | HBP v2 client (WebSocket + MessagePack) |
| **UI** | Native Flutter widgets — NO SDUI renderer |

---

## Design Principles

1. **No SDUI**. There is no blueprint loader, no screen assembler, no `SduiBlockRegistry`. Screens are `.dart` files.
2. **Typed state everywhere**. Every provider has a typed model class. No `dynamic`, no `Map<String, dynamic>` at the state layer.
3. **HBP v2 is the only transport**. No raw REST calls. All data flows through the `HbpClient` WebSocket.
4. **Platform-adaptive layout**. Windows = larger canvas, multi-column where appropriate. Android = single-column, bottom nav bar. GoRouter handles routing identically on both.
5. **Offline shell**. The app can launch and navigate even when the Pi5 is unreachable. Screens show a connection error state, not a crash.

---

## Technology Stack

| Concern | Package |
| :--- | :--- |
| State management | `riverpod` + `flutter_riverpod` + `riverpod_annotation` |
| Navigation | `go_router` |
| MessagePack encode/decode | `messagepack` (pub.dev) |
| WebSocket | `web_socket_channel` |
| Theming | Custom `ThemeData` — HCT color system (`material_color_utilities`) |
| Fonts | `google_fonts` (Outfit, JetBrains Mono, Lora) |
| Persistent local config | `shared_preferences` (Pi5 URL, Tailscale vs LAN toggle) |
| Animations | Flutter built-in (`AnimatedWidget`, `TweenAnimationBuilder`) |
| UUID generation | `uuid` |

---

## Platform Targets

### Windows (MSI Laptop)
- Window size: adaptive, min 1024×768
- Navigation: Side rail (NavigationRail) on left
- Multi-column layouts where screen width allows
- Development machine — hot reload works natively

### Android (Moto G84 5G)
- Navigation: Bottom NavigationBar
- Single-column scroll layouts
- Uses same GoRouter routes — layout is purely responsive, not a separate codebase
- APK sideloaded (not Play Store for now)

---

## GoRouter — Route Map

```
/                           ← Splash / connection check
├── /dashboard              ← Home dashboard (module status, Governor health)
├── /settings               ← App settings (Pi5 URL, Ollama model, theme)
│
├── /resume                 ← shua_resume module root
│   ├── /resume/editor      ← Resume matrix editor
│   ├── /resume/compile     ← PDF compilation screen (template picker, JD input)
│   └── /resume/history     ← Past compilation history
│
├── /diary                  ← shua_diary module root
│   ├── /diary/list         ← Entry list (date-grouped, mood heatmap)
│   ├── /diary/entry/:id    ← Block editor (native Notion-like)
│   └── /diary/new          ← Create new entry
│
├── /code                   ← shua_code_visualizer module root
│   ├── /code/topology      ← AST topology viewer
│   └── /code/watch         ← Watcher daemon control
│
├── /governor               ← shua_governor control panel
│   ├── /governor/status    ← Module process states, RAM, uptime
│   ├── /governor/ollama    ← Model load/evict controls
│   └── /governor/logs      ← Live log stream
│
└── /gym                    ← shua_gym (Phase 4 stub — locked behind feature flag)
    └── /crypto             ← shua_crypto (Phase 4 stub — locked behind feature flag)
```

---

## Screen Inventory

### Phase 1 Screens (Must Build)

| Screen | Route | Priority | Description |
| :--- | :--- | :--- | :--- |
| `SplashScreen` | `/` | P0 | Connection check, Pi5 reachability test, route to dashboard |
| `DashboardScreen` | `/dashboard` | P0 | Module status grid, Ollama model badge, Governor health |
| `SettingsScreen` | `/settings` | P0 | Pi5 host URL, LAN/Tailscale toggle, theme picker, font scale |
| `GovernorStatusScreen` | `/governor/status` | P0 | Live process table from `governor.status` |
| `GovernorOllamaScreen` | `/governor/ollama` | P1 | Model picker, load/evict buttons, RAM gauge |
| `GovernorLogsScreen` | `/governor/logs` | P1 | Streaming log feed from Governor EVENT |

### Phase 3 Screens (Stubs in Phase 1, Implemented in Phase 3)

| Screen | Route | Module |
| :--- | :--- | :--- |
| `ResumeEditorScreen` | `/resume/editor` | shua_resume |
| `ResumeCompileScreen` | `/resume/compile` | shua_resume |
| `ResumeHistoryScreen` | `/resume/history` | shua_resume |
| `DiaryListScreen` | `/diary/list` | shua_diary |
| `DiaryEntryScreen` | `/diary/entry/:id` | shua_diary |
| `DiaryNewScreen` | `/diary/new` | shua_diary |

### Phase 2 Screens (Stubs in Phase 1, Implemented in Phase 2)

| Screen | Route | Module |
| :--- | :--- | :--- |
| `CodeTopologyScreen` | `/code/topology` | shua_code_visualizer |
| `CodeWatchScreen` | `/code/watch` | shua_code_visualizer |

---

## Riverpod Provider Registry

### HBP / Connection Layer

| Provider | Type | Scope | Description |
| :--- | :--- | :--- | :--- |
| `hbpClientProvider` | `AsyncNotifier<HbpClient>` | Global | WebSocket connection to Governor. Manages connect/reconnect. |
| `connectionStateProvider` | `StateProvider<ConnectionState>` | Global | `connected \| connecting \| disconnected \| error` |

### Governor Providers

| Provider | Type | Scope | Description |
| :--- | :--- | :--- | :--- |
| `governorStatusProvider` | `AsyncNotifier<GovernorStatus>` | Global | Polls `governor.status` on connect + every 30s |
| `ollamaStateProvider` | `StateNotifier<OllamaState>` | Global | Currently loaded model, RAM usage |
| `governorLogsProvider` | `StreamNotifier<List<LogEntry>>` | Governor screen | Live log stream from Governor EVENT push |

### App Config Providers

| Provider | Type | Scope | Description |
| :--- | :--- | :--- | :--- |
| `appConfigProvider` | `AsyncNotifier<AppConfig>` | Global | Pi5 URL, network mode (LAN/Tailscale), loaded from `shared_preferences` |
| `themeProvider` | `Notifier<AppTheme>` | Global | Active theme (seed color, brightness, font scale) |

---

## Folder Structure

```
client_flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                        ← MaterialApp.router + GoRouter setup
│   │
│   ├── core/
│   │   ├── hbp/
│   │   │   ├── hbp_client.dart         ← WebSocket connect/reconnect/heartbeat
│   │   │   ├── hbp_frame.dart          ← Frame encode/decode (MessagePack)
│   │   │   ├── hbp_dispatcher.dart     ← Route incoming frames to providers
│   │   │   └── hbp_request.dart        ← Typed request builder
│   │   ├── config/
│   │   │   ├── app_config.dart         ← AppConfig model
│   │   │   └── app_config_provider.dart
│   │   └── theme/
│   │       ├── app_theme.dart          ← ThemeData builder
│   │       └── theme_provider.dart
│   │
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── dashboard_provider.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   ├── governor/
│   │   │   ├── governor_status_screen.dart
│   │   │   ├── governor_ollama_screen.dart
│   │   │   ├── governor_logs_screen.dart
│   │   │   └── governor_provider.dart
│   │   ├── resume/                     ← Phase 3 (stub in Phase 1)
│   │   ├── diary/                      ← Phase 3 (stub in Phase 1)
│   │   └── code_visualizer/            ← Phase 2 (stub in Phase 1)
│   │
│   ├── shared/
│   │   ├── widgets/                    ← Reusable UI components
│   │   │   ├── module_status_card.dart
│   │   │   ├── connection_banner.dart
│   │   │   └── loading_shimmer.dart
│   │   └── models/                     ← Shared data models
│   │       ├── governor_status.dart
│   │       ├── ollama_state.dart
│   │       └── connection_state.dart
│   │
│   └── router/
│       └── app_router.dart             ← GoRouter definition
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Connection Lifecycle (Splash → Dashboard)

```
App Launch
    │
    ▼
SplashScreen
    │
    ├──► Load AppConfig from shared_preferences
    │         (Pi5 URL, network mode)
    │
    ├──► Attempt WebSocket connect to Pi5
    │         hbpClientProvider.build()
    │
    ├── [Success] ──► governor.status request
    │                      │
    │                 [Success] ──► GoRouter.push('/dashboard')
    │                 [Failure] ──► Dashboard with degraded state banner
    │
    └── [Timeout 5s] ──► Show "Cannot reach Pi5" screen
                              │
                         [Retry button] or [Settings]
```

---

## Theme System

The theme follows the Material 3 HCT (Hue-Chroma-Tone) color system. Seed colors generate the full `ColorScheme` dynamically.

| Theme Preset | Seed Color | Brightness | Personality |
| :--- | :--- | :--- | :--- |
| `midnightGlass` (default) | HSL(220, 40%, 20%) | Dark | Primary UI — deep navy |
| `warmPaper` | HSL(38, 60%, 50%) | Light | Diary canvas feel |
| `cyberNeon` | HSL(160, 100%, 40%) | Dark | High contrast cyberpunk |
| `emeraldForest` | HSL(145, 50%, 35%) | Dark | Rich green depth |

Typography:
- **UI / Headlines**: Outfit
- **Body / Reading**: Lora (diary canvas only)
- **Code / Monospace**: JetBrains Mono

---

## Phase 1 Acceptance Criteria

- [ ] App launches on Windows without crash
- [ ] App launches on Android (Moto G84) without crash
- [ ] `SplashScreen` connects to Pi5 at `100.67.11.0:7700` via Tailscale
- [ ] `DashboardScreen` displays Governor module status from `governor.status`
- [ ] `SettingsScreen` persists Pi5 URL to `shared_preferences`
- [ ] Navigation between all Phase 1 screens works on both platforms
- [ ] Connection drop → reconnect → state restores without app restart
- [ ] GoRouter deep links work on both platforms

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire protocol
- `_architecture/specs/shua_governor/shua_governor_spec.md` — Governor API
- `_architecture/decisions/ADR-001_native_over_sdui.md` — Why no SDUI
- `_architecture/reference/client_flutter.md` — 2.0 Flutter topology (historical)

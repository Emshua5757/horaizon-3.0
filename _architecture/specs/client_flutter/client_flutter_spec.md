# client_flutter — Specification

| Field | Value |
| :--- | :--- |
| **Language** | Dart |
| **Framework** | Flutter |
| **Phase** | Phase 1 Baseline (Supports Phase 2–5 feature modules) |
| **Targets** | Windows (MSI Laptop, 1024×768+) + Android (Moto G84 5G, 6.5" 120Hz) |
| **State** | Riverpod (`AsyncNotifier`, `Notifier`, `StreamNotifier`) |
| **Navigation** | GoRouter (typed routes) + `RouteObserver` history tracking |
| **Transport** | HBP v2 client (WebSocket + MessagePack) |
| **UI** | Native Flutter widgets — NO SDUI renderer (ADR-001) |

---

## Design Principles

1. **No SDUI**. There is no blueprint loader, no screen assembler, no `SduiBlockRegistry`. Screens are 100% native `.dart` widgets (ADR-001).
2. **Typed state everywhere**. Every provider has a typed model class. No `dynamic`, no `Map<String, dynamic>` at the state layer.
3. **HBP v2 is the main transport**. All microservice data flows through `HbpClient` WebSocket (`ws://host:7700/hbp`).
4. **Platform-adaptive glassmorphic shell scaffold**. Breakpoint-driven:
   - **Compact (< 640px)**: Bottom `NavigationBar`.
   - **Desktop Minimized / Medium (640–900px or toggled)**: 80px icons-only rail with cyan active indicators.
   - **Desktop Expanded (≥ 900px)**: 260px obsidian glass sidebar matching Google Stitch designs.
5. **Persistent Telemetry Top Header**. All screens display live hardware & AI status meters (`CPU %`, `RAM 7.1G ceiling`, `SoC Temp °C`, `Tailscale Ping ms`, `Active AI Model`) and history navigation (`<` Back / `>` Forward).
6. **Offline-safe shell**. The app launches cleanly when Pi 5 is unreachable, displaying an interactive `ConnectionStatusBanner` instead of crashing.
7. **Biometric App Lock**. Optional device-level unlock (`local_auth`) securing private diary and resume data.
8. **mDNS Auto-Discovery**. Auto-discovers `horaizon.local` on LAN via `multicast_dns` when host IP is unconfigured.

---

## Technology Stack

| Concern | Package | Usage |
| :--- | :--- | :--- |
| State management | `riverpod` + `flutter_riverpod` | App state & async network providers |
| Navigation | `go_router` | Typed route map & navigation shell |
| MessagePack | `messagepack` | HBP v2 frame payload encoding |
| WebSocket | `web_socket_channel` | Persistent HBP v2 connection |
| Theme System | Custom `ThemeCompiler` + `dynamic_color` | HCT color seeds, 4 surface modes, Material You |
| Biometric Security | `local_auth` | Face ID / Touch ID / Fingerprint app lock |
| LAN Auto-Discovery | `multicast_dns` | mDNS broadcast search for `horaizon.local` |
| Fonts | `google_fonts` | Outfit (UI), Lora (Diary), JetBrains Mono (Code) |
| Persistent config | `shared_preferences` | User preferences & saved connection settings |
| Icons | `flutter_svg` + `flutter_launcher_icons` | Vector graphics & custom app icons |

---

## Platform Targets & Breakpoints (`lib/shared/breakpoints.dart`)

```dart
class Breakpoints {
  static const double compact = 640.0;   // Mobile phone boundary
  static const double expanded = 900.0;   // Desktop sidebar expanded boundary
}
```

- **Compact (< 640px)**: Bottom `NavigationBar`, single-column vertical card list.
- **Desktop Minimized (640–900px)**: 80px icons-only rail (`Desktop | Dashboard - Minimized Sidebar`).
- **Desktop Expanded (≥ 900px)**: 260px full obsidian glass sidebar (`Desktop | Dashboard - Telemetry Sidebar`).

---

## GoRouter — Canonical Route Map

```
/                           ← Splash / mDNS auto-discovery / connection check
├── /dashboard              ← Home dashboard (RPi5 Hardware Telemetry, AI Aggregator, Microservices Grid)
├── /chat                   ← Global AI Chat (RPi5 Ollama + MCP server tools)
├── /terminal               ← Multi-Tab Embedded Console & Telemetry Log Feed
├── /settings               ← App settings (Appearance, HBP v2 Connection, Security, AI RAM limits)
│
├── /code                   ← Phase 2: shua_code_visualizer
│   ├── /code/topology      ← AST topology graph
│   └── /code/watch         ← File watcher control
│
├── /diary                  ← Phase 3: shua_diary
│   ├── /diary/list         ← Entry list (date-grouped, mood heatmap)
│   ├── /diary/entry/:id    ← Block editor (36 native widgets)
│   └── /diary/new          ← Create new entry
│
├── /resume                 ← Phase 4: shua_resume
│   ├── /resume/editor      ← Resume matrix editor
│   ├── /resume/compile     ← Typst PDF compilation screen
│   └── /resume/history     ← Compilation history
│
├── /gym                    ← Phase 5: shua_gym (Health & workout tracking)
└── /crypto                 ← Phase 5: shua_crypto (Local secrets & key vault)
```

---

## Screen Inventory (Aligned to Master Roadmap)

### Phase 1 Core Shell Screens
| Screen | Route | Description |
| :--- | :--- | :--- |
| `SplashScreen` | `/` | mDNS LAN discovery, Pi 5 connectivity check, biometric auth guard |
| `DashboardScreen` | `/dashboard` | Hardware Telemetry Hero Card, AI Aggregator Hero Card, microservice cgroups v2 power switches |
| `GlobalChatScreen` | `/chat` | Native AI Chat interface connected to Shua Governor and MCP server tool loop |
| `TerminalScreen` | `/terminal` | Multi-tab embedded terminal console & real-time reverse-telemetry log stream |
| `SettingsScreen` | `/settings` | Wide single pane top tab bar (Appearance, HBP v2 Connection, Security, AI Limits) |

### Phase 2 Screens (`shua_code_visualizer`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `CodeTopologyScreen` | `/code/topology` | Interactive AST dependency hypergraph canvas |
| `CodeWatchScreen` | `/code/watch` | File watcher daemon status & controls |

### Phase 3 Screens (`shua_diary`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `DiaryListScreen` | `/diary/list` | Date-grouped entry list, mood filter & heatmap row |
| `DiaryEntryScreen` | `/diary/entry/:id` | Native block widget editor with LexoRank reordering |
| `DiaryNewScreen` | `/diary/new` | Create entry dialog & template picker |

### Phase 4 Screens (`shua_resume`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `ResumeEditorScreen` | `/resume/editor` | Resume matrix editor (experience, skills, portfolio) |
| `ResumeCompileScreen` | `/resume/compile` | Typst PDF compilation screen with AI tailoring |
| `ResumeHistoryScreen` | `/resume/history` | Past PDF compilation list & download links |

### Phase 5 Screens (`shua_gym` & `shua_crypto`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `GymScreen` | `/gym` | Workout tracking & physical metrics |
| `CryptoVaultScreen` | `/crypto` | Local secrets & encryption key vault |

---

## Connection Lifecycle (Splash → mDNS → Dashboard)

```
App Launch
    │
    ▼
SplashScreen
    │
    ├──► Check Biometric Auth (if enabled in settings) ──► Fail ──► Lock Screen
    │                                                     Pass
    │                                                       │
    ├──► Load AppConfig from shared_preferences             │
    │         (Pi 5 URL, network mode)                      │
    │                                                       │
    ├──► Is Pi 5 Host IP set? ──────────────────────────────┘
    │         ├── NO  ──► Broadcast mDNS search for horaizon.local (multicast_dns)
    │         │                ├── Found ──► Save IP & Connect
    │         │                └── Not Found ──► Show Settings Screen
    │         └── YES
    │              │
    │              ▼
    ├──► Attempt HBP v2 WebSocket connect to Pi 5 (ws://host:7700/hbp)
    │         hbpClientProvider.build()
    │
    ├── [Success] ──► governor.status request ──► GoRouter.go('/dashboard')
    │
    └── [Timeout 5s] ──► Render degraded UI with ConnectionStatusBanner
```

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire protocol
- `_architecture/contracts/mcp/mcp_master_spec.md` — Master MCP specification
- `_architecture/decisions/ADR-001_native_over_sdui.md` — Native over SDUI decision
- `_architecture/screens/ui_screens_spec.md` — Master UI Screen & Stitch Specifications

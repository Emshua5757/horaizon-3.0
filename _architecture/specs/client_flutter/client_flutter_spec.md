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
| **UI** | Native Flutter widgets — NO SDUI renderer |

---

## Design Principles

1. **No SDUI**. There is no blueprint loader, no screen assembler, no `SduiBlockRegistry`. Screens are native `.dart` widgets.
2. **Typed state everywhere**. Every provider has a typed model class. No `dynamic`, no `Map<String, dynamic>` at the state layer.
3. **HBP v2 is the main transport**. All microservice data flows through `HbpClient` WebSocket (`ws://host:7700/hbp`).
4. **Platform-adaptive layout**. Breakpoint-driven: Compact (< 640px) uses `NavigationBar`, Medium (640–1024px) uses `NavigationRail`, Expanded (> 1024px) uses multi-column canvas.
5. **Offline-safe shell**. The app launches cleanly when Pi 5 is unreachable, displaying an interactive `ConnectionStatusBanner` instead of crashing.
6. **Biometric App Lock**. Optional device-level unlock (`local_auth`) securing private diary and resume data.
7. **mDNS Auto-Discovery**. Auto-discovers `horaizon.local` on LAN via `multicast_dns` when host IP is unconfigured.

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
  static const double expanded = 1024.0; // Large tablet / desktop boundary
}
```

- **Compact (< 640px)**: Bottom `NavigationBar`, single-column vertical list layout.
- **Medium (640–1024px)**: Left `NavigationRail`, single or double card column.
- **Expanded (> 1024px)**: Left `NavigationRail`, multi-column master-detail canvas with side inspector.

---

## GoRouter — Canonical Route Map

```
/                           ← Splash / mDNS auto-discovery / connection check
├── /dashboard              ← Home dashboard (native module grid, Ollama badge)
├── /settings               ← App settings (mDNS scan, visual customizer, theme, host IP)
├── /dev/blocks             ← Developer 36-block gallery preview
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
├── /governor               ← Phase 1: shua_governor control panel
│   ├── /governor/status    ← Process states, RAM/CPU metrics
│   ├── /governor/ollama    ← Model loader & RAM gauge
│   └── /governor/logs      ← Live reverse-telemetry log stream
│
├── /gym                    ← Phase 5: shua_gym (Health & workout tracking)
└── /crypto                 ← Phase 5: shua_crypto (Local secrets & key vault)
```

---

## Screen Inventory (Aligned to Master Roadmap)

### Phase 1 Screens
| Screen | Route | Description |
| :--- | :--- | :--- |
| `SplashScreen` | `/` | mDNS LAN discovery, Pi 5 connectivity check, biometric auth guard |
| `DashboardScreen` | `/dashboard` | Native module card grid, Ollama model status header card |
| `SettingsScreen` | `/settings` | Visual customizer, host IP/port, mDNS scan button, font scale |
| `GovernorStatusScreen` | `/governor/status` | Real-time cgroups v2 process table, wake/sleep buttons |
| `GovernorOllamaScreen` | `/governor/ollama` | Ollama model load/evict controls, RAM gauge |
| `GovernorLogsScreen` | `/governor/logs` | Real-time reverse-telemetry log feed from Governor EVENT |

### Phase 2 Screens (`shua_code_visualizer`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `CodeTopologyScreen` | `/code/topology` | Interactive AST dependency hypergraph canvas |
| `CodeWatchScreen` | `/code/watch` | File watcher daemon status & controls |

### Phase 3 Screens (`shua_diary`)
| Screen | Route | Description |
| :--- | :--- | :--- |
| `DiaryListScreen` | `/diary/list` | Date-grouped entry list, mood filter & heatmap row |
| `DiaryEntryScreen` | `/diary/entry/:id` | 37 native block widget editor with LexoRank reordering |
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

## Shared Provider & UI Conventions

### Standardized `AsyncValueView` (`lib/shared/widgets/async_value_view.dart`)
All screens use `AsyncValueView<T>` to handle Riverpod `AsyncValue` loading and error states consistently:

```dart
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Card(
        color: Colors.redContainer,
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text('Error loading data: $err'),
          trailing: onRetry != null
              ? IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry)
              : null,
        ),
      ),
    );
  }
}
```

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

## Reconnect Testing Strategy

To verify the acceptance criterion *"Connection drop → reconnect → state restores without app restart"*:

1. **Automated Unit & Widget Tests**:
   - `test/core/hbp/hbp_client_test.dart` uses a `MockWebSocketChannel` stream controller.
   - Emits an abrupt socket close event (`onDone`), asserts `HbpConnectionState.reconnecting`, verifies exponential backoff timers (1s, 2s, 4s... 30s), and verifies automatic state re-subscription upon reconnect.
2. **Manual Hardware Verification**:
   - Run `client_flutter` on Windows or Android.
   - Stop `shua_governor` daemon on Pi 5 (`sudo systemctl stop shua-governor`).
   - Observe `ConnectionStatusBanner` displaying red offline state.
   - Restart `shua_governor` daemon (`sudo systemctl start shua-governor`).
   - Confirm `ConnectionStatusBanner` transitions to green pulse and UI state auto-refreshes without restarting app.

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire protocol
- `_architecture/contracts/mcp/mcp_master_spec.md` — Master MCP specification
- `_architecture/decisions/ADR-001_native_over_sdui.md` — Native over SDUI decision
- `_architecture/tasks/master_task_roadmap.md` — Master task roadmap

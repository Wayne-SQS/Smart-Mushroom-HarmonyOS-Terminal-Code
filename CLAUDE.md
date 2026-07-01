# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SoftwareAction is a **蘑菇大棚 IoT 管理系统** (Mushroom Greenhouse IoT Management System) built with **ArkTS + ArkUI** using the **Stage Model**. It connects to Huawei Cloud IoTDA for real device data (sensor shadow queries, command delivery). Target API is 6.1.1(24), bundle `com.example.softwareaction`, targeting six device types: phone, tablet, 2in1, car, wearable, tv.

**Key reference document:** `docs/harmony-kb.md` — HarmonyOS development knowledge base covering kit APIs, Huawei Cloud IoT integration, and project conventions.

**⚠️ CREDENTIALS:** `entry/src/main/ets/entryability/IotConfig.ets` contains real Huawei Cloud IoTDA credentials (`IOT_CONFIG`). This file is excluded via `.gitignore` (`**/IotConfig.ets`) but currently exists in the working tree. Never commit this file. The template at `IotConfig.example.ets` (NOT gitignored) is the safe file to commit — new developers copy it to `IotConfig.ets` and fill in their credentials.

### `docs/` 目录规则

`docs/` 下的文件是**设计文档和知识库，不是可执行代码**：

- **只读优先**：除非用户明确要求修改，否则不要改动 `docs/` 下的任何文件
- **不构建验证**：文档中的代码片段是示意性的，不要尝试编译或运行。不要对 `docs/` 触发 `hvigorw` 构建
- **内容权威性**：`docs/harmony-kb.md` 是 HarmonyOS 开发的知识来源，文档中的 API 用法优先于模型训练数据中的记忆

### Startup Sequence

```
EntryAbility.onCreate()
  ├── context.setColorMode(NOT_SET)     // follow system
  ├── IotService.getInstance().init(IOT_CONFIG)  // singleton, loads IAM creds
  └── hilog init log

EntryAbility.onWindowStageCreate()
  └── windowStage.loadContent('pages/Index')

Index.aboutToAppear()
  ├── AppStorage.setOrCreate('navPathStack', AppRouter.getStack())
  └── AppStorage.setOrCreate('currentBreakpoint', BreakpointConstants.SM)

Index.build()
  ├── onAreaChange → recompute breakpoint → write AppStorage
  ├── Narrow (XS/SM): Tabs(barPosition=End) with TabContent inline
  └── Wide (MD/LG/XL): SideNavBar + Navigation(mode=Auto) with NavDestination builder
```

### IotConfig Security Pattern

The `.gitignore` uses a negated pattern to protect credentials:
```
**/IotConfig.ets          # ignored — real credentials, never commit
!**/IotConfig.example.ets # NOT ignored — template, safe to commit
```

`IotConfig.ets` imports `IotAppConfig` from `features-core` and exports `IOT_CONFIG`. `EntryAbility.ets` imports it as `import { IOT_CONFIG } from './IotConfig'`. Always verify `IotConfig.ets` is not staged before committing.

## Build System & Commands

This project uses **Hvigor** (HarmonyOS build system) with **DevEco Studio** as the IDE.

### Build
```bash
# Assemble debug HAP
hvigorw assembleHap -p buildMode=debug

# Assemble release HAP
hvigorw assembleHap -p buildMode=release

# Clean + rebuild (use when incremental build acts up)
hvigorw clean && hvigorw assembleHap -p buildMode=debug
```

If incremental build fails unexpectedly, also try deleting `.hvigor/` and `entry/build/` before rebuilding.

### Testing
Testing uses `@ohos/hypium` (v1.0.25) with `@ohos/hamock` (v1.0.0).

```bash
# Run all unit tests (entry/src/test/)
hvigorw test

# Run UI/integration tests (entry/src/ohosTest/) — requires device/emulator
hvigorw ohosTest
```

**Test file locations:**
- `entry/src/test/List.test.ets` — test suite entry point (imports all test files: `LocalUnit.test.ets`, `IotTypes.test.ets`, `Recipe.test.ets`, `ViewModel.test.ets`)
- `entry/src/ohosTest/ets/test/` — UI/integration tests (run on device/emulator)

**Test API** (import from `@ohos/hypium`):
```typescript
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
```

### Linting
CodeLinter configured in `code-linter.json5`. Lints `**/*.ets` with `@performance/recommended` + `@typescript-eslint/recommended` plus security rules (no unsafe AES, hash, RSA, DH, DSA, ECDSA, 3DES). `no-unsafe-mac` is `warn` — HMAC-SHA256 in `IotAuthUtil` is intentional. Run via DevEco Studio: **Code → Code Linter → Run Linter**. Ignores: `ohosTest/`, `test/`, `mock/`, `oh_modules/`, `build/`, `.preview/`.

## Architecture

### 3-Layer Architecture (IMPLEMENTED)

```
common/base (HAR)  →  features/core (HAR)  →  entry (HAP)
  public cap.           business logic          product entry
```

| Layer | Package | Key directories |
|-------|---------|-----------------|
| Public | `common-base` | `constants/` (Breakpoint, Style, SensorType), `utils/` (Logger, Capability), `components/` (BarChart, LineChart, Gauge, base ChartComponent) |
| Feature | `features-core` | `pages/`, `viewmodel/`, `model/`, `service/` (IoT) |
| Product | `entry` | `entryability/`, `pages/` (Index, AppRouter), `src/test/` |

Imports use package names (e.g., `import { Logger } from 'common-base'`), not relative paths. All modules registered in root `build-profile.json5`.

**Dependency rules (STRICT):**
- `entry → features/core → common/base` ✅
- `common/base → features/core` ❌ (no reverse)
- `features/core → entry` ❌ (no reverse)
- No lateral calls between modules ❌

### Navigation & Routing

The app uses `Navigation` + `NavPathStack` + `NavDestination`:

- `entry/pages/Index.ets` owns the `Navigation` component with a `NavPathStack`
- `AppRouter` is a singleton that holds the shared `NavPathStack`, accessible from any module
- `NavPathStack` is stored in `AppStorage` under key `'navPathStack'` so `features-core` pages can call `AppRouter.push('AlertPage')` etc.
- **`main_pages.json` only registers `pages/Index`** — all other pages (AlertPage, GrowthPage, RecipePage, etc.) are imported from `features-core` module and rendered via builder patterns:
  - **Sub-pages** (AlertPage, GrowthPage, RecipePage): rendered via `@Builder PageDestination(name)` in Index.ets, reached via `AppRouter.push('AlertPage')` etc.
  - **Tab pages** (DashboardPage, DevicePage, MapPage, ProfilePage): rendered inline in `TabContent` (narrow) or `Column` (wide)
- Main tabs: 首页 (Dashboard), 设备 (Device), 地图 (Map), 我的 (Profile)
- SettingsPage is mentioned in routing plans but **does not exist yet** (see `docs/后续开发计划.md`)

### Index Responsive Layout (Dual-Mode)

The `Index.ets` entry page implements a breakpoint-driven dual-mode architecture:

| Mode | Breakpoints | Layout |
|------|-------------|--------|
| **Narrow** | XS, SM | `Tabs(barPosition=End)` — bottom tab bar, full TabContent pages |
| **Wide** | MD, LG, XL | `SideNavBar` (96vp left rail) + `Navigation(mode=Auto)` — Navigation auto-chooses Stack or Split |

The wide mode uses `Navigation` for the content area, supporting `NavPathStack` push/pop for sub-pages. The narrow mode Tabs do NOT use Navigation — sub-page pushes from within tab pages still work because `AppRouter` shares the same `NavPathStack` across both modes.

### IoT Service Layer (`features/core/src/main/ets/service/`)

| File | Purpose |
|------|---------|
| `IotService.ets` | Singleton — IAM auth, device shadow query, property report, command send (Light control etc.) |
| `IamAuthUtil.ets` | Huawei Cloud IAM token request (username/password → X-Subject-Token) |
| `IotAuthUtil.ets` | Legacy HMAC-SHA256 password generation (kept for reference, new code uses IAM) |
| `IotTokenManager.ets` | Token cache with configurable TTL (default 23h for 24h IAM tokens) |
| `IotTypes.ets` | All IoT API TypeScript interfaces |
| `IotExample.ets` | Usage examples (not wired to UI) |

**Available control methods** (all on `IotService` singleton, send async commands via `sendCommand()`):
- `controlLight(on: boolean)` → `SetLamp`
- `controlFan(on: boolean)` → `SetVent`
- `controlCondi(on: boolean)` → `SetCond`
- `controlBuzzer(on: boolean)` → `SetBuzzer`

**plantAI service** (`SERVICE_PLANT_AI = 'plantAI'`) — ESP32-CAM AI recognition. `recognizeOnce` command with empty paras triggers one-shot plant disease/growth analysis. Result returned via property report. Code has the service constant and paras class defined; UI integration pending.

**Auth flow:** `IotService.init(config) → authenticate() → IamAuthUtil.requestToken() → X-Subject-Token cached in IotTokenManager → queryDeviceShadow/sendCommand`

**IAM endpoint** is dynamically constructed from `config.region`: `iam.{region}.myhuaweicloud.com`. Previously hardcoded to `cn-north-4`.

**Command delivery:** MQTT devices use synchronous `/commands` only. `/async-commands` returns `IOTDA.014114` for MQTT devices. Commands may timeout (`IOTDA.014111`) if the ESP32 is slow to respond — this is a device-side issue.

### ViewModel Pattern

ViewModels follow a consistent pattern (see `features/core/src/main/ets/viewmodel/`):

- `BaseViewModel` — abstract base class providing `isLoading`, `errorMsg`, `lastUpdateTime` state, `handleAsync<T>()` wrapper for unified try-catch/loading/error management, and `loadData()` abstract method
- Concrete ViewModels (`DashboardViewModel`, `DeviceViewModel`, `GrowthViewModel`, `AlertViewModel`) extend `BaseViewModel`
- ViewModels are pure TS classes (no ArkTS decorators) — Pages import and instantiate them, binding data to `@State` in the Page
- IoT failure → ViewModel falls back to mock data (sensors, controls, alerts all have sensible defaults)
- Status calculation for sensors: value in [min, max] → 0 (normal); 10% overflow → 0 (tolerance); 10-20% → 1 (warning); ≥20% → 2 (danger)

## Key Patterns

### State Management

| Scope | Decorator |
|-------|-----------|
| Local only | `@State` |
| Parent-child ≤2 levels | `@State` + `@Prop` (one-way) / `@Link` (two-way) |
| Parent-child >2 levels | `@Provide` + `@Consume` |
| Nested object properties | `@Observed` + `@ObjectLink` |
| Cross-page / global | `LocalStorage` / `AppStorage` / `StateStore` |
| **New code (prefer V2)** | `@ObservedV2` + `@Trace` + `@ComponentV2` + `@Local` + `@Param` + `@Event` |

### Coding Rules
- **No `any`** — all variables must have explicit type declarations; no `as` type assertions
- **No object literals without a declared interface/class**
- **No dynamic property access** (`obj[dynamicKey]`) — ArkTS restriction; use explicit `switch`/`if-else` branches
- **Split large state objects** into individual `@State` variables grouped by refresh frequency and associated UI
- **Cache state variables in local variables** before loops — never read `@State` directly inside a loop
- **`build()` must be lightweight** — no network requests, heavy computation, or sync I/O. Use `aboutToAppear` for async init.
- **Use `LazyForEach` + `cachedCount` + `@Reusable`** for lists > 100 items; `ForEach` for ≤100
- **Animate only composite properties** (`translate`, `scale`, `opacity`, `rotate`) — never animate layout properties (`width`, `height`, `margin`, `padding`)
- **Use `@Builder` for simple UI fragments** (no CustomNode overhead); `@Component` only when lifecycle/state management is needed
- **Layout depth ≤ 5 levels**; merge same-direction redundant nesting (e.g., `Row` inside `Row`)
- **Use `visibility()` for frequent show/hide toggles**; `if/else` for conditional rendering/lazy loading
- **All device capability API calls must be guarded with `canIUse()`**
- **All async operations must have `try-catch`**
- **Use optional chaining (`?.`) and nullish coalescing (`??`)** for null safety
- **Dimension units**: `vp` for layout/sizing, `fp` for fonts, `'100%'` string for percentage, `layoutWeight()` for flex allocation

### Responsive Breakpoints
- XS (0–320vp) → watch
- SM (320–600vp) → phone portrait
- MD (600–840vp) → foldable / small tablet
- LG (840–1440vp) → tablet landscape
- XL (1440+vp) → large screen / PC

Breakpoint values are defined in `BreakpointConstants` (common/base). `AdaptiveUtils` provides helper methods for column count, padding, gap, dual-pane detection per breakpoint. Breakpoints are stored in `AppStorage` under `'currentBreakpoint'` and shared globally via `@StorageLink`. Use `GridRow`/`GridCol` with breakpoint-responsive `span` — do NOT branch on `deviceInfo.deviceType`.

### Layout Rules

- **Layout selection priority** (same level performance): `Column/Row` > `Stack` > `RelativeContainer` > `Flex` > `Grid`
- **Scroll + List rule:** When nesting `List` inside `Scroll`, the `List` must have explicit width and height.

## Key System Kit Imports

- `@kit.AbilityKit` — `UIAbility`, `Want`, `AbilityConstant`, `ConfigurationConstant`
- `@kit.ArkUI` — UI components, `window`
- `@kit.NetworkKit` — `http` module (IoT HTTP requests — must call `destroy()` on each `createHttp()` instance)
- `@kit.CryptoArchitectureKit` — `cryptoFramework` (HMAC-SHA256 in `IotAuthUtil`)
- `@kit.BasicServicesKit` — `BusinessError`
- `@kit.PerformanceAnalysisKit` — `hilog`
- `@kit.CoreFileKit` — `BackupExtensionAbility`
- `@ohos/hypium` — test framework
- `@ohos/hamock` — mocking for tests
- `@ohos.data.preferences` — local persistence (login state, config cache)
- `@ohos.promptAction` — Toast messages (prefer over deprecated `prompt`)
- `@ohos.net.connection` — network state detection
- `@ohos.net.socket` — TCP socket (ESP32-CAM video streaming, `constructTCPSocketInstance()`)
- `@ohos.multimedia.image` — `createImageSource()` + `createPixelMap()` for JPEG frame decoding

## Git Conventions (from project docs)
```
main              — release (protected)
develop           — daily development
feature/xxx       — feature branches
bugfix/xxx        — fix branches

Commit: <type>(<scope>): <subject>
type: feat / fix / refactor / style / docs / test / chore
scope: common / feature / product / ui / api
```

## Never Commit
- `local.properties`
- `.hvigor/`
- `entry/build/`
- `entry/.preview/`
- `oh_modules/`
- `**/IotConfig.ets` — real credentials (see IotConfig Security Pattern above). Template `IotConfig.example.ets` IS safe to commit.

## File Naming
| Type | Pattern |
|------|---------|
| Pages | `XxxPage.ets` |
| Components | `XxxComponent.ets` |
| Utils | `XxxUtils.ets` |
| Models | `XxxModel.ets` |
| ViewModels | `XxxViewModel.ets` |
| Services | `XxxService.ets` |
| Constants | `XxxConstants.ets` |

## IoT-Specific Conventions

### Huawei Cloud IoTDA Property Names (Case-Sensitive)

Properties are defined in the IoTDA console 物模型 (Thing Model). The smartRoom service includes:

| Property | Meaning | Maps to | HW? | Example |
|----------|---------|----------|-----|---------|
| `Temp` | Temperature °C | `TEMPERATURE` | ✅ DHT11 | `"27.7"` |
| `Humi` | Humidity % | `HUMIDITY` | ✅ DHT11 | `"51.3"` |
| `Lumi` | Light (LDR) | `LIGHT` | ✅ LDR | `"63"` |
| `CO2` | CO₂ ppm | `CO2` | ✅ | `"800"` |
| `Smoke` | Smoke/gas | *(pending)* | ✅ MQ2 | `"120"` |
| `Dist` | Distance cm | `SOIL_MOISTURE` | ❌ 预留 | `"-1"` |
| `LampST` | Lamp state | controls (light) | ✅ LED | `"ON"` |
| `CondST` | AC state | controls (condi) | ✅ | `"ON"` |
| `VentST` | Fan state | controls (fan) | ✅ | `"ON"` |
| `BuzzerST` | Buzzer state | controls (buzzer) | ✅ ESP32 | `"ON"` |

> **HW?** column: ✅ = hardware reports (see `mqtt.c` JSON_Tree_Format). ❌ = cloud-defined but hardware doesn't report yet — app gracefully falls back to mock data.

SOIL_TEMP and PH have no cloud property defined — remain mock-only.

**Commands (match mqtt.c handle_cloud_command):**

| Control | Command Name | Paras Key | Values |
|---------|-------------|-----------|--------|
| Light (补光) | `SetLamp` | `LampStatus` | `"ON"` / `"OFF"` |
| Fan (通风) | `SetVent` | `VentStatus` | `"ON"` / `"OFF"` |
| AC (空调) | `SetCond` | `CondStatus` | `"ON"` / `"OFF"` |
| Buzzer (蜂鸣器) | `SetBuzzer` | `BuzzerStatus` | `"ON"` / `"OFF"` |

**plantAI 服务（新增，ESP32-CAM AI 识别）：**

| Command | Paras | Purpose |
|---------|-------|---------|
| `recognizeOnce` | `{}` | 触发一次植物 AI 识别（病害/长势），结果通过属性上报返回 |

`plantAI` 是独立于 `smartRoom` 的第二个 IoTDA 服务，对应 ESP32-CAM 的 AI 推理能力。截至当前，代码中尚未对接此服务的响应，仅硬件侧上报。

**Hardware response format:** `{"result_code": 0, "response_name": "<CommandName>", "paras": {"Result": "success"|"fail"}}`

If data reads as `undefined`, first check the embedded `mqtt.c` and the IoTDA console for exact property names.

### IoT Data Flow
```
IoTDA Cloud → IotService.queryDeviceShadow() → getDeviceProperties('smartRoom')
  → DashboardViewModel.applyProperties() → sensors array with calculated status
  → Page UI binding
```

### Chart Component System (`common/base/src/main/ets/components/`)

The common-base layer provides a reusable chart component hierarchy:

| Component | Purpose |
|-----------|---------|
| `ChartComponent` | Base class — exports `ChartPoint`, `ChartSeries`, `GaugeConfig` interfaces + `ChartUtils` |
| `BarChartComponent` | Bar/column charts (24h trends). Props include `labelFontSize`/`axisFontSize` (default 10). DashboardPage uses 160px compact card + **tap to expand** overlay (320px chart, 14px/12px fonts). |
| `LineChartComponent` | Line charts (used for 7-day trends) |
| `GaugeComponent` | Circular gauge (used for sensor value-at-a-glance) |
| `MapViewComponent` | Dual-mode map: real MapKit (`@kit.MapKit`) + Canvas fallback, cluster support, 3D pushpin markers |

All chart components take data via typed interfaces (no `any`), support theme-aware colors, and are Canvas-based for performance.

**MapViewComponent props** (in `common/base`): `markers: MapMarker[]`, `centerLat`/`centerLng`, `mapHeight`, `colors: MapViewColors`, `isSatellite`, `enableCluster`, `enableMyLocation`, `onMarkerClick`. Auto-detects MapKit availability via `canIUse('SystemCapability.Map.Core')`.

### Map Icons (`MapIcon` in MapPage.ets)

A set of 14 custom geometric icons (pure `Circle`/`Rect`/`Stack`/`Row`/`Column`) replacing all emoji throughout the map UI. Types: `satellite`, `cluster`, `location`, `expand`, `contract`, `search`, `close`, `alert`, `map`, `list`, `thermo`, `humidity`, `pin`. Each ~12×12px inside 30×30px buttons. See `MapButtonWithIcon` and `MapIcon` @Builders in MapPage.ets.

### Build Profile Strict Mode

`build-profile.json5` enables two important strict checks:
```json5
"strictMode": {
  "caseSensitiveCheck": true,     // imports must match file case exactly
  "useNormalizedOHMUrl": true     // enforces standard OHPM URL format
}
```
These catch case-sensitivity bugs early — HarmonyOS is case-sensitive but Windows is not, so without this check, code that builds locally can fail on CI/device.

## Project Documentation (`docs/`)

| File | Content |
|------|---------|
| `harmony-kb.md` | **Primary reference** — HarmonyOS kit APIs, Huawei Cloud IoT integration, coding patterns, official doc links |
| `后续开发计划.md` | Development roadmap — Phase I (UI ✅), Phase II (IoT ✅), Phase III (navigation/charts ✅), Phases IV–VI (Map Kit ✅, theming ✅, multi-device partial, testing pending). **AlertPage, RecipePage, theme system 已超前完成。** 视频监控 (ESP32-CAM) 集成计划见 `.claude/plans/`。 |
| `美化.md` | UI theming plan — the dual-theme system is **now fully implemented**: `ThemeManager` singleton, `ThemeTokens` interface (106 props), `ThemeFrosted` (pastel green, backdropBlur=16, large radii) + `ThemeContrast` (black/white, no blur, minimal radii). All pages access tokens via `this.t()`. |


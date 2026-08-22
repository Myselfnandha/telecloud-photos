# PLAN: TeleCloud Photos — Telegram-Backed Android Photo/Video Cloud App

> **Agent:** `@mobile-developer` · **Type:** MOBILE (Flutter + Android)
> **Reference:** Immich (UX/architecture inspiration), TDLib (Telegram MTProto)
> **Status:** 🟡 PLANNING — No code written yet

---

## 🎯 Goal

Build a Flutter Android app that uses your **personal Telegram account** as a free, unlimited cloud backend for photos and videos — Apple Photos-quality UX: timeline grid, auto-backup, albums, offline thumbnails, smart backup scheduling.

---

## ✅ Success Criteria

- [ ] Login with phone number + OTP via TDLib
- [ ] Auto-backup camera roll to a private Telegram channel
- [ ] Timeline grid renders with date-grouped sections (60fps)
- [ ] Backup network mode configurable: WiFi-only OR WiFi+Mobile data (default: WiFi-only)
- [ ] Albums tracked in SQLite + Telegram channel topics
- [ ] Offline thumbnails via local cache
- [ ] Full-res download on demand from Telegram
- [ ] Settings: folder picker, backup trigger, WiFi/charging
- [ ] App survives kill/restart (WorkManager + TDLib session persistence)

---

## 🏗️ Project Type

**MOBILE — Flutter (Android-first)**
- Primary Agent: `mobile-developer`
- NO `frontend-specialist`, NO `backend-specialist`

---

## 🧰 Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI** | Flutter 3.x | Buttery animations, Apple Photos UX |
| **State** | Riverpod 2.x | Reactive, testable, no boilerplate |
| **Telegram** | TDLib (FFI) | Official MTProto, unlimited file size, session persistence |
| **Local DB** | Drift (SQLite ORM) | Type-safe, reactive queries, mirrors TG message IDs |
| **Background** | WorkManager | Battery-safe, survives app kills |
| **Media** | photo_manager | Efficient camera roll access |
| **Navigation** | GoRouter | Type-safe, deep-link ready |
| **Secure Store** | flutter_secure_storage | TDLib session, API credentials |
| **Foreground Svc** | flutter_foreground_task | Keeps upload alive |

---

## 📁 Project File Structure

```
telecloud_photos/
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml        # Permissions, foreground service, WorkManager
│   │   └── kotlin/com/telecloud/
│   │       └── BackupWorker.kt         # WorkManager worker entry point
│   └── build.gradle                   # minSdk 24, targetSdk 34, TDLib ABI splits
├── lib/
│   ├── main.dart                      # ProviderScope, GoRouter, WorkManager init
│   ├── core/
│   │   ├── constants/app_constants.dart        # API_ID, API_HASH from env
│   │   ├── database/
│   │   │   ├── app_database.dart               # Drift DB definition
│   │   │   ├── tables/media_table.dart         # Photos/videos index
│   │   │   ├── tables/albums_table.dart        # Album → TG topic mapping
│   │   │   └── daos/media_dao.dart             # Stream queries
│   │   ├── telegram/
│   │   │   ├── tdlib_client.dart               # TDLib init + event stream
│   │   │   ├── auth_service.dart               # Phone/OTP/session
│   │   │   ├── upload_service.dart             # Chunked upload
│   │   │   ├── channel_manager.dart            # Private channel + topics
│   │   │   └── metadata_encoder.dart           # JSON in captions
│   │   ├── backup/
│   │   │   ├── backup_manager.dart             # Orchestrates backup
│   │   │   ├── media_scanner.dart              # Reads camera roll
│   │   │   ├── upload_queue.dart               # Queue + retry
│   │   │   └── constraints_checker.dart        # WiFi/charging checks
│   │   └── di/providers.dart                   # All Riverpod providers
│   ├── features/
│   │   ├── auth/screens/{splash,phone_input,otp}_screen.dart
│   │   ├── timeline/screens/timeline_screen.dart
│   │   ├── timeline/widgets/{photo_grid,date_header,media_thumbnail}.dart
│   │   ├── viewer/screens/media_viewer_screen.dart
│   │   ├── albums/screens/{albums_list,album_detail}_screen.dart
│   │   ├── search/screens/search_screen.dart
│   │   └── settings/screens/settings_screen.dart
│   └── shared/
│       ├── widgets/{loading_shimmer,error_retry,app_bottom_nav}.dart
│       └── theme/{app_theme,app_colors}.dart
├── pubspec.yaml
└── .env                               # API_ID, API_HASH (gitignored)
```

---

## ⚠️ KEY TECHNICAL CONSTRAINTS

> These will break your code if ignored. Read before writing any function.

### TDLib Constraints
- TDLib is **C++** — integrated via FFI or `tdlib` pub.dev package
- **Session is file-based** — stored in `getApplicationDocumentsDirectory()`. Delete = logout
- **All calls are async events** — `send()` is fire-and-forget. Poll with `receive(timeout: 1.0)` loop in an Isolate
- **Auth state machine** (must handle ALL states):
  `waitTdlibParameters` → `waitPhoneNumber` → `waitCode` → `waitPassword`(if 2FA) → `ready`
- **File upload** = `inputFileLocal` inside `sendMessage`. TDLib handles chunking internally
- **2GB per file** limit. Files >2GB must be warned/split
- **FLOOD_WAIT** errors: exponential backoff. Store pause state in SharedPreferences
- **`updateMessageSendSucceeded`** event gives final `message_id` and `file_id` — do NOT use pending message object
- **TDLib 1.8.19+** required for `is_forum: true` supergroup support

### Battery & Background Logic Constraints
- **Exact Timers**: WorkManager *cannot* do exact 5-minute delays. We must use a **Native Android `BroadcastReceiver`** (listening to `ACTION_POWER_CONNECTED` and `ACTION_POWER_DISCONNECTED`) combined with a **Foreground Service** (`flutter_foreground_task`).
- **Foreground Service Notification**: Required by Android to keep the app alive during the 5-minute waits ("Waiting 5 mins to backup..." / "Upload paused, waiting for charger..."). This notification will be automatically dismissed by the system the moment the upload finishes or the wait timer expires and the service is killed.
- **App Lifecycle**: When on battery, the app can only upload if it is actively in the **Foreground** (on screen). The moment it transitions to the **Background** (minimized), the upload must pause immediately. TDLib can resume partially uploaded files safely later.
- **Disconnect Behavior**: If charger is disconnected, wait exactly 5 minutes (configurable). If reconnected within that time, resume upload. If not, kill the foreground service and stop uploading completely.

### Drift / SQLite Constraints
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after ANY schema change
- **Never edit `.g.dart` files** manually
- Use `watch()` (stream), NOT `get()` (future) for reactive UI queries
- Batch insert in `transaction(() async { ... })` — prevents DB lock during bulk scan
- `InsertMode.insertOrIgnore` to prevent duplicates on rescan
- Enable FK enforcement: `db.execute('PRAGMA foreign_keys = ON')` in `NativeDatabase` setup
- Define `MigrationStrategy` from v1 — every column addition needs `Migrator.addColumn()`
- Add `@Index(['captured_at'])` on MediaItems table for timeline sort performance

### Android Permissions Constraints
- Android 12-: `READ_EXTERNAL_STORAGE` (maxSdkVersion="32")
- Android 13+: `READ_MEDIA_IMAGES` + `READ_MEDIA_VIDEO`
- `FOREGROUND_SERVICE_DATA_SYNC` — required Android 14+. Missing = crash on Android 14
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — declare in manifest + request at onboarding
- `RECEIVE_BOOT_COMPLETED` — WorkManager reboot rescheduling
- Scoped storage (Android 10+) — use `AssetEntity.file` from photo_manager, NOT raw paths

### photo_manager Constraints
- `AssetEntity.file` is **slow** (copies file). Use `thumbnailDataWithSize()` for thumbs
- `PhotoManager.getAssetListPaged(page, size: 100)` — paginate, NEVER load all at once
- `AssetEntity.id` = stable device key. Store as `localId` to detect already-uploaded items
- Use `modifiedDateTime` not `createDateTime` (may be null on Android)
- `PhotoManager.addChangeCallback()` — register after initial scan for incremental backup
- `PermissionState.limited` (Android 13 partial access) — handle gracefully, show banner

### UI / Performance Constraints
- Timeline MUST use `CustomScrollView` + `SliverPersistentHeader` (dates) + `SliverGrid` (photos)
- `RepaintBoundary` around EVERY thumbnail tile — isolates repaints during scroll
- `const` constructors on all leaf widgets — prevents unnecessary rebuilds
- `AutomaticKeepAliveClientMixin` on Timeline/Albums/Search screens — preserves state on tab switch
- `Hero(tag: 'media_${item.localId}')` on thumbnail AND viewer — tags must match exactly
- `ChewieController` must be disposed in `dispose()` — memory leak if skipped
- OLED dark mode: `Color(0xFF000000)` background, NOT dark grey

### Telegram Channel / Metadata Constraints
- Create channel ONCE, store `channelId` in `FlutterSecureStorage`. Verify on startup via `getChat()`
- Forum supergroup: `createNewSupergroupChat` with `'is_forum': true`
- Default "General" topic (id=1) = "All Photos" bucket
- Caption JSON (max 1024 chars):
  ```json
  {"app":"telecloud","v":1,"filename":"IMG_001.jpg","captured":"2024-08-14T10:30:00Z",
   "size":4194304,"width":4032,"height":3024,"lat":12.97,"lng":77.59,"album":"Vacation"}
  ```
- Save `telegramFileId` from upload response — permanent ID for direct downloads
- 500ms delay between rapid topic creates to avoid rate limiting

---

## 📋 Task Breakdown

> Format: **Input → Output → Verify → ⚠️ Gotchas**

---

### PHASE 0 — Project Setup

#### T0.1 — Flutter Project Init
- **Input:** Nothing
- **Output:** `flutter create telecloud_photos --org com.telecloud --platforms android`
- **Verify:** `flutter run` shows default app
- **⚠️ Gotchas:** `minSdkVersion 24`, `multiDexEnabled true`, delete default widget test, enable ABI splits for TDLib `.so` files

#### T0.2 — pubspec.yaml Dependencies
- **Input:** T0.1
- **Output:** All deps added, `flutter pub get` succeeds
- **Verify:** `flutter pub deps` — no conflicts
- **⚠️ Gotchas:** `drift`+`drift_flutter`+`sqlite3_flutter_libs` all 3 needed; `build_runner`+`drift_dev` = devDeps; `riverpod_annotation` needed for codegen; check `tdlib` pub.dev version supports Android FFI

#### T0.3 — AndroidManifest.xml
- **Input:** T0.2
- **Output:** All permissions + foreground service declaration
- **Verify:** App installs without manifest errors
- **⚠️ Gotchas:** Dual storage perms (Android 12/13+); `FOREGROUND_SERVICE_DATA_SYNC` for Android 14+; foreground service `android:foregroundServiceType="dataSync"`; WorkManager initializer block

#### T0.4 — Architecture Bootstrap (Riverpod + GoRouter + Drift)
- **Input:** T0.3
- **Output:** `main.dart` with ProviderScope, GoRouter, LazyDatabase, WorkManager.initialize()
- **Verify:** App navigates to placeholder; DB file created
- **⚠️ Gotchas:** `Workmanager().initialize(callbackDispatcher)` BEFORE `runApp()`; `callbackDispatcher` must be top-level; `LazyDatabase` to avoid blocking main(); `ProviderScope` wraps everything including `MaterialApp`

---

### PHASE 1 — TDLib Integration & Auth

#### T1.1 — TDLib Client Initialization
- **Input:** T0.4 + `API_ID`/`API_HASH` from my.telegram.org
- **Output:** `lib/core/telegram/tdlib_client.dart` — TDLib event stream flowing
- **Verify:** Logcat shows `authorizationStateWaitPhoneNumber`
- **⚠️ Gotchas:**
  - `setTdlibParameters` must be FIRST message sent
  - `database_directory` = `getApplicationDocumentsDirectory()` NOT temp dir
  - Poll `client.receive(timeout: 1.0)` in a loop inside an `Isolate`
  - Bridge to Riverpod via `StreamController<Map<String, dynamic>>`
  - Set log verbosity: level 1 debug, 0 release
  - `.so` ABI must match device — verify `tdlib` package includes all variants

#### T1.2 — Auth State Machine (Phone + OTP)
- **Input:** T1.1
- **Output:** `auth_service.dart` + `auth_provider.dart`
- **Verify:** Full login flow: phone → OTP → `authorizationStateReady`
- **⚠️ Gotchas:**
  - `setAuthenticationPhoneNumber` requires E.164 (`+919876543210`)
  - Wait for `authorizationStateWaitCode` BEFORE navigating to OTP screen
  - Handle `authorizationStateWaitPassword` for 2FA accounts
  - Session persistence: if TDLib DB dir exists on startup, goes straight to `ready` — skip auth screens
  - `API_ID`/`API_HASH` in `.env` + `flutter_dotenv` — NEVER hardcode

#### T1.3 — Camera Roll Permission Request
- **Input:** T0.3
- **Output:** Permission request flow in `media_scanner.dart`
- **Verify:** Permission dialog appears; `PhotoManager.getAssetListPaged()` returns photos after grant
- **⚠️ Gotchas:**
  - `PhotoManager.requestPermissionExtend()` returns `PermissionState` enum
  - `PermissionState.limited` → show "grant full access" banner, don't crash
  - Use `RequestType.common` to get both images and videos
  - `AssetEntity.file` returns `Future<File?>` — always null-check

#### T1.4 — Private Channel + Forum Topics
- **Input:** T1.2 (authorizationStateReady)
- **Output:** `channel_manager.dart` — creates forum supergroup, stores channelId
- **Verify:** Private channel "TeleCloud Photos 📸" appears in Telegram with forum enabled
- **⚠️ Gotchas:**
  - `createNewSupergroupChat` with `'is_forum': true` (requires TDLib 1.8.19+)
  - Check `FlutterSecureStorage` for existing `channelId` before creating new one
  - Verify channel exists via `getChat(channelId)` on each startup
  - Default topic id=1 ("General") = All Photos bucket
  - 500ms delay between `createForumTopic` calls to avoid FLOOD_WAIT

---

### PHASE 2 — Local Database Layer

#### T2.1 — Drift Schema Definition
- **Input:** T0.4
- **Output:** All tables + DAOs + generated `.g.dart` files
- **Verify:** `build_runner build` completes; `AppDatabase` instantiates without crash
- **⚠️ Gotchas:**
  - Always use `--delete-conflicting-outputs` flag
  - MediaItems primary key = `localId` (AssetEntity.id)
  - `intEnum<UploadStatus>()` requires enum defined before table
  - Enable `PRAGMA foreign_keys = ON` in NativeDatabase setup callback
  - Define `MigrationStrategy` now even if v1 has no migrations

#### T2.2 — MediaDAO: Stream Queries
- **Input:** T2.1
- **Output:** `media_dao.dart` — watch/insert/update methods
- **Verify:** Unit test: insert 100 items, stream emits sorted by capturedAt
- **⚠️ Gotchas:**
  - Use `watch()` not `get()` — reactive stream drives UI
  - `batch()` + `InsertMode.insertOrIgnore` for bulk scan inserts
  - Date grouping done in Dart (provider layer), not SQL
  - Stream of pending items: `.where((t) => t.uploadStatus.equals(0)).watch()`

---

### PHASE 3 — Backup Engine

#### T3.1 — Media Scanner (Initial + Incremental)
- **Input:** T1.3 (permissions), T2.2 (DAO)
- **Output:** `media_scanner.dart` — populates DB with pending items
- **Verify:** `watchAllMedia()` emits device photos; no duplicates on rescan
- **⚠️ Gotchas:**
  - Paginate: `getAssetListPaged(page: p, size: 100)` in loop
  - Use `modifiedDateTime ?? DateTime.now()` — createDateTime can be null
  - Run in `compute()` isolate for 10K+ libraries to avoid ANR
  - Register `PhotoManager.addChangeCallback()` ONCE after scan for incremental backup
  - `AssetType.other` (live photos) → skip for v1

#### T3.2 — Thumbnail Generator
- **Input:** T3.1, T2.2
- **Output:** `thumbnail_generator.dart` — 256x256 JPEG thumbnails in cache dir
- **Verify:** Thumbnail file exists at stored path; displays in grid
- **⚠️ Gotchas:**
  - Use `AssetEntity.thumbnailDataWithSize(256, 256)` NOT `image` package decode
  - Save to `getApplicationCacheDirectory()` (not documents — cache is clearable by system)
  - Create dir with `Directory.create(recursive: true)` before writing
  - Batch in groups of 10 with 50ms delay to avoid ANR on large libraries
  - Store original `width` + `height` from AssetEntity — needed for Telegram `InputThumbnail`

#### T3.3 — Upload Service
- **Input:** T1.4 (channel), T3.2 (thumbnails)
- **Output:** `upload_service.dart` — uploads one item to Telegram with JSON caption
- **Verify:** Photo in Telegram channel; `telegramMsgId` + `telegramFileId` in DB
- **⚠️ Gotchas:**
  - Use `inputMessageDocument` (preserves quality) NOT `inputMessagePhoto` (compresses)
  - Caption JSON must be under 1024 chars
  - Wait for `updateMessageSendSucceeded` to get final IDs — pending message IDs are temporary
  - `FLOOD_WAIT_X`: pause X seconds, store pause state in SharedPreferences
  - `updateFile` event = upload progress (`local.upload_offset`)
  - Set `uploadStatus = uploading` before start, `done`/`failed` on completion

#### T3.4 — Upload Queue + Retry
- **Input:** T3.3, T2.2
- **Output:** `upload_queue.dart` — sequential processing with 3-attempt retry
- **Verify:** Kill mid-upload → restart → resumes correctly; failed items retry 3x
- **⚠️ Gotchas:**
  - Process SEQUENTIALLY — concurrent uploads = faster FLOOD_WAIT
  - Retry: 1s, 4s, 16s backoff. After 3 failures = `uploadStatus.failed`
  - On startup: reset any `uploading` items back to `pending` (TDLib state lost on kill)
  - Drive queue from Drift stream `watchPendingItems()` — reacts to new inserts automatically
  - `bool _isProcessing` flag or `Mutex` to prevent duplicate queue processors

#### T3.5 — Foreground Service + Broadcast Receiver State Machine
- **Input:** T0.4, T3.4
- **Output:** `backup_manager.dart` + Native Kotlin `BroadcastReceiver`
- **Verify:** Connect charger → 5 min notification → upload starts. Disconnect → 5 min paused notification → service dies if not reconnected.
- **⚠️ Gotchas:**
  - WorkManager is NOT used here. We use `flutter_foreground_task` triggered by a native Kotlin `BroadcastReceiver` for exact timing.
  - Dart isolate must be spawned by the foreground service.
  - App Lifecycle (WidgetsBindingObserver): If on battery and user minimizes the app, catch `AppLifecycleState.paused` and immediately stop the upload queue.
  - Timer values must be read from SharedPreferences by the native receiver or the dart foreground task before starting the countdown.

---

### PHASE 4 — UI Screens

#### T4.1 — Splash + Auth Gate
- **Input:** T1.2
- **Output:** `splash_screen.dart` + GoRouter redirect logic
- **Verify:** Fresh install → login; existing session → timeline
- **⚠️ Gotchas:**
  - Wait for real TDLib auth state event, NOT `Future.delayed` hack
  - GoRouter `redirect` reads Riverpod authProvider state
  - Show animated logo during TDLib init — never blank white screen

#### T4.2 — Phone + OTP Screens
- **Input:** T1.2, T4.1
- **Output:** `phone_input_screen.dart` + `otp_screen.dart`
- **Verify:** Full login flow; invalid OTP error; resend works
- **⚠️ Gotchas:**
  - `intl_phone_field` for country code + E.164 formatting
  - `pinput` package for OTP boxes with auto-submit on 5 digits
  - Disable submit while loading — prevent double-submit
  - Show countdown from `code_info.timeout` (TDLib provides it)

#### T4.3 — Timeline Screen (Main Grid)
- **Input:** T2.2 (stream), T3.2 (thumbnails)
- **Output:** `timeline_screen.dart` + `photo_grid.dart`
- **Verify:** 1000+ photos at 60fps; sticky date headers; no jank
- **⚠️ Gotchas:**
  - `CustomScrollView` + `SliverPersistentHeader` (dates) + `SliverGrid` — NOT flat GridView.builder
  - `RepaintBoundary` on every `MediaThumbnail`
  - `crossAxisCount: 3` phones / `5` tablets via `LayoutBuilder`
  - `Image.file(File(thumbPath), cacheWidth: 256, cacheHeight: 256)` — memory limit
  - `AutomaticKeepAliveClientMixin` on screen — preserves state across tab switches

#### T4.4 — Full-screen Media Viewer
- **Input:** T4.3
- **Output:** `media_viewer_screen.dart`
- **Verify:** Hero animation; pinch zoom; swipe between photos; video plays with seek
- **⚠️ Gotchas:**
  - `Hero(tag: 'media_${item.localId}')` — tag must match thumbnail exactly
  - `InteractiveViewer(minScale: 0.5, maxScale: 4.0, clipBehavior: Clip.none)`
  - `PageView.builder` for swipe navigation — pass full sorted list + index
  - Show local thumbnail first → swap to full-res when Telegram download completes
  - `ChewieController.dispose()` in widget dispose — memory leak otherwise
  - `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive)` on open; restore on pop

#### T4.5 — Settings Screen
- **Input:** T3.5
- **Output:** `settings_screen.dart`
- **Verify:** Folder picker saves; logout works; wait timers update correctly in UI
- **⚠️ Gotchas:**
  - Folder picker = `PhotoManager.getAssetPathList()` (NOT file_picker which needs SAF)
  - Timers: Add inputs for "Wait X mins on connect" and "Wait X mins on disconnect" (default 5).
  - Battery optimization: `FlutterForegroundTask.requestIgnoreBatteryOptimization()`
  - Logout: `logOut()` TDLib → delete TDLib DB dir → clear FlutterSecureStorage → navigate /login

#### T4.6 — Albums Screen
- **Input:** T2.2, T1.4
- **Output:** `albums_list_screen.dart` + `album_detail_screen.dart`
- **Verify:** Albums with cover photo; create album → Telegram topic created
- **⚠️ Gotchas:**
  - Album cover = MAX(capturedAt) per album
  - Create album: (1) Telegram topic → topicId, (2) insert albums row, (3) update photo albumIds
  - "Move to album" = update local DB + `editMessageCaption` on Telegram message
  - 500ms delay between topic creates

#### T4.7 — Search Screen
- **Input:** T2.2
- **Output:** `search_screen.dart`
- **Verify:** "2024-08" returns August 2024 photos; filename search works
- **⚠️ Gotchas:**
  - Debounce 300ms before firing Drift query
  - Drift `like('%$query%')` for filename; date range for month search
  - Parse "2024-08" → `DateTime(2024,8,1)` to `DateTime(2024,8,31)` range
  - Empty state with suggestion chips

---

### PHASE 5 — Polish

#### T5.1 — Loading + Error States
- **Verify:** Shimmer before load; retry on error; empty state CTA
- **⚠️ Gotchas:** `shimmer` package for skeleton grid; `AsyncValue.when()` on ALL async providers

#### T5.2 — Theme System
- **Verify:** System dark mode works; all screens correct in both modes
- **⚠️ Gotchas:** NO PURPLE; `ColorScheme.fromSeed(Color(0xFF0A84FF))`; OLED true black `Color(0xFF000000)`

#### T5.3 — Build Verification
- **Verify:** `flutter build apk --debug` succeeds; APK installs; login + timeline works
- **⚠️ Gotchas:**
  - `build_runner build --delete-conflicting-outputs` BEFORE build
  - `flutter analyze` — fix all errors
  - Check ABI `.so` in APK: `unzip -l app-debug.apk | grep .so`
  - Gradle version: Flutter 3.x needs Gradle 7.x/8.x

---

## PHASE X — Verification Checklist

```bash
# Build
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --debug

# Security
python .agent/skills/vulnerability-scanner/scripts/security_scan.py .

# Mobile audit
python .agent/skills/mobile-design/scripts/mobile_audit.py .
```

**Manual checks:**
- [ ] TDLib session persists (kill + reopen → timeline, not login)
- [ ] Upload queue resumes after kill
- [ ] Connect charger: exact 5-min wait notification before upload starts
- [ ] Disconnect charger: exact 5-min wait notification, then kills background app
- [ ] Reconnect charger within 5 min: upload resumes
- [ ] Minimize app on battery: upload pauses immediately
- [ ] WiFi-only constraint respected
- [ ] 60fps scroll on mid-range device
- [ ] No memory leak (open/close viewer 20x, check profiler)
- [ ] Permissions denied gracefully
- [ ] 5000+ photo library: scan completes without ANR
- [ ] No purple/violet colors in UI
- [ ] All touch targets ≥ 48dp
- [ ] `grep -r "api_id\|api_hash" lib/` returns no hardcoded values

---

## 🔴 Agent Checkpoint

```
Platform:   Android (Flutter)
Framework:  Flutter 3.x + Riverpod + TDLib + Drift + WorkManager
Files Read: mobile-developer.md, mobile-backend.md, mobile-performance.md, platform-android.md

3 Principles:
1. SliverGrid + RepaintBoundary + const constructors → 60fps
2. Drift streams (watch()) not futures → reactive UI
3. @pragma('vm:entry-point') + top-level callbackDispatcher → WorkManager works in release

Anti-Patterns Avoided:
1. ScrollView for photos → SliverGrid/CustomScrollView
2. Hardcoded API credentials → .env + flutter_dotenv
3. AsyncStorage for session → FlutterSecureStorage
```

---

## ⏱️ Implementation Order

```
T0.1→T0.2→T0.3→T0.4          Day 1: Foundation
T1.1→T1.2→T1.3→T1.4          Day 2: Telegram auth + channel
T2.1→T2.2                     Day 3: Database layer
T3.1→T3.2→T3.3→T3.4→T3.5    Day 4-5: Backup engine
T4.1→T4.2→T4.3→T4.4→T4.5→T4.6→T4.7   Day 6-8: UI
T5.1→T5.2→T5.3               Day 9: Polish + verify
```

---
*Plan created: 2026-08-14 · Agent: project-planner + mobile-developer*

# 🌌 TeleCloud Photos
> **Infinite, Free & Secure Cloud Photo Storage Powered by Telegram & TDLib**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-green)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Database](https://img.shields.io/badge/Database-Drift%20SQLite-orange)](#)

TeleCloud Photos is a next-generation, open-source cloud photo gallery and backup client. It bridges your local device media and Google Photos account directly into private Telegram Supergroups, granting **unlimited free cloud backup** at original quality with zero server costs.

---

## 🚀 Key Features

### 📸 1. Interactive High-Performance Timeline
- **Two-Finger Pinch-to-Zoom Grid Scaling**: Dynamically expand and shrink gallery density from 1 to 6 columns using fluid two-finger multi-touch gestures (no clunky menus).
- **Native 120Hz High Refresh Rate**: Optimized with persistent memory caching and asynchronous thumbnail streaming for stutter-free scrolling.
- **Adaptive Aspect Ratios**: Choose between **Square (1:1 Fill)**, **Letterbox Fit**, or **Dynamic Original Aspect Ratio (Masonry)**.

### ☁️ 2. Unlimited Telegram Cloud Storage
- **Dedicated Supergroup Forum Integration**: Automatically provisions a private Telegram supergroup with isolated topic channels for each device album and sync source.
- **Background Upload Engine**: Employs Android Foreground Service & WorkManager with automatic wake-lock release and auto-kill when queue is clean.
- **Signal Dot & Live Telemetry**: Clean app bar status with pulsing signal dot and real-time MB/s upload metrics.

### 🔄 3. Genuine Google Photos Auto-Auth Sync
- **100% Authentic Cloud Migration**: Connects directly to Google OAuth2 endpoints and queries official Google Photos REST APIs.
- **Bit-for-Bit Original Resolution**: Downloads original quality photos and videos directly from Google CDN and uploads to Telegram without compression or synthetic mocks.
- **Flexible Scope Presets**: Full Library, Past 30/90 Days, Past Year, or Custom Date Range imports.

### 📁 4. Strict Monitored Backup Folders & Uploads Screen
- **Dedicated Monitored Folders Section**: Live horizontal cards displaying active backup folders with live item counts, sync indicators, and a `+ Manage` shortcut.
- **Manual Folder Upload**: Explicit one-tap folder upload trigger with full progress feedback.
- **Instant Folder Scanner (<50ms)**: Parallelized folder count resolution and asynchronous thumbnail previews.

### 🎨 5. Hierarchical Compact Settings Dashboard
- **Grouped Category Architecture**: Streamlined master dashboard with 5 high-level category cards routing into dedicated focused sub-screens:
  - 🎨 **Appearance & Display**: OLED Pure Black (#000000), Dark, Light themes, Aspect ratio switcher, 120Hz toggle.
  - ☁️ **Cloud Migration & Imports**: Google Photos sync hub & Google Takeout archive extractor.
  - 🔄 **Backup Engine & Rules**: Auto-backup switch, backup folders, Wi-Fi only, mobile data caps, sync frequency.
  - ⚡ **Power & Battery Constraints**: Charging-only policy, thermal dwell delay slider, battery protection (<20%).
  - 💾 **Storage & Cache Maintenance**: Free up device space, thumbnail cache clearing, deep app kill.

### 🧹 6. Storage Freedom & Local Maintenance
- **Free Up Space**: One-tap cleanup of local device media that has already been verified and safely backed up to Telegram Cloud.
- **Cache Management**: Inspect and clear thumbnail caches with a single click.

---

## 🏗️ Architecture & Tech Stack

```
telecloud_photos/
├── lib/
│   ├── core/
│   │   ├── backup/          # Media scanner, upload queue, & background workers
│   │   ├── cache/           # Persistent thumbnail cache & disk eviction
│   │   ├── database/        # Drift SQLite database, DAOs, & tables
│   │   ├── google/          # Google Photos OAuth2 client & sync pipeline
│   │   ├── telegram/        # TDLib MTProto client, channel & topic manager
│   │   └── di/              # Riverpod dependency injection providers
│   ├── features/
│   │   ├── timeline/        # Pinch-zoom gallery timeline & sticky headers
│   │   ├── library/         # 2-Column collection cards & real cover previews
│   │   ├── uploads/         # Monitored backup folders & manual upload triggers
│   │   ├── viewer/          # Fullscreen pan-zoom viewer & EXIF inspector
│   │   ├── google_photos/   # Google Photos cloud sync hub
│   │   └── settings/        # 5-Category hierarchical sub-screen settings
│   └── shared/
│       └── theme/           # OLED pure black, dark, & light design system
└── test/                    # 40+ automated unit & integration tests
```

---

## ⚡ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (3.24.0 or newer)
- Java 17 JDK (`openjdk-17`)
- Android SDK Platform 34+

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Myselfnandha/telecloud-photos.git
   cd telecloud-photos/telecloud_photos
   ```

2. **Configure Environment (`.env`)**:
   Create a `.env` file in the `telecloud_photos` root:
   ```env
   TELEGRAM_API_ID=your_api_id
   TELEGRAM_API_HASH=your_api_hash
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run Tests**:
   ```bash
   flutter test
   ```

5. **Launch Application**:
   ```bash
   flutter run
   ```

6. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
   *Output APK: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📜 License
This project is open-source software licensed under the [MIT License](LICENSE).

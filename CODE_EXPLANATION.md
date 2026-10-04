# 📦 StockWatch — Code Explanation Guide

A comprehensive guide explaining every file, class, and concept in the **StockWatch** Flutter inventory management application.

---

## 📁 Project Structure

```
stock_watch/
├── lib/
│   ├── main.dart        → App entry point & theme configuration
│   ├── core.dart        → Data models, storage service & state management
│   └── screens.dart     → All UI screens and widgets
├── pubspec.yaml         → Dependencies & project configuration
├── macos/               → macOS platform-specific files
├── ios/                 → iOS platform-specific files
├── android/             → Android platform-specific files
├── web/                 → Web platform-specific files
└── README.md            → Project readme
```

---

## 🗂️ File-by-File Breakdown

---

### 1. `pubspec.yaml` — Project Configuration

This file defines the project metadata and all its dependencies.

| Dependency | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Core Flutter framework for building the UI |
| `cupertino_icons` | ^1.0.8 | iOS-style icons for the app |
| `shared_preferences` | ^2.5.5 | Lightweight local storage (key-value pairs) to persist data |
| `uuid` | ^4.6.0 | Generates unique IDs (UUID v4) for each stock movement |
| `provider` | ^6.1.5+1 | State management — notifies the UI when data changes |
| `intl` | ^0.20.3 | Date/time formatting (e.g., `Oct 4, 2026 • 10:30 PM`) |

**Key settings:**
- `sdk: ^3.12.2` → Requires Dart SDK 3.12.2 or higher
- `uses-material-design: true` → Enables Material Design icons

---

### 2. `main.dart` — App Entry Point & Theme

This is where the app starts. It has **two responsibilities**:

#### a) Bootstrap (`main()` function)
```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => StockProvider(),
      child: const StockWatchApp(),
    ),
  );
}
```
- `runApp()` — Launches the Flutter app
- `ChangeNotifierProvider` — Wraps the entire app with a `StockProvider` instance so **any widget** in the tree can access and react to stock data changes

#### b) Theme Configuration (`StockWatchApp` class)
Defines the complete **dark theme** with:

| Theme Element | Purpose |
|---|---|
| `ColorScheme.dark()` | Dark mode base with teal (`#00BFA5`) as the primary accent |
| `scaffoldBackgroundColor` | Deep dark background (`#141420`) |
| `cardTheme` | Rounded cards with elevation and shadow |
| `navigationBarTheme` | Custom bottom nav colors, selected/unselected states |
| `dialogTheme` | Rounded, dark-styled dialogs |
| `inputDecorationTheme` | Filled text fields with teal focus border |
| `snackBarTheme` | Floating, dark-styled snack bars |

> **Design choice:** Material 3 (`useMaterial3: true`) is enabled for modern component styling.

---

### 3. `core.dart` — Models, Storage & State Management

This is the **brain** of the app. It contains all data logic with no UI code.

#### a) `StockItem` — Data Model for an Inventory Item

```dart
class StockItem {
  final String id;              // Unique identifier
  final String name;            // Product name (e.g., "MacBook Pro 16\"")
  final String category;        // Category (e.g., "Laptops")
  int currentQuantity;          // Current stock count (mutable)
  final int reorderThreshold;   // Alert when stock drops below this
}
```

**Key computed property:**
```dart
bool get isLowStock => currentQuantity < reorderThreshold;
```
Returns `true` when stock is critically low — the UI uses this to show warnings.

**Serialization:**
- `toMap()` — Converts the object to a `Map<String, dynamic>` for JSON storage
- `fromMap()` — Factory constructor to recreate an object from stored JSON

#### b) `StockMovement` — Data Model for a Stock Transaction

```dart
class StockMovement {
  final String id;         // Unique movement ID (UUID v4)
  final String itemId;     // Links to the StockItem
  final String itemName;   // Denormalized name for display
  final String type;       // 'IN' (restock) or 'OUT' (dispatch)
  final int quantity;      // How many units moved
  final DateTime timestamp; // When this movement happened
}
```

Same `toMap()` / `fromMap()` serialization pattern. Timestamps are stored as ISO 8601 strings.

#### c) `StorageService` — Persistence Layer

Uses `SharedPreferences` (local key-value store) to save/load data.

| Method | What it does |
|---|---|
| `getItems()` | Loads all stock items from local storage. Returns seed data if storage is empty |
| `saveItems()` | Saves the current items list as JSON strings |
| `getMovements()` | Loads all movement records from local storage |
| `saveMovements()` | Saves all movement records as JSON strings |
| `_getInitialItems()` | Returns 4 seed items for first-time users |

**How it works internally:**
1. Each `StockItem` → converted to `Map` → encoded to JSON string
2. All JSON strings stored as a `List<String>` under a key in `SharedPreferences`
3. On load, each JSON string is decoded back to a `Map` → converted to a `StockItem`

#### d) `StockProvider` — State Management (ChangeNotifier)

This is the **central state manager** using the Provider pattern.

```dart
class StockProvider extends ChangeNotifier {
  List<StockItem> _items = [];
  List<StockMovement> _movements = [];
  bool _isLoading = true;
}
```

| Property | Type | Purpose |
|---|---|---|
| `_items` | `List<StockItem>` | All inventory items |
| `_movements` | `List<StockMovement>` | All stock movements (sorted newest first) |
| `_isLoading` | `bool` | Shows a loading spinner while data loads |

**Key method — `recordMovement()`:**
```dart
Future<void> recordMovement(StockItem item, String type, int quantity) async {
  // 1. Update the item's quantity
  if (type == 'IN') {
    item.currentQuantity += quantity;
  } else if (type == 'OUT') {
    item.currentQuantity = max(0, item.currentQuantity - quantity);
  }

  // 2. Create a new movement record
  final movement = StockMovement(id: _uuid.v4(), ...);

  // 3. Insert at the front (newest first)
  _movements.insert(0, movement);

  // 4. Notify all listening widgets to rebuild
  notifyListeners();

  // 5. Persist changes to local storage
  await _storage.saveItems(_items);
  await _storage.saveMovements(_movements);
}
```

> **Flow:** User action → Provider updates data → `notifyListeners()` → UI rebuilds → Data persisted to disk

---

### 4. `screens.dart` — All UI Screens & Widgets

This file contains all the visual components, organized as follows:

#### a) `_GradientAppBar` — Custom App Bar

A reusable app bar with a dark gradient background and optional app logo icon.
- Shows the StockWatch icon + title on the main screens
- Shows a styled back button on detail screens

#### b) `HomeScreen` — Main Navigation Shell

A `StatefulWidget` that manages the bottom navigation bar.

```
┌─────────────────────────┐
│       [AppBar]          │
│                         │
│    [Current Screen]     │ ← Switches between tabs
│                         │
│ ┌───────────┬──────────┐│
│ │ Stock List│ Activity ││ ← Bottom NavigationBar
│ └───────────┴──────────┘│
└─────────────────────────┘
```

Uses `AnimatedSwitcher` for smooth transitions between tabs.

#### c) `_SummaryCards` — Dashboard Overview

Three metric cards displayed at the top of the Stock List:

| Card | Metric | Color |
|---|---|---|
| Total Items | Count of all stock items | Teal gradient |
| Low Stock | Count of items below threshold | Red (if >0) / Green (if 0) |
| Total Qty | Sum of all quantities | Purple gradient |

Each card has a subtle gradient background with a matching border.

#### d) `StockListScreen` — Inventory List View

Displays all stock items using a scrollable `ListView.builder`.

**Each item card (`_StockItemCard`) shows:**
- Category icon (mapped by category name)
- Item name and category badge
- Low stock warning badge (if applicable)
- Progress bar showing stock health
- Quantity badge with color coding (green = healthy, red = low)
- Chevron indicating tap-for-details

**Page transition:** Uses `PageRouteBuilder` with a slide-in animation from the right.

#### e) `ItemDetailScreen` — Single Item Details

Shows detailed information about one stock item with:

1. **Info Card** — Large quantity display, health status badge, category/threshold chips, low stock alert
2. **Action Buttons** — "Stock In" (teal) and "Stock Out" (red) with gradient styling
3. **Movement History** — List of all movements for this specific item

#### f) `_showMovementDialog()` — Stock In/Out Dialog

A modal dialog for recording inventory changes:
- Large centered quantity input field
- Color-coded confirm button (teal for in, red for out)
- Validation: rejects empty/zero/negative inputs and prevents over-withdrawal

#### g) `MovementLogScreen` — Global Activity Feed

Shows **all** stock movements across all items in reverse chronological order.

Each entry shows:
- Direction icon with gradient background (↑ green for IN, ↓ red for OUT)
- Item name
- IN/OUT badge + formatted timestamp
- Signed quantity badge (+5 or -3)

---

## 🔄 Data Flow Architecture

```
┌────────────────────────────────────────────────┐
│                   USER ACTION                   │
│         (Tap "Stock In" → Enter 5 → Confirm)   │
└──────────────────────┬─────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│              StockProvider                        │
│                                                   │
│  1. Update item.currentQuantity += 5              │
│  2. Create StockMovement(type: 'IN', qty: 5)     │
│  3. Insert movement at index 0                    │
│  4. notifyListeners()  ──────────────────┐       │
│  5. Save to SharedPreferences            │       │
└──────────────────────────────────────────┼───────┘
                                           │
                       ┌───────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│              UI REBUILD                           │
│                                                   │
│  • StockListScreen updates quantity & colors      │
│  • Summary cards recalculate totals               │
│  • MovementLogScreen shows new entry              │
│  • ItemDetailScreen shows updated history         │
└──────────────────────────────────────────────────┘
```

---

## 🎨 Design System

### Color Palette

| Color | Hex | Usage |
|---|---|---|
| Background | `#141420` | Main scaffold background |
| Surface | `#1E1E2C` | Cards, containers |
| Dark Surface | `#1A1A28` | Navigation bar |
| Primary Teal | `#00BFA5` | Healthy stock, buttons, accents |
| Secondary Cyan | `#64FFDA` | Selected states, gradients |
| Error Red | `#FF5252` | Low stock warnings, stock out |
| Light Red | `#FF8A80` | Red gradient endpoints |
| Purple | `#7C4DFF` | Total quantity card accent |
| Light Purple | `#B388FF` | Purple gradient endpoint |

### UI Patterns Used

- **Glassmorphism** — Subtle transparency and layered surfaces
- **Gradient accents** — Used on icons, buttons, and cards for depth
- **Color-coded status** — Green = healthy, Red = low stock, universally applied
- **Micro-animations** — Page transitions, animated tab switching
- **Progress indicators** — Visual stock level bars on each item card
- **Chip badges** — Category and status labels for quick scanning

---

## 🚀 How to Run

```bash
# Get dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Run on Chrome (web)
flutter run -d chrome

# Run on iOS Simulator
flutter run -d ios

# Hot reload (while running)
# Press 'r' in terminal

# Hot restart (while running)
# Press 'R' in terminal
```

---

## 📚 Key Flutter Concepts Used

| Concept | Where Used | Why |
|---|---|---|
| **Provider** | `main.dart`, all screens | Centralized state management without boilerplate |
| **ChangeNotifier** | `StockProvider` | Notifies listening widgets when data changes |
| **Consumer Widget** | `screens.dart` | Rebuilds only the parts of UI that depend on data |
| **SharedPreferences** | `StorageService` | Simple persistent storage for small data |
| **StatefulWidget** | `HomeScreen` | Manages local state (selected tab index) |
| **StatelessWidget** | Most screens | No local state needed — data comes from Provider |
| **Navigator** | Item tap → Detail screen | Standard page-based navigation |
| **PageRouteBuilder** | Stock list → Detail | Custom slide transition animation |
| **AnimatedSwitcher** | Tab switching | Smooth crossfade between screens |
| **Material 3** | Theme configuration | Latest Material Design system |

---

> 💡 **Tip:** The app uses a clean separation of concerns — `core.dart` handles all data logic, `screens.dart` handles all presentation, and `main.dart` ties them together with theming and Provider setup.

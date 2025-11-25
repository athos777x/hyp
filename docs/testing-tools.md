## Testing Controls Cheat Sheet

Keep these flags handy for quickly enabling local-only helpers while keeping production builds clean.

### `lib/healthpage.dart`

```dart
static const bool _showTestingActions = false; // TODO: Change to false before deploying
```

- Set to `true` to show the hidden AppBar actions:
  - **Generate sample data** (seeds 12 months of BP readings).
  - **Clear all measurements** (wipes the last 12 months for quick resets).
- Leave `false` when shipping so users never see these buttons.

### `lib/medicationspage.dart`

```dart
static const bool _showNotificationTestFab = false; // TODO: Change to false before deploying
```

- Switch to `true` to bring back the orange bell FAB that triggers `_testMedicationNotification()`.
- Turn it off (`false`) before release builds to hide the bell but keep the feature ready for future QA sessions.

> Tip: search for `TODO: Change to false before deploying` to locate every testing toggle in one go.


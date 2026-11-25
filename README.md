# Pulse: Flutter Web admin dashboard

Personal demo project. A responsive admin dashboard built with **Flutter Web** and **Dart**: KPI cards, a line chart (fl_chart), and a searchable, sortable orders table. Layout switches between one column (mobile/tablet) and two columns (desktop) with `LayoutBuilder`.

**Tech:** Flutter, Dart, Flutter Web, REST API integration (http), bearer-token auth, responsive layout, fl_chart, Provider (state management), intl, Material 3 dark theme.

## Backend integration
Pulse talks to the **Relay** Dart backend (separate repo): login, orders, stats and the AI summary card. If Relay is not reachable it shows local demo data and says so on screen.

## Run
```bash
# 1) start Relay (see the relay repo), then:
flutter run -d chrome --dart-define=RELAY_URL=http://localhost:8080 --dart-define=RELAY_USER=admin --dart-define=RELAY_PASS=admin123
flutter pub get
flutter build web
flutter test
```

## Notes
- Offline fallback data lives in `lib/data.dart`; the API client is `lib/api.dart`.
- Honest status: the code was written without running it on a device. Run `flutter analyze` and `flutter test` first. Screenshots in `docs/` are UI mockups, not recordings.

## Screens (design mockups, not recordings)
![pulse-1-overview](docs/pulse-1-overview.png)
![pulse-2-orders](docs/pulse-2-orders.png)
![pulse-3-insights](docs/pulse-3-insights.png)
